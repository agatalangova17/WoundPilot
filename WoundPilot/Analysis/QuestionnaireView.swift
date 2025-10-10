import SwiftUI
import UIKit
import FirebaseFirestore

struct QuestionnaireView: View {
    let woundGroupId: String
    let context: QuestionnaireContext
    var isQuickScan: Bool = false
    var measurementResult: WoundMeasurementResult? = nil

    @ObservedObject var langManager = LocalizationManager.shared

    enum Step: Int, CaseIterable, Hashable {
        case woundBed
        case exudate
        case deepSpaces
        case periwoundSkin
        case infection
        case boneInvolvement  // Conditional
        case perfusion        // Conditional
        
        var title: String {
            switch self {
            case .woundBed: return "Wound Bed"
            case .exudate: return "Exudate Level"
            case .deepSpaces: return "Deep Spaces"
            case .periwoundSkin: return "Peri-wound Skin"
            case .infection: return "Infection Signs"
            case .boneInvolvement: return "Bone Involvement"
            case .perfusion: return "Perfusion"
            }
        }
    }

    // Stored values
    @State private var woundBedTypes: Set<String> = []  // Multi-select
    @State private var exudate: String = ""
    @State private var hasDeepSpaces: Bool = false
    @State private var deepSpaceType: Set<String> = []
    @State private var periwoundSkin: String = ""
    
    // Infection (toggles)
    @State private var hasWarmth = false
    @State private var hasPurulentDischarge = false
    @State private var hasOdor = false
    @State private var hasSpreadingRedness = false
    @State private var hasErythemaGt2cm = false
    @State private var hasFever = false
    @State private var hasCrepitus = false
    
    // Bone (conditional)
    @State private var hasExposedBone = false
    @State private var probeToBonePositive = false
    
    // Perfusion (conditional)
    @State private var pedalPulsesPalpable: Bool? = nil
    @State private var coldPaleFoot = false
    @State private var restPainRelievedByHanging = false
    @State private var abi: String = ""

    // UX
    @State private var isSaving = false
    @State private var showNextView = false
    @State private var step: Step = .woundBed
    @State private var navigationHistory: [Step] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                StepIndicator(
                    currentIndex: navigationHistory.count + 1,
                    total: estimatedTotalSteps,
                    title: step.title
                )
                .padding(.top, 8)
                
                // Show context info
                HStack(spacing: 12) {
                    if let measurements = measurementResult {
                        HStack(spacing: 6) {
                            Image(systemName: "ruler")
                                .foregroundColor(.blue)
                            Text("\(String(format: "%.1f", measurements.lengthCm)) × \(String(format: "%.1f", measurements.widthCm)) cm")
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                    
                    if let location = context.bodyLocation {
                        HStack(spacing: 6) {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(.green)
                            Text(location.replacingOccurrences(of: "|", with: " · "))
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1), in: Capsule())
                    }
                }

                if let urgent = urgentBannerText {
                    Banner(text: urgent, style: .danger)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 8)

            // Steps
            TabView(selection: $step) {
                woundBedStep.tag(Step.woundBed)
                exudateStep.tag(Step.exudate)
                deepSpacesStep.tag(Step.deepSpaces)
                periwoundSkinStep.tag(Step.periwoundSkin)
                infectionStep.tag(Step.infection)
                
                if shouldShowBoneQuestions {
                    boneInvolvementStep.tag(Step.boneInvolvement)
                }
                
                if shouldShowPerfusion {
                    perfusionStep.tag(Step.perfusion)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNextView) {
            ReportView(
                woundGroupId: woundGroupId,
                patientId: context.patientId,
                context: context,
                questionnaireData: buildQuestionnairePayload(),
                measurementResult: measurementResult,
                isQuickScan: isQuickScan
            )
        }
    }
    
    // MARK: - Steps

    private var woundBedStep: some View {
        questionCard(title: "Wound Bed") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select all tissue types present (choose dominant if mixed):")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    WoundBedOption(
                        title: "Red/Pink Granulation",
                        subtitle: "Healthy healing tissue",
                        color: Color(red: 0.9, green: 0.3, blue: 0.3),
                        isSelected: woundBedTypes.contains("granulation"),
                        action: { toggle(&woundBedTypes, "granulation") }
                    )
                    
                    WoundBedOption(
                        title: "Yellow/Gray Slough",
                        subtitle: "Devitalized tissue",
                        color: Color(red: 0.8, green: 0.7, blue: 0.4),
                        isSelected: woundBedTypes.contains("slough"),
                        action: { toggle(&woundBedTypes, "slough") }
                    )
                    
                    WoundBedOption(
                        title: "Black/Brown Eschar",
                        subtitle: "Dead necrotic tissue",
                        color: Color(white: 0.2),
                        isSelected: woundBedTypes.contains("necrosis"),
                        action: { toggle(&woundBedTypes, "necrosis") }
                    )
                    
                    WoundBedOption(
                        title: "Shiny Pink Epithelializing",
                        subtitle: "New skin forming",
                        color: Color(red: 1.0, green: 0.7, blue: 0.8),
                        isSelected: woundBedTypes.contains("epithelializing"),
                        action: { toggle(&woundBedTypes, "epithelializing") }
                    )
                }
                
