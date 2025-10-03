import SwiftUI
import UIKit
import FirebaseFirestore

// MARK: - Optimized Questionnaire (8 steps with skip logic)

struct QuestionnaireView: View {
    let woundGroupId: String
    let patientId: String

    @ObservedObject var langManager = LocalizationManager.shared

    // Streamlined steps
    enum Step: Int, CaseIterable, Hashable {
        case etiology
        case tissueInfection   // Combined
        case moisture
        case edge
        case perfusion         // Skipped for venous/pressure
        case boneInvolvement   // Skipped if not relevant
        case comorbidities
        case redFlags

        var title: String {
            switch self {
            case .etiology: return LocalizedStrings.secEtiology
            case .tissueInfection: return "Tissue & Infection"
            case .moisture: return LocalizedStrings.secMoisture
            case .edge: return LocalizedStrings.secEdge
            case .perfusion: return LocalizedStrings.secPerfusion
            case .boneInvolvement: return "Bone & Depth"
            case .comorbidities: return LocalizedStrings.secComorbidities
            case .redFlags: return LocalizedStrings.secRedFlags
            }
        }
    }

    // Core answers
    @State private var etiology: String = "unknown"
    @State private var duration: String = "unknown"
    @State private var tissue: String = "unknown"
    @State private var infection: String = "none"
    @State private var moisture: String = "unknown"
    @State private var edge: String = "unknown"
    @State private var abi: String = "unknown"
    @State private var pulses: String = "unknown"
    @State private var exposedBone = false
    @State private var probeToBone = false
    @State private var comorbidities: Set<String> = []
    @State private var redFlags: Set<String> = []

    // Infection detail (shown conditionally)
    @State private var showInfectionDetail = false
    @State private var hasPurulence = false
    @State private var hasErythema = false
    @State private var hasSystemicSigns = false

    // UX
    @State private var isSaving = false
    @State private var showNextView = false
    @State private var step: Step = .etiology
    @State private var completedSteps: Set<Step> = []
    @State private var showResumeBanner = false

    // Navigation history for smart back button
    @State private var navigationHistory: [Step] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                StepIndicator(
                    currentIndex: currentIndex,
                    total: estimatedTotalSteps,
                    title: step.title
                )
                .padding(.top, 8)

                if let urgent = urgentBannerText {
                    Banner(text: urgent, style: .danger)
                        .padding(.horizontal)
                }

