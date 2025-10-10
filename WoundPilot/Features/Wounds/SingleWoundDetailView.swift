import SwiftUI
import ARKit

struct SingleWoundDetailView: View {
    let wound: Wound
    
    @ObservedObject var langManager = LocalizationManager.shared
    @State private var navigateToQuestionnaire = false
    @State private var measurementResult: WoundMeasurementResult?

    // AR sheet
    @State private var showAR = false
    @State private var showARUnsupportedAlert = false
    
    // Latest measurement display
    @State private var latestMeasurement: WoundMeasurement?
    @State private var isLoadingMeasurement = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                woundImageSection
                metadataSection
                measurementSection
                measureARButton
                analyzeButton
                Spacer(minLength: 0)
            }
            .padding(.top)
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .navigationTitle(LocalizedStrings.woundEntryTitle)
        .navigationBarTitleDisplayMode(.inline)
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
        .onAppear(perform: loadLatestMeasurement)
    }
    
    // MARK: - Data Loading
    
    private func loadLatestMeasurement() {
        isLoadingMeasurement = true
        WoundService.shared.fetchLatestMeasurement(woundId: wound.id) { result in
            isLoadingMeasurement = false
            if case .success(let measurement) = result {
                latestMeasurement = measurement
            }
        }
    }
    
    // MARK: - Measurement Handler
    
    private func handleMeasurementResult(_ result: WoundMeasurementResult) {
        let lengthCm = Double(result.lengthCm)
        let widthCm = Double(result.widthCm)
        
        let calculatedArea = lengthCm * widthCm * 0.785
        let areaCm2: Double
        if let resultArea = result.areaCm2 {
            areaCm2 = Double(resultArea)
        } else {
            areaCm2 = calculatedArea
        }

        
        measurementResult = result

        
        WoundService.shared.addMeasurement(
            woundId: wound.id,
            lengthCm: lengthCm,
            widthCm: widthCm,
            areaCm2: areaCm2,
            width1Cm: widthCm,
            width2Cm: widthCm
        ) { firestoreResult in
            if case .success(let measurement) = firestoreResult {
                latestMeasurement = measurement
            } else if case .failure(let error) = firestoreResult {
                print("Failed to add measurement: \(error)")
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
            Text(LocalizedStrings.analyzeWound)
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
        QuestionnaireContext(
            // You do have the patientId on the wound
            patientId: wound.patientId,

            // You probably don’t have comorbidities here—pass nils (unknown)
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

            // Location context you do have on the wound
            bodyLocation: wound.location,      // String? on your model
            bodyRegionCode: nil,               // Your Wound doesn’t have this -> pass nil for now
            isLowerLimb: isLowerLimb(from: wound.location),

            // Measurements (convert Float -> Double if your context uses Double?)
            lengthCm: measurementResult.map { Double($0.lengthCm) },
            widthCm:  measurementResult.map { Double($0.widthCm)  },
            areaCm2:  measurementResult?.areaCm2.map(Double.init)
        )
    }

    private func isLowerLimb(from location: String?) -> Bool {
        guard let s = location?.lowercased() else { return false }
        let hits = ["foot","heel","toe","ankle","lower leg","calf","shin","knee","thigh"]
        return hits.contains { s.contains($0) }
    }
}