                if woundBedTypes.contains("necrosis") || woundBedTypes.contains("slough") {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("Debridement may be needed to remove devitalized tissue")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var exudateStep: some View {
        questionCard(title: "Exudate Level") {
            VStack(alignment: .leading, spacing: 12) {
                Text("How much drainage/moisture?")
                    .font(.subheadline.weight(.semibold))
                
                SegmentedChips(selection: $exudate, options: exudateOptions) {
                    goNext()
                }
                
                if exudate == "high" {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("High absorbency dressing will be recommended")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var deepSpacesStep: some View {
        questionCard(title: "Deep Spaces") {
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $hasDeepSpaces) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Any cavities, tunnels, or undermining?")
                            .font(.subheadline.weight(.semibold))
                        Text("Areas extending beyond visible wound edges")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: hasDeepSpaces) { val in
                    if !val { deepSpaceType.removeAll() }
                    Haptics.light()
                }
                
                if hasDeepSpaces {
                    VStack(spacing: 8) {
                        Text("Select all that apply:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        MultiTagChips(
                            selection: $deepSpaceType,
                            options: [
                                .init(id: "cavity", label: "Cavity (depression)", sfSymbol: nil),
                                .init(id: "tunnel", label: "Tunnel (channel)", sfSymbol: nil),
                                .init(id: "undermining", label: "Undermining (edges)", sfSymbol: nil)
                            ]
                        )
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("These spaces need packing to prevent abscess formation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var periwoundSkinStep: some View {
        questionCard(title: "Peri-wound Skin") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Skin condition around the wound:")
                    .font(.subheadline.weight(.semibold))
                
                SegmentedChips(selection: $periwoundSkin, options: periwoundOptions) {
                    goNext()
                }
                
                if periwoundSkin == "macerated" {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Barrier cream and better exudate management needed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var infectionStep: some View {
        questionCard(title: "Infection Signs") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select all signs present:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    ToggleRow(title: "Warmth around wound", isOn: $hasWarmth)
                    ToggleRow(title: "Purulent discharge (pus)", isOn: $hasPurulentDischarge)
                    ToggleRow(title: "Foul odor", isOn: $hasOdor)
                    ToggleRow(title: "Spreading redness", isOn: $hasSpreadingRedness)
                    ToggleRow(title: "Erythema > 2cm from edge", isOn: $hasErythemaGt2cm)
                    ToggleRow(title: "Fever / systemic symptoms", isOn: $hasFever)
                    ToggleRow(title: "Crepitus (gas/crackling)", isOn: $hasCrepitus)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasAnyInfectionSign ? Color.orange.opacity(0.08) : Color(.systemGray6))
                )
                
                if hasAnyInfectionSign {
                    let severity = infectionSeverity
                    HStack(spacing: 8) {
                        Image(systemName: severity == .systemic ? "exclamationmark.triangle.fill" : "info.circle.fill")
                            .foregroundColor(severity == .systemic ? .red : .orange)
                        Text(severity == .systemic
                            ? "⚠️ URGENT: Systemic infection - patient needs immediate medical evaluation"
                            : "Local infection present - antimicrobial dressing recommended")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill((severity == .systemic ? Color.red : Color.orange).opacity(0.12))
                    )
                }
            }
        }
    }

    private var boneInvolvementStep: some View {
        questionCard(title: "Bone Involvement") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Check for deep infection:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ToggleRow(title: "Exposed bone visible", isOn: $hasExposedBone)
                
                Divider().padding(.vertical, 4)
                
                HStack {
                    ToggleRow(title: "Probe to bone test positive", isOn: $probeToBonePositive)
                    HelpButton(text: "Probe to bone: Using a sterile probe, can you feel hard bone at the wound base? This suggests osteomyelitis (bone infection).")
                }

                if hasExposedBone || probeToBonePositive {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("⚠️ URGENT: Possible osteomyelitis - X-ray/MRI and specialist referral needed")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var perfusionStep: some View {
        questionCard(title: "Perfusion Assessment") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Assess blood flow (determines compression safety):")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Pedal pulses
                HStack {
                    Text("Pedal pulses palpable?")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Picker("", selection: $pedalPulsesPalpable) {
                        Text("Unknown").tag(nil as Bool?)
                        Text("No").tag(false as Bool?)
                        Text("Yes").tag(true as Bool?)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                
                Divider().padding(.vertical, 4)
                
                // Clinical signs
                ToggleRow(title: "Cold, pale, or blue foot", isOn: $coldPaleFoot)
                ToggleRow(title: "Rest pain relieved by hanging leg down", isOn: $restPainRelievedByHanging)
                
                Divider().padding(.vertical, 4)
                
                // ABI
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ABI (if available)")
                            .font(.subheadline.weight(.semibold))
                        HelpButton(text: "Ankle-Brachial Index measures blood flow. Normal: 0.9-1.3. Values <0.8 indicate poor circulation and contraindicate compression therapy.")
                    }
                    
                    SegmentedChips(selection: $abi, options: abiOptions)
                }
                
                // Warnings
                if pedalPulsesPalpable == false || coldPaleFoot || restPainRelievedByHanging || abi == "lt0_5" {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("⚠️ Poor perfusion detected - compression contraindicated, vascular assessment needed")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                } else if abi == "p0_5to0_79" {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Reduced perfusion - only reduced compression (20-30mmHg) if venous disease present")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            if !navigationHistory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if !woundBedTypes.isEmpty {
                            summaryChip(woundBedTypes.map { $0.capitalized }.joined(separator: ", "), icon: "checkmark.circle.fill")
                        }
                        if !exudate.isEmpty {
                            summaryChip(exudate.capitalized + " exudate", icon: "drop.fill")
                        }
                        if hasAnyInfectionSign {
                            summaryChip(
                                infectionSeverity == .systemic ? "Systemic infection" : "Local infection",
                                icon: "exclamationmark.triangle.fill",
                                color: infectionSeverity == .systemic ? .red : .orange
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 32)
            }

            HStack(spacing: 10) {
                Button { goBack() } label: {
                    Label("Back", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(navigationHistory.isEmpty)

                Button {
                    if isLastStep {
                        save()
                    } else {
                        goNext()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isLastStep ? "Analyze & Generate Report" : "Next")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isStepAnswered(step))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
    }

    private func summaryChip(_ text: String, icon: String = "checkmark.circle.fill", color: Color = .green) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .imageScale(.small)
            Text(text)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.15)))
        .foregroundColor(color)
    }

    // MARK: - Navigation Logic

    private var estimatedTotalSteps: Int {
        var total = 5 // woundBed, exudate, deepSpaces, periwoundSkin, infection
        if shouldShowBoneQuestions { total += 1 }
        if shouldShowPerfusion { total += 1 }
        return total
    }

    private var shouldShowBoneQuestions: Bool {
        // Show if diabetic foot OR has necrosis
        return (context.hasDiabetes == true && context.isFootLocation) ||
               woundBedTypes.contains("necrosis")
    }

    private var shouldShowPerfusion: Bool {
        // Show if lower limb (compression considerations)
        return context.isLowerLimb
    }

    private var isLastStep: Bool {
        if shouldShowPerfusion { return step == .perfusion }
        if shouldShowBoneQuestions { return step == .boneInvolvement }
        return step == .infection
    }

    private var hasAnyInfectionSign: Bool {
        hasWarmth || hasPurulentDischarge || hasOdor || hasSpreadingRedness ||
        hasErythemaGt2cm || hasFever || hasCrepitus
    }

    private enum InfectionSeverity { case none, local, systemic }
    
    private var infectionSeverity: InfectionSeverity {
        if hasFever || hasCrepitus || hasSpreadingRedness { return .systemic }
        if hasAnyInfectionSign { return .local }
        return .none
    }

    private var urgentBannerText: String? {
        if infectionSeverity == .systemic {
            return "⚠️ URGENT: Systemic infection - immediate medical evaluation required"
        }
        if hasExposedBone || probeToBonePositive {
            return "⚠️ URGENT: Possible osteomyelitis - imaging and specialist referral needed"
        }
        if pedalPulsesPalpable == false || abi == "lt0_5" {
            return "⚠️ URGENT: Severe ischemia - vascular assessment required"
        }
        return nil
    }

    private func goNext() {
        guard let next = nextStep(after: step) else {
            save()
            return
        }
        
        Haptics.light()
        navigationHistory.append(step)
        
        withAnimation(.easeInOut(duration: 0.25)) {
            step = next
        }
    }

    private func goBack() {
        guard let previous = navigationHistory.popLast() else { return }
        
        Haptics.light()
        withAnimation(.easeInOut(duration: 0.25)) {
            step = previous
        }
    }

    private func nextStep(after current: Step) -> Step? {
        switch current {
        case .woundBed: return .exudate
        case .exudate: return .deepSpaces
        case .deepSpaces: return .periwoundSkin
        case .periwoundSkin: return .infection
        case .infection:
            if shouldShowBoneQuestions { return .boneInvolvement }
            if shouldShowPerfusion { return .perfusion }
            return nil
        case .boneInvolvement:
            if shouldShowPerfusion { return .perfusion }
            return nil
        case .perfusion: return nil
        }
    }

    private func isStepAnswered(_ s: Step) -> Bool {
        switch s {
        case .woundBed: return !woundBedTypes.isEmpty
        case .exudate: return !exudate.isEmpty
        case .deepSpaces: return true // Can skip
        case .periwoundSkin: return !periwoundSkin.isEmpty
        case .infection: return true // Can have no signs
        case .boneInvolvement: return true // Can be negative
        case .perfusion: return pedalPulsesPalpable != nil || !abi.isEmpty
        }
    }

    // MARK: - Save

    private func save() {
        isSaving = true

        if isQuickScan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSaving = false
                showNextView = true
            }
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("woundGroups").document(woundGroupId)

        let payload = buildQuestionnairePayload()

        ref.setData(["questionnaire": payload], merge: true) { error in
            DispatchQueue.main.async {
                isSaving = false
                if error == nil {
                    showNextView = true
                }
            }
        }
    }

    private func buildQuestionnairePayload() -> [String: Any] {
        return [
            "woundBedTypes": Array(woundBedTypes),
            "exudate": exudate,
            "hasDeepSpaces": hasDeepSpaces,
            "deepSpaceType": Array(deepSpaceType),
            "periwoundSkin": periwoundSkin,
            "infectionSigns": [
                "warmth": hasWarmth,
                "purulentDischarge": hasPurulentDischarge,
                "odor": hasOdor,
                "spreadingRedness": hasSpreadingRedness,
                "erythemaGt2cm": hasErythemaGt2cm,
                "fever": hasFever,
                "crepitus": hasCrepitus
            ],
            "hasExposedBone": hasExposedBone,
            "probeToBonePositive": probeToBonePositive,
            "pedalPulsesPalpable": pedalPulsesPalpable as Any,
            "coldPaleFoot": coldPaleFoot,
            "restPainRelievedByHanging": restPainRelievedByHanging,
            "abi": abi,
            "completedAt": FieldValue.serverTimestamp()
        ]
    }

    // MARK: - Helpers

    private func toggle(_ set: inout Set<String>, _ value: String) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
        Haptics.light()
    }

    private func questionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title3.bold()).padding(.horizontal)
            GroupCard { content() }
                .padding(.horizontal)
            Spacer(minLength: 24)
        }
    }
}

// MARK: - UI Components

private struct WoundBedOption: View {
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .imageScale(.large)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct StepIndicator: View {
    let currentIndex: Int
    let total: Int
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(1...total, id: \.self) { i in
                    Circle()
                        .fill(i <= currentIndex ? Color.blue : Color.blue.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
            Text("Step \(currentIndex) of \(total): \(title)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private enum BannerStyle { case danger, warning, info }

private struct Banner: View {
    let text: String
    let style: BannerStyle
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text).font(.footnote.weight(.semibold))
            Spacer()
        }
        .foregroundColor(style == .danger ? .red : .orange)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((style == .danger ? Color.red : Color.orange).opacity(0.12))
        )
    }
}

private struct GroupCard<Content: View>: View {
    private let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
    }
}

private struct SegmentedChips: View {
    @Binding var selection: String
    let options: [Option]
    var onSelect: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dts
    private var minChip: CGFloat { dts >= .accessibility2 ? 120 : 110 }
    private var cols: [GridItem] { [GridItem(.adaptive(minimum: minChip), spacing: 8)] }