                if showResumeBanner {
                    resumeBanner
                }
            }
            .padding(.bottom, 8)

            // Steps
            TabView(selection: $step) {
                etiologyStep.tag(Step.etiology)
                tissueInfectionStep.tag(Step.tissueInfection)
                moistureStep.tag(Step.moisture)
                edgeStep.tag(Step.edge)
                perfusionStep.tag(Step.perfusion)
                boneInvolvementStep.tag(Step.boneInvolvement)
                comorbiditiesStep.tag(Step.comorbidities)
                redFlagsStep.tag(Step.redFlags)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNextView) {
            ReportView(woundGroupId: woundGroupId, patientId: patientId)
        }
        .onAppear(perform: loadDraft)
        .onChange(of: etiology) { autoSave() }
        .onChange(of: tissue) { autoSave() }
        .onChange(of: infection) { autoSave() }
    }

    // MARK: - Steps

    private var etiologyStep: some View {
        questionCard(title: LocalizedStrings.secEtiology) {
            VStack(spacing: 16) {
                // Quick templates at top
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick start").font(.caption).foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            templateChip("Venous leg ulcer") {
                                applyVenousTemplate()
                            }
                            templateChip("Pressure injury") {
                                applyPressureTemplate()
                            }
                            templateChip("Diabetic foot") {
                                applyDiabeticTemplate()
                            }
                        }
                    }
                }
                .padding(.bottom, 8)

                Divider()

                IconChoiceGrid(selection: $etiology, options: etiologyOptions) {
                    markComplete(.etiology)
                    goNext()
                }
            }
        }
    }

    private var tissueInfectionStep: some View {
        questionCard(title: "Tissue & Infection") {
            VStack(alignment: .leading, spacing: 16) {
                // Tissue
                Text("Predominant tissue type")
                    .font(.subheadline.weight(.semibold))
                SegmentedChips(selection: $tissue, options: tissueOptions)

                Divider().padding(.vertical, 4)

                // Infection severity
                Text("Infection/inflammation signs")
                    .font(.subheadline.weight(.semibold))
                SeverityScale(selection: $infection, options: infectionOptions) {
                    showInfectionDetail = (infection != "none")
                    if !showInfectionDetail {
                        markComplete(.tissueInfection)
                        goNext()
                    }
                }

                if showInfectionDetail {
                    VStack(spacing: 10) {
                        Text("Clinical signs present:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ToggleRow(title: "Purulent discharge", isOn: $hasPurulence)
                        ToggleRow(title: "Erythema >2cm", isOn: $hasErythema)
                        ToggleRow(title: "Fever/systemic illness", isOn: $hasSystemicSigns)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.08))
                    )
                }

                if infection == "systemic" {
                    GuardrailBadge(text: "⚠️ Urgent: Consider systemic antibiotics & specialist referral")
                }
            }
        }
    }

    private var moistureStep: some View {
        questionCard(title: LocalizedStrings.secMoisture) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Exudate level")
                    .font(.subheadline.weight(.semibold))
                
                SegmentedChips(selection: $moisture, options: moistureOptions) {
                    markComplete(.moisture)
                    goNext()
                }
                
                if moisture == "high" {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("High exudate → superabsorbent dressing recommended")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var edgeStep: some View {
        questionCard(title: LocalizedStrings.secEdge) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Wound edge appearance")
                    .font(.subheadline.weight(.semibold))
                
                TagChips(selection: $edge, options: edgeOptions) {
                    markComplete(.edge)
                    goNext()
                }
            }
        }
    }

    private var perfusionStep: some View {
        questionCard(title: "Perfusion Assessment") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ankle-Brachial Index (ABI)")
                    .font(.subheadline.weight(.semibold))
                SegmentedChips(selection: $abi, options: abiOptions)

                Divider().padding(.vertical, 4)

                Text("Palpable pedal pulses")
                    .font(.subheadline.weight(.semibold))
                SegmentedChips(selection: $pulses, options: pulsesOptions) {
                    markComplete(.perfusion)
                    goNext()
                }

                if abi == "lt0_5" {
                    GuardrailBadge(text: "⚠️ Severe ischemia - compression contraindicated, urgent vascular referral")
                }
            }
        }
    }

    private var boneInvolvementStep: some View {
        questionCard(title: "Bone & Deep Structures") {
            VStack(alignment: .leading, spacing: 16) {
                ToggleRow(title: "Bone visible in wound bed", isOn: $exposedBone)
                
                Divider().padding(.vertical, 4)
                
                ToggleRow(title: "Probe to bone positive", isOn: $probeToBone)

                if exposedBone || probeToBone {
                    GuardrailBadge(text: "⚠️ Possible osteomyelitis - consider X-ray, MRI, or bone biopsy")
                }
            }
        }
    }

    private var comorbiditiesStep: some View {
        questionCard(title: LocalizedStrings.secComorbidities) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select all that apply")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                MultiTagChips(selection: $comorbidities, options: comorbidityOptions)
            }
        }
    }

    private var redFlagsStep: some View {
        questionCard(title: LocalizedStrings.secRedFlags) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Any concerning signs?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                MultiTagChips(selection: $redFlags, options: redFlagOptions)

                if showsRedFlagsWarning {
                    GuardrailBadge(text: "⚠️ Red flags present - escalate to specialist immediately")
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            // Inline summary
            if !completedSteps.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if etiology != "unknown" {
                            summaryChip(labelFor(etiology, in: etiologyOptions), icon: "checkmark.circle.fill")
                        }
                        if tissue != "unknown" {
                            summaryChip(labelFor(tissue, in: tissueOptions), icon: "drop.fill")
                        }
                        if infection != "none" {
                            summaryChip(
                                labelFor(infection, in: infectionOptions),
                                icon: "exclamationmark.triangle.fill",
                                color: infection == "systemic" ? .red : .orange
                            )
                        }
                        if moisture != "unknown" {
                            summaryChip(labelFor(moisture, in: moistureOptions), icon: "drop.fill")
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 32)
            }

            HStack(spacing: 10) {
                Button {
                    goBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(navigationHistory.isEmpty)

                Button {
                    if isLastStep {
                        save()
                    } else {
                        markComplete(step)
                        goNext()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isLastStep ? "Save & Analyze" : "Next")
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
        .background(
            Capsule().fill(color.opacity(0.15))
        )
        .foregroundColor(color)
    }

    private var resumeBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.clockwise.circle.fill")
            Text("Resume from where you left off")
                .font(.footnote.weight(.medium))
            Spacer()
            Button("Start over") {
                clearDraft()
                showResumeBanner = false
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Navigation with Skip Logic

    private var currentIndex: Int {
        navigationHistory.count + 1
    }

    private var estimatedTotalSteps: Int {
        var total = 5 // etiology, tissue+infection, moisture, edge, comorbidities, redflags
        
        // Add perfusion if arterial/diabetic
        if etiology == "arterial" || etiology == "diabeticFoot" {
            total += 1
        }
        
        // Add bone if diabetic foot or necrotic
        if etiology == "diabeticFoot" || tissue == "necrosis" {
            total += 1
        }
        
        return total
    }

    private var isLastStep: Bool {
        step == .redFlags
    }

    private func goNext() {
        guard let next = nextStep(after: step) else {
            // Reached end, save
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
        case .etiology:
            return .tissueInfection
            
        case .tissueInfection:
            return .moisture
            
        case .moisture:
            return .edge
            
        case .edge:
            // Skip perfusion for venous/pressure (rarely ischemic)
            if etiology == "venous" || etiology == "pressure" {
                return .comorbidities
            }
            return .perfusion
            
        case .perfusion:
            // Skip bone involvement if not diabetic foot and not necrotic
            if etiology != "diabeticFoot" && tissue != "necrosis" {
                return .comorbidities
            }
            return .boneInvolvement
            
        case .boneInvolvement:
            return .comorbidities
            
        case .comorbidities:
            return .redFlags
            
        case .redFlags:
            return nil // Done
        }
    }

    private func isStepAnswered(_ s: Step) -> Bool {
        switch s {
        case .etiology: return etiology != "unknown"
        case .tissueInfection: return tissue != "unknown" && infection != "unknown"
        case .moisture: return moisture != "unknown"
        case .edge: return edge != "unknown"
        case .perfusion: return abi != "unknown" && pulses != "unknown"
        case .boneInvolvement: return true // toggles always valid
        case .comorbidities: return true
        case .redFlags: return true
        }
    }

    private func markComplete(_ step: Step) {
        completedSteps.insert(step)
    }

    // MARK: - Quick Templates

    private func templateChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.blue.opacity(0.15)))
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }

    private func applyVenousTemplate() {
        etiology = "venous"
        tissue = "granulation"
        infection = "none"
        moisture = "moderate"
        edge = "attached"
        // Skip perfusion automatically via logic
        Haptics.success()
    }

    private func applyPressureTemplate() {
        etiology = "pressure"
        tissue = "slough"
        infection = "local"
        moisture = "moderate"
        edge = "undermined"
        Haptics.success()
    }

    private func applyDiabeticTemplate() {
        etiology = "diabeticFoot"
        tissue = "necrosis"
        infection = "local"
        moisture = "low"
        edge = "rolled"
        probeToBone = true
        comorbidities.insert("diabetes")
        comorbidities.insert("neuropathy")
        Haptics.success()
    }

    // MARK: - Auto-save

    private func autoSave() {
        let draft: [String: Any] = [
            "etiology": etiology,
            "tissue": tissue,
            "infection": infection,
            "moisture": moisture,
            "edge": edge,
            "abi": abi,
            "pulses": pulses,
            "exposedBone": exposedBone,
            "probeToBone": probeToBone,
            "comorbidities": Array(comorbidities),
            "redFlags": Array(redFlags),
            "timestamp": Date().timeIntervalSince1970
        ]
        UserDefaults.standard.set(draft, forKey: "questionnaire_draft_\(woundGroupId)")
    }

    private func loadDraft() {
        guard let draft = UserDefaults.standard.dictionary(forKey: "questionnaire_draft_\(woundGroupId)") else {
            return
        }
        
        // Check if draft is recent (< 24 hours old)
        if let timestamp = draft["timestamp"] as? TimeInterval {
            let age = Date().timeIntervalSince1970 - timestamp
            if age > 86400 { // 24 hours
                clearDraft()
                return
            }
        }
        
        etiology = draft["etiology"] as? String ?? "unknown"
        tissue = draft["tissue"] as? String ?? "unknown"
        infection = draft["infection"] as? String ?? "none"
        moisture = draft["moisture"] as? String ?? "unknown"
        edge = draft["edge"] as? String ?? "unknown"
        abi = draft["abi"] as? String ?? "unknown"
        pulses = draft["pulses"] as? String ?? "unknown"
        exposedBone = draft["exposedBone"] as? Bool ?? false
        probeToBone = draft["probeToBone"] as? Bool ?? false
        comorbidities = Set(draft["comorbidities"] as? [String] ?? [])
        redFlags = Set(draft["redFlags"] as? [String] ?? [])
        
        if etiology != "unknown" {
            showResumeBanner = true
        }
    }

    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: "questionnaire_draft_\(woundGroupId)")
        etiology = "unknown"
        tissue = "unknown"
        infection = "none"
        moisture = "unknown"
        edge = "unknown"
        abi = "unknown"
        pulses = "unknown"
        exposedBone = false
        probeToBone = false
        comorbidities = []
        redFlags = []
        completedSteps = []
        navigationHistory = []
        step = .etiology
    }

    // MARK: - Logic

    private var showsRedFlagsWarning: Bool {
        redFlags.contains("spreadingErythema") ||
        redFlags.contains("crepitus") ||
        redFlags.contains("systemicUnwell")
    }

    private var urgentBannerText: String? {
        if infection == "systemic" || showsRedFlagsWarning {
            return "⚠️ URGENT: Systemic signs - immediate medical attention required"
        }
        if abi == "lt0_5" {
            return "⚠️ Severe ischemia detected - urgent vascular surgery referral"
        }
        return nil
    }

    private func save() {
        isSaving = true

        let db = Firestore.firestore()
        let ref = db.collection("woundGroups").document(woundGroupId)

        let payload: [String: Any] = [
            "etiology": etiology,
            "duration": duration,
            "tissue": tissue,
            "infection": infection,
            "infectionSigns": [
                "purulence": hasPurulence,
                "erythema": hasErythema,
                "systemic": hasSystemicSigns
            ],
            "moisture": moisture,
            "edge": edge,
            "abi": abi,
            "pulses": pulses,
            "exposedBone": exposedBone,
            "probeToBone": probeToBone,
            "comorbidities": Array(comorbidities),
            "redFlags": Array(redFlags),
            "completedAt": FieldValue.serverTimestamp(),
            "patientId": patientId
        ]

        ref.setData(["questionnaire": payload], merge: true) { error in
            DispatchQueue.main.async {
                isSaving = false
                if error == nil {
                    clearDraft() // Clear saved draft
                    showNextView = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func questionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal)

            GroupCard { content() }
                .padding(.horizontal)

            Spacer(minLength: 24)
        }
    }

    private func labelFor(_ id: String, in options: [Option]) -> String {
        options.first(where: { $0.id == id })?.label ?? id.capitalized
    }
}

