import SwiftUI
import ARKit
import FirebaseFirestore

struct SingleWoundDetailView: View {
    let wound: Wound
    
    @ObservedObject var langManager = LocalizationManager.shared
    
    // Navigation
    @State private var navigateToQuestionnaire = false
    @State private var measurementResult: WoundMeasurementResult?
    
    // AR sheet
    @State private var showAR = false
    @State private var showARUnsupportedAlert = false
    
    // Latest measurement display
    @State private var latestMeasurement: WoundMeasurement?
    @State private var isLoadingMeasurement = true
    
    // Past analysis (read-only summary)
    @State private var pastAnalysis: PastAnalysisData?
    @State private var isLoadingAnalysis = true
    
    // Patient
    @State private var patient: Patient?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                woundImageSection
                metadataSection
                measurementSection
                
                // PAST ANALYSIS SECTION
                if isLoadingAnalysis {
                    ProgressView("Loading past analysis...")
                        .padding()
                } else if let analysis = pastAnalysis {
                    pastAnalysisSection(analysis)
                }
                
                measureARButton
                analyzeButton
                Spacer(minLength: 0)
            }
            .padding(.top)
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .navigationTitle(LocalizedStrings.woundEntryTitle)
        .navigationBarTitleDisplayMode(.inline)

        // Only Questionnaire navigation remains
        .navigationDestination(isPresented: $navigateToQuestionnaire) {
            QuestionnaireView(
                woundGroupId: wound.woundGroupId,
                context: makeContextFromWound(),
                isQuickScan: false,
                measurementResult: measurementResult
            )
        }

        .sheet(isPresented: $showAR) {
            WoundMeasurementView(onComplete: handleMeasurementResult)
        }
        .alert(LocalizedStrings.arNotSupportedTitle, isPresented: $showARUnsupportedAlert) {
            Button(LocalizedStrings.ok, role: .cancel) { }
        } message: {
            Text(LocalizedStrings.arNotSupportedMessage)
        }
        .onAppear {
            loadLatestMeasurement()
            loadPastAnalysis()
            loadPatient()
        }
    }
    
    // MARK: - Data Loading
    
    @MainActor
    private func loadLatestMeasurement() {
        isLoadingMeasurement = true

        WoundService.shared.fetchLatestMeasurement(woundId: wound.id) { result in
            self.isLoadingMeasurement = false

            switch result {
            case .success(let mOpt):
                guard let m = mOpt else {
                    self.latestMeasurement = nil
                    self.measurementResult = nil
                    return
                }

                self.latestMeasurement = m

                // Minimal confidence placeholder (or set to nil if you prefer)
                let basicConfidence = WoundMeasurementResult.MeasurementConfidence(
                    score: 0.95,
                    label: "Good",
                    trackingQuality: "N/A",
                    distanceFromCamera: nil,
                    surfacePlanarity: nil
                )

                self.measurementResult = WoundMeasurementResult(
                    lengthCm:  Float(m.length_cm),
                    widthCm:   Float(m.width_cm),
                    areaCm2:   Float(m.area_cm2),
                    capturedImage: nil,
                    method: .manual,            // TODO: persist real method with the measurement and use it here
                    confidence: basicConfidence, // or nil
                    timestamp: m.measured_at
                )

            case .failure:
                self.latestMeasurement = nil
                self.measurementResult = nil
            }
        }
    }
    
    private func loadPastAnalysis() {
        isLoadingAnalysis = true
        
        Firestore.firestore()
            .collection("woundGroups")
            .document(wound.woundGroupId)
            .getDocument { snapshot, _ in
                DispatchQueue.main.async {
                    isLoadingAnalysis = false
                    
                    guard let data = snapshot?.data(),
                          let questionnaireData = data["questionnaire"] as? [String: Any] else {
                        pastAnalysis = nil
                        return
                    }
                    
                    // Extract completion timestamp (optional)
                    let completedAt: Date?
                    if let timestamp = questionnaireData["completedAt"] as? Timestamp {
                        completedAt = timestamp.dateValue()
                    } else {
                        completedAt = nil
                    }
                    
                    pastAnalysis = PastAnalysisData(
                        questionnaireData: questionnaireData,
                        completedAt: completedAt
                    )
                }
            }
    }
    
    private func loadPatient() {
        Firestore.firestore()
            .collection("patients")
            .document(wound.patientId)
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                
                DispatchQueue.main.async {
                    patient = Patient(
                        id: wound.patientId,
                        name: data["name"] as? String ?? "",
                        dateOfBirth: (data["dateOfBirth"] as? Timestamp)?.dateValue() ?? Date(),
                        sex: data["sex"] as? String,
                        hasDiabetes: data["hasDiabetes"] as? Bool,
                        hasPAD: data["hasPAD"] as? Bool,
                        hasVenousDisease: data["hasVenousDisease"] as? Bool,
                        isImmunosuppressed: data["isImmunosuppressed"] as? Bool,
                        hasMobilityImpairment: data["hasMobilityImpairment"] as? Bool,
                        canOffload: data["canOffload"] as? Bool,
                        isOnAnticoagulants: data["isOnAnticoagulants"] as? Bool,
                        allergyToAdhesives: data["allergyToAdhesives"] as? Bool,
                        allergyToIodine: data["allergyToIodine"] as? Bool,
                        allergyToSilver: data["allergyToSilver"] as? Bool,
                        allergyToLatex: data["allergyToLatex"] as? Bool,
                        otherAllergies: data["otherAllergies"] as? String
                    )
                }
            }
    }
    
    // MARK: - Measurement Handler
    
    private func handleMeasurementResult(_ result: WoundMeasurementResult) {
        let lengthCm = Double(result.lengthCm)
        let widthCm  = Double(result.widthCm)
        
        let calculatedArea = lengthCm * widthCm * 0.785
        let areaCm2: Double = result.areaCm2.map(Double.init) ?? calculatedArea

        measurementResult = result

        WoundService.shared.addMeasurement(
            woundId: wound.id,
            lengthCm: lengthCm,
            widthCm: widthCm,
            areaCm2: areaCm2,
            width1Cm: widthCm,
            width2Cm: widthCm
        ) { firestoreResult in
            DispatchQueue.main.async {
                if case .success(let measurement) = firestoreResult {
                    latestMeasurement = measurement
                } else if case .failure(let error) = firestoreResult {
                    print("Failed to add measurement: \(error)")
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder private var woundImageSection: some View {
        if let imageURL = URL(string: wound.imageURL) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    placeholderCard
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                case .failure:
                    placeholderCard
                @unknown default:
                    placeholderCard
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 260)
            .padding(.horizontal)
        }
    }

    private var placeholderCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
            ProgressView()
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let location = displayLocation {
                Label(location, systemImage: "mappin.circle.fill")
            }
            Label(formattedTimestamp, systemImage: "calendar")
            if let name = wound.woundGroupName {
                Label(name, systemImage: "folder.fill")
            }
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    @ViewBuilder private var measurementSection: some View {
        if isLoadingMeasurement {
            ProgressView()
                .padding()
        } else if let m = latestMeasurement {
            VStack(spacing: 8) {
                Text(LocalizedStrings.latestMeasurementTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    measurementChip(
                        icon: "ruler",
                        label: LocalizedStrings.lengthShort,
                        value: String(format: "%.1f cm", m.length_cm)
                    )
                    measurementChip(
                        icon: "ruler",
                        label: LocalizedStrings.widthShort,
                        value: String(format: "%.1f cm", m.width_cm)
                    )
                    measurementChip(
                        icon: "square.dashed",
                        label: LocalizedStrings.areaShort,
                        value: String(format: "%.1f cm²", m.area_cm2)
                    )
                }
            }
            .padding(.horizontal)
        } else {
            Text(LocalizedStrings.noMeasurementsYetHint)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    private func measurementChip(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption2.weight(.semibold))
            Text(value)
                .font(.caption.weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color.accentBlue.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - PAST ANALYSIS SECTION (read-only)
    
    private func pastAnalysisSection(_ analysis: PastAnalysisData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Past Analysis")
                    .font(.headline)
                Spacer()
                if let date = analysis.completedAt {
                    Text(formatAnalysisDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick summary from questionnaire data
            if let summary = buildQuickSummary(from: analysis.questionnaireData) {
                VStack(alignment: .leading, spacing: 8) {
                    summaryRow(icon: "bandage.fill", label: "Wound Bed",
                               value: summary.woundBed, color: summary.woundBedColor)
                    summaryRow(icon: "drop.fill", label: "Exudate",
                               value: summary.exudate, color: .blue)
                    summaryRow(icon: "exclamationmark.triangle.fill", label: "Infection",
                               value: summary.infection, color: summary.infectionColor)
                    
                    if let perfusion = summary.perfusion {
                        summaryRow(icon: "heart.fill", label: "Perfusion",
                                   value: perfusion, color: .purple)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    private func summaryRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
    }
    
    private func buildQuickSummary(from data: [String: Any]) -> QuickAnalysisSummary? {
        // Parse wound bed types
        let woundBedTypes = Set(data["woundBedTypes"] as? [String] ?? [])
        let woundBed: String
        let woundBedColor: Color
        
        if woundBedTypes.contains("necrosis") {
            woundBed = "Necrotic tissue present"
            woundBedColor = .red
        } else if woundBedTypes.contains("slough") {
            woundBed = "Sloughy tissue"
            woundBedColor = .orange
        } else if woundBedTypes.contains("granulation") {
            woundBed = "Granulating"
            woundBedColor = .green
        } else if woundBedTypes.contains("epithelializing") {
            woundBed = "Epithelializing"
            woundBedColor = .blue
        } else {
            woundBed = "Not assessed"
            woundBedColor = .gray
        }
        
        // Parse exudate
        let exudate = (data["exudate"] as? String ?? "unknown").capitalized
        
        // Parse infection
        let infectionSigns = data["infectionSigns"] as? [String: Any] ?? [:]
        let hasWarmth    = infectionSigns["warmth"] as? Bool ?? false
        let hasPurulent  = infectionSigns["purulentDischarge"] as? Bool ?? false
        let hasOdor      = infectionSigns["odor"] as? Bool ?? false
        let hasSpreading = infectionSigns["spreadingRedness"] as? Bool ?? false
        let hasErythema  = infectionSigns["erythemaGt2cm"] as? Bool ?? false
        let hasFever     = infectionSigns["fever"] as? Bool ?? false
        let hasCrepitus  = infectionSigns["crepitus"] as? Bool ?? false
        
        let infection: String
        let infectionColor: Color
        
        if hasFever || hasCrepitus || hasSpreading {
            infection = "Systemic infection"
            infectionColor = .red
        } else if hasWarmth || hasPurulent || hasOdor || hasErythema {
            infection = "Local infection"
            infectionColor = .orange
        } else {
            infection = "No signs"
            infectionColor = .green
        }
        
        // Parse perfusion (if present)
        let abi = data["abi"] as? String
        let perfusion: String?
        
        if let abi = abi {
            switch abi {
            case "ge0_8":
                perfusion = "Adequate (ABI ≥0.8)"
            case "p0_5to0_79":
                perfusion = "Reduced (ABI 0.5-0.79)"
            case "lt0_5":
                perfusion = "Critical (ABI <0.5)"
            default:
                perfusion = "Unknown"
            }
        } else {
            perfusion = nil
        }
        
        return QuickAnalysisSummary(
            woundBed: woundBed,
            woundBedColor: woundBedColor,
            exudate: exudate,
            infection: infection,
            infectionColor: infectionColor,
            perfusion: perfusion
        )
    }
    
    private func formatAnalysisDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var measureARButton: some View {
        Button(action: handleARButtonTap) {
            Label(latestMeasurement == nil ? LocalizedStrings.measureButton : LocalizedStrings.remeasureButton, systemImage: "ruler")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentBlue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private func handleARButtonTap() {
        if ARWorldTrackingConfiguration.isSupported {
            showAR = true
        } else {
            showARUnsupportedAlert = true
        }
    }

    private var analyzeButton: some View {
        Button {
            navigateToQuestionnaire = true
        } label: {
            Text(pastAnalysis == nil ? LocalizedStrings.analyzeWound : "Re-analyze Wound")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var formattedTimestamp: String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return df.string(from: wound.timestamp)
    }

    private var displayLocation: String? {
        guard let loc = wound.location, !loc.isEmpty else { return nil }
        return loc.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private func makeContextFromWound() -> QuestionnaireContext {
        if let patient = patient {
            return QuestionnaireContext(
                patientId: wound.patientId,
                hasDiabetes: patient.hasDiabetes,
                hasPAD: patient.hasPAD,
                hasVenousDisease: patient.hasVenousDisease,
                isImmunosuppressed: patient.isImmunosuppressed,
                hasMobilityImpairment: patient.hasMobilityImpairment,
                canOffload: patient.canOffload,
                isOnAnticoagulants: patient.isOnAnticoagulants,
                allergyToAdhesives: patient.allergyToAdhesives,
                allergyToIodine: patient.allergyToIodine,
                allergyToSilver: patient.allergyToSilver,
                allergyToLatex: patient.allergyToLatex,
                otherAllergies: patient.otherAllergies,
                bodyLocation: wound.location,
                bodyRegionCode: nil,
                isLowerLimb: isLowerLimb(from: wound.location),
                lengthCm: measurementResult.map { Double($0.lengthCm) },
                widthCm: measurementResult.map { Double($0.widthCm) },
                areaCm2: measurementResult?.areaCm2.map(Double.init)
            )
        } else {
            return QuestionnaireContext(
                patientId: wound.patientId,
                hasDiabetes: nil,
                hasPAD: nil,
                hasVenousDisease: nil,
                isImmunosuppressed: nil,
                hasMobilityImpairment: nil,
                canOffload: nil,
                isOnAnticoagulants: nil,
                allergyToAdhesives: nil,
                allergyToIodine: nil,
                allergyToSilver: nil,
                allergyToLatex: nil,
                otherAllergies: nil,
                bodyLocation: wound.location,
                bodyRegionCode: nil,
                isLowerLimb: isLowerLimb(from: wound.location),
                lengthCm: measurementResult.map { Double($0.lengthCm) },
                widthCm: measurementResult.map { Double($0.widthCm) },
                areaCm2: measurementResult?.areaCm2.map(Double.init)
            )
        }
    }

    private func isLowerLimb(from location: String?) -> Bool {
        guard let s = location?.lowercased() else { return false }
        let hits = ["foot","heel","toe","ankle","lower leg","calf","shin","knee","thigh"]
        return hits.contains { s.contains($0) }
    }
}

// MARK: - Supporting Models

struct PastAnalysisData {
    let questionnaireData: [String: Any]
    let completedAt: Date?
}

struct QuickAnalysisSummary {
    let woundBed: String
    let woundBedColor: Color
    let exudate: String
    let infection: String
    let infectionColor: Color
    let perfusion: String?
}