    var body: some View {
        LazyVGrid(columns: cols, spacing: 8) {
            ForEach(options) { opt in
                let selected = selection == opt.id
                Button {
                    selection = opt.id
                    Haptics.light()
                    onSelect()
                } label: {
                    Text(opt.label)
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(selected ? Color.blue : Color(.systemGray6))
                        .foregroundColor(selected ? .white : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct MultiTagChips: View {
    @Binding var selection: Set<String>
    let options: [Option]

    @Environment(\.dynamicTypeSize) private var dts
    private var minChip: CGFloat { dts >= .accessibility2 ? 140 : 130 }
    private var cols: [GridItem] { [GridItem(.adaptive(minimum: minChip), spacing: 8)] }

    var body: some View {
        LazyVGrid(columns: cols, spacing: 8) {
            ForEach(options) { opt in
                let isSel = selection.contains(opt.id)
                Button {
                    if isSel { selection.remove(opt.id) } else { selection.insert(opt.id) }
                    Haptics.light()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isSel ? "checkmark.circle.fill" : "circle").imageScale(.small)
                        Text(opt.label).font(.callout.weight(.semibold))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(isSel ? Color.blue : Color(.systemGray6))
                    .foregroundColor(isSel ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 999))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).font(.subheadline)
        }
        .onChange(of: isOn) { _ in Haptics.light() }
    }
}

private struct HelpButton: View {
    let text: String
    @State private var showHelp = false
    
    var body: some View {
        Button {
            showHelp = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
                .imageScale(.medium)
        }
        .alert("Help", isPresented: $showHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(text)
        }
    }
}

private struct Option: Identifiable, Hashable {
    let id: String
    let label: String
    let sfSymbol: String?
}

// Options

private var exudateOptions: [Option] {
    [
        .init(id: "dry", label: "Dry", sfSymbol: nil),
        .init(id: "low", label: "Low", sfSymbol: nil),
        .init(id: "moderate", label: "Moderate", sfSymbol: nil),
        .init(id: "high", label: "High", sfSymbol: nil)
    ]
}

private var periwoundOptions: [Option] {
    [
        .init(id: "normal", label: "Normal", sfSymbol: nil),
        .init(id: "macerated", label: "Macerated (wet/white)", sfSymbol: nil),
        .init(id: "fragile", label: "Fragile/friable", sfSymbol: nil)
    ]
}

private var abiOptions: [Option] {
    [
        .init(id: "unknown", label: "Unknown", sfSymbol: nil),
        .init(id: "ge0_8", label: "≥ 0.8 (Normal)", sfSymbol: nil),
        .init(id: "p0_5to0_79", label: "0.5-0.79 (Reduced)", sfSymbol: nil),
        .init(id: "lt0_5", label: "< 0.5 (Severe)", sfSymbol: nil)
    ]
}

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