// MARK: - UI Components (reused from original)

private struct StepIndicator: View {
    let currentIndex: Int
    let total: Int
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(1...total, id: \.self) { i in
                    Circle()
                        .fill(i <= currentIndex ? Color.primaryBlue : Color.primaryBlue.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
            Text("Step \(currentIndex) of \(total)  •  \(title)")
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

private struct GuardrailBadge: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill").imageScale(.small)
            Text(text).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.orange.opacity(0.15)))
        .foregroundColor(.orange)
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

// MARK: - Input Components (reused from original with minor tweaks)

private struct IconChoiceGrid: View {
    @Binding var selection: String
    let options: [Option]
    var onSelect: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dts
    private var minCell: CGFloat { dts >= .accessibility2 ? 140 : 120 }
    private var cols: [GridItem] { [GridItem(.adaptive(minimum: minCell), spacing: 10)] }

    var body: some View {
        LazyVGrid(columns: cols, spacing: 10) {
            ForEach(options) { opt in
                let selected = selection == opt.id
                Button {
                    selection = opt.id
                    Haptics.light()
                    onSelect()
                } label: {
                    VStack(spacing: 8) {
                        if let s = opt.sfSymbol {
                            Image(systemName: s)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(selected ? .white : .primary)
                        }
                        Text(opt.label)
                            .font(.callout.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 76)
                    .padding(12)
                    .background(selected ? Color.primaryBlue : Color(.systemGray6))
                    .foregroundColor(selected ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
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
                        .background(selected ? Color.primaryBlue : Color(.systemGray6))
                        .foregroundColor(selected ? .white : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SeverityScale: View {
    @Binding var selection: String
    let options: [Option]
    var onSelect: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options) { opt in
                let selected = selection == opt.id
                Button {
                    selection = opt.id
                    Haptics.light()
                    onSelect()
                } label: {
                    Text(opt.label)
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(color(for: opt.id, selected: selected))
                        .foregroundColor(selected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func color(for id: String, selected: Bool) -> Color {
        switch id {
        case "none": return selected ? .green : .green.opacity(0.15)
        case "local": return selected ? .orange : .orange.opacity(0.18)
        case "systemic": return selected ? .red : .red.opacity(0.18)
        default: return Color(.systemGray5)
        }
    }
}

private struct TagChips: View {
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
                    HStack(spacing: 6) {
                        if selected { Image(systemName: "checkmark.circle.fill").imageScale(.small) }
                        Text(opt.label).font(.callout.weight(.semibold))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(selected ? Color.primaryBlue : Color(.systemGray6))
                    .foregroundColor(selected ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 999))
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
                    .background(isSel ? Color.primaryBlue : Color(.systemGray6))
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
        .onChange(of: isOn) { oldValue, newValue in
            if newValue {
                Haptics.light()
            }
         }
    }
}

// MARK: - Models (reused from original)

private struct Option: Identifiable, Hashable {
    let id: String
    let label: String
    let sfSymbol: String?
}

// Options (same as before)
private var etiologyOptions: [Option] {
    [
        .init(id: "venous", label: LocalizedStrings.optEtiologyVenous, sfSymbol: "drop.fill"),
        .init(id: "arterial", label: LocalizedStrings.optEtiologyArterial, sfSymbol: "heart.fill"),
        .init(id: "diabeticFoot", label: LocalizedStrings.optEtiologyDiabetic, sfSymbol: "figure.walk"),
        .init(id: "pressure", label: LocalizedStrings.optEtiologyPressure, sfSymbol: "bed.double.fill"),
        .init(id: "trauma", label: LocalizedStrings.optEtiologyTrauma, sfSymbol: "bandage.fill"),
        .init(id: "surgical", label: LocalizedStrings.optEtiologySurgical, sfSymbol: "scissors"),
        .init(id: "unknown", label: LocalizedStrings.optUnknown, sfSymbol: "questionmark.circle")
    ]
}

private var tissueOptions: [Option] {
    [
        .init(id: "granulation", label: LocalizedStrings.optTissueGranulation, sfSymbol: nil),
        .init(id: "slough", label: LocalizedStrings.optTissueSlough, sfSymbol: nil),
        .init(id: "necrosis", label: LocalizedStrings.optTissueNecrosis, sfSymbol: nil),
        .init(id: "unknown", label: LocalizedStrings.optUnknown, sfSymbol: nil)
    ]
}

private var infectionOptions: [Option] {
    [
        .init(id: "none", label: LocalizedStrings.optInfectionNone, sfSymbol: nil),
        .init(id: "local", label: LocalizedStrings.optInfectionLocal, sfSymbol: nil),
        .init(id: "systemic", label: LocalizedStrings.optInfectionSystemic, sfSymbol: nil)
    ]
}

private var moistureOptions: [Option] {
    [
        .init(id: "dry", label: LocalizedStrings.optMoistureDry, sfSymbol: nil),
        .init(id: "low", label: LocalizedStrings.optMoistureLow, sfSymbol: nil),
        .init(id: "moderate", label: LocalizedStrings.optMoistureModerate, sfSymbol: nil),
        .init(id: "high", label: LocalizedStrings.optMoistureHigh, sfSymbol: nil)
    ]
}

private var edgeOptions: [Option] {
    [
        .init(id: "attached", label: LocalizedStrings.optEdgeAttached, sfSymbol: nil),
        .init(id: "rolled", label: LocalizedStrings.optEdgeRolled, sfSymbol: nil),
        .init(id: "undermined", label: LocalizedStrings.optEdgeUndermined, sfSymbol: nil)
    ]
}

private var abiOptions: [Option] {
    [
        .init(id: "ge0_8", label: LocalizedStrings.optAbiGE0_8, sfSymbol: nil),
        .init(id: "p0_5to0_79", label: LocalizedStrings.optAbi0_5to0_79, sfSymbol: nil),
        .init(id: "lt0_5", label: LocalizedStrings.optAbiLT0_5, sfSymbol: nil),
        .init(id: "unknown", label: LocalizedStrings.optUnknown, sfSymbol: nil)
    ]
}

private var pulsesOptions: [Option] {
    [
        .init(id: "yes", label: LocalizedStrings.optYes, sfSymbol: nil),
        .init(id: "no", label: LocalizedStrings.optNo, sfSymbol: nil),
        .init(id: "unknown", label: LocalizedStrings.optUnknown, sfSymbol: nil)
    ]
}

private var comorbidityOptions: [Option] {
    [
        .init(id: "diabetes", label: LocalizedStrings.optCoDiabetes, sfSymbol: nil),
        .init(id: "pad", label: LocalizedStrings.optCoPAD, sfSymbol: nil),
        .init(id: "neuropathy", label: LocalizedStrings.optCoNeuropathy, sfSymbol: nil),
        .init(id: "immunosuppressed", label: LocalizedStrings.optCoImmuno, sfSymbol: nil),
        .init(id: "anticoagulants", label: LocalizedStrings.optCoAnticoag, sfSymbol: nil)
    ]
}

private var redFlagOptions: [Option] {
    [
        .init(id: "spreadingErythema", label: LocalizedStrings.optRFSpread, sfSymbol: nil),
        .init(id: "severePain", label: LocalizedStrings.optRFPain, sfSymbol: nil),
        .init(id: "crepitus", label: LocalizedStrings.optRFCrepitus, sfSymbol: nil),
        .init(id: "systemicUnwell", label: LocalizedStrings.optRFSystemic, sfSymbol: nil)
    ]
}

// MARK: - Haptics Helper

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
