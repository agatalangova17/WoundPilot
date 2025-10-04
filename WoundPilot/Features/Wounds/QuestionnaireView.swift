import SwiftUI
import UIKit
import FirebaseFirestore

struct QuestionnaireView: View {
    let woundGroupId: String
    let patientId: String
    var isQuickScan: Bool = false
    var measurementResult: WoundMeasurementResult? = nil

    @ObservedObject var langManager = LocalizationManager.shared

    enum Step: Int, CaseIterable, Hashable {
        case etiology
        case duration
        case tissue
        case infection
        case moisture
        case edge
        case perfusion
        case boneInvolvement
        case comorbidities
        case redFlags

        var title: String {
            switch self {
            case .etiology: return LocalizedStrings.secEtiology
            case .duration: return LocalizedStrings.secDuration
            case .tissue: return LocalizedStrings.secTissue
            case .infection: return LocalizedStrings.secInfection
            case .moisture: return LocalizedStrings.secMoisture
            case .edge: return LocalizedStrings.secEdge
            case .perfusion: return LocalizedStrings.secPerfusion
            case .boneInvolvement:return LocalizedStrings.secBoneDepth
            case .comorbidities: return LocalizedStrings.secComorbidities
            case .redFlags: return LocalizedStrings.secRedFlags
            }
        }
    }

    // Stored values
    @State private var etiology: String = ""
    @State private var duration: String = ""
    @State private var tissue: String = ""
    @State private var exposedBone = false
    @State private var infection: String = ""
    @State private var probeToBone = false
    @State private var moisture: String = ""
    @State private var edge: String = ""
    @State private var abi: String = ""
    @State private var pulses: String = ""
    @State private var comorbidities: Set<String> = []
    @State private var redFlags: Set<String> = []

    // Infection detail
    @State private var showInfectionDetail = false
    @State private var hasPurulence = false
    @State private var hasErythema = false
    @State private var hasSystemicSigns = false

    // UX
    @State private var isSaving = false
    @State private var showNextView = false
    @State private var step: Step = .etiology
    @State private var completedSteps: Set<Step> = []
    @State private var navigationHistory: [Step] = []

    // Computed properties for conditional rendering
    private var shouldShowPerfusion: Bool {
        etiology == "arterial" || etiology == "diabeticFoot"
    }

    private var shouldShowBoneInvolvement: Bool {
        etiology == "diabeticFoot" || tissue == "necrosis"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                StepIndicator(
                    currentIndex: navigationHistory.count + 1,
                    total: estimatedTotalSteps,
                    title: step.title
                )
                .padding(.top, 8)
                
                // Show wound size if available
                if let measurements = measurementResult {
                    HStack(spacing: 8) {
                        Image(systemName: "ruler")
                            .foregroundColor(.blue)
                        Text("Wound: \(String(format: "%.1f", measurements.lengthCm)) × \(String(format: "%.1f", measurements.widthCm)) cm")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1), in: Capsule())
                }

                if let urgent = urgentBannerText {
                    Banner(text: urgent, style: .danger)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 8)

            TabView(selection: $step) {
                etiologyStep.tag(Step.etiology)
                durationStep.tag(Step.duration)
                tissueStep.tag(Step.tissue)
                infectionStep.tag(Step.infection)
                moistureStep.tag(Step.moisture)
                edgeStep.tag(Step.edge)
                
                if shouldShowPerfusion {
                    perfusionStep.tag(Step.perfusion)
                }
                
                if shouldShowBoneInvolvement {
                    boneInvolvementStep.tag(Step.boneInvolvement)
                }
                
                comorbiditiesStep.tag(Step.comorbidities)
                redFlagsStep.tag(Step.redFlags)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNextView) {
            if isQuickScan {
                let payload = QuestionnairePayload(
                    etiology: etiology,
                    duration: duration,
                    tissue: tissue,
                    exposedBone: exposedBone,
                    infection: infection,
                    probeToBone: probeToBone,
                    moisture: moisture,
                    edge: edge,
                    abi: abi,
                    pulses: pulses,
                    comorbidities: comorbidities,
                    redFlags: redFlags
                )
                
                ReportView(
                    woundGroupId: woundGroupId,
                    patientId: patientId,
                    heroImage: measurementResult?.capturedImage,
                    isQuickScan: true,
                    quickScanPayload: payload,
                    measurementResult: measurementResult
                )
            } else {
                ReportView(
                    woundGroupId: woundGroupId,
                    patientId: patientId,
                    measurementResult: measurementResult
                )
            }
        }
        .onAppear(perform: loadDraft)
        .onChange(of: etiology) { autoSave() }
        .onChange(of: tissue) { autoSave() }
        .onChange(of: infection) { autoSave() }
    }
    
    // MARK: - Steps

    private var etiologyStep: some View {
        questionCard(title: LocalizedStrings.secEtiology) {
            IconChoiceGrid(selection: $etiology, options: etiologyOptions) {
                markComplete(.etiology)
                goNext()
            }
        }
    }

    private var durationStep: some View {
        questionCard(title: LocalizedStrings.secDuration) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.qDurationPrompt)
                    .font(.subheadline.weight(.semibold))
                
                SegmentedChips(selection: $duration, options: durationOptions) {
                    markComplete(.duration)
                    goNext()
                }
            }
        }
    }

    private var tissueStep: some View {
        questionCard(title: LocalizedStrings.secTissue) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.qTissuePrompt)
                    .font(.subheadline.weight(.semibold))
                
                SegmentedChips(selection: $tissue, options: tissueOptions) {
                    markComplete(.tissue)
                    goNext()
                }
            }
        }
    }

    private var infectionStep: some View {
        questionCard(title: LocalizedStrings.secInfection) {
            VStack(alignment: .leading, spacing: 16) {
                SeverityScale(selection: $infection, options: infectionOptions) {
                    showInfectionDetail = (infection != "none")
                    if !showInfectionDetail {
                        markComplete(.infection)
                        goNext()
                    }
                }

                if showInfectionDetail {
                    VStack(spacing: 10) {
                        Text(LocalizedStrings.infectionSignsHeader)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ToggleRow(title: LocalizedStrings.infectionSignPurulence, isOn: $hasPurulence)
                        ToggleRow(title: LocalizedStrings.infectionSignErythema2cm, isOn: $hasErythema)
                        ToggleRow(title: LocalizedStrings.infectionSignSystemicFever, isOn: $hasSystemicSigns)
                        
                        if !hasAnyInfectionSign {
                            Text(LocalizedStrings.infectionSelectAtLeastOne)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.08))
                    )
                }

                if infection == "systemic" {
                    GuardrailBadge(text: LocalizedStrings.infectionSystemicUrgentAdvice)
                }
            }
        }
    }

    private var moistureStep: some View {
        questionCard(title: LocalizedStrings.secMoisture) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.exudateLevelLabel)
                    .font(.subheadline.weight(.semibold))
                
                SegmentedChips(selection: $moisture, options: moistureOptions) {
                    markComplete(.moisture)
                    goNext()
                }
                
                if moisture == "high" {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(LocalizedStrings.highExudateHint)
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
                Text(LocalizedStrings.woundEdgeAppearanceLabel)
                    .font(.subheadline.weight(.semibold))
                
                TagChips(selection: $edge, options: edgeOptions) {
                    markComplete(.edge)
                    goNext()
                }
            }
        }
    }

    private var perfusionStep: some View {
        questionCard(title: LocalizedStrings.secPerfusion) {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStrings.perfusionABIHeading)
                    .font(.subheadline.weight(.semibold))
                SegmentedChips(selection: $abi, options: abiOptions)

                Divider().padding(.vertical, 4)

                Text(LocalizedStrings.perfusionPulsesLabel)
                    .font(.subheadline.weight(.semibold))
                SegmentedChips(selection: $pulses, options: pulsesOptions) {
                    markComplete(.perfusion)
                    goNext()
                }

                if abi == "lt0_5" {
                    GuardrailBadge(text: "⚠️ " + LocalizedStrings.perfusionSevereIschemiaGuardrail)
                }
            }
        }
    }
    
    
    private var boneInvolvementStep: some View {
        questionCard(title: LocalizedStrings.secBoneDepth) {
            VStack(alignment: .leading, spacing: 16) {
                ToggleRow(title: LocalizedStrings.boneVisibleToggle, isOn: $exposedBone)
                
                Divider().padding(.vertical, 4)
                
                ToggleRow(title: LocalizedStrings.probeToBoneToggle, isOn: $probeToBone)

                if exposedBone || probeToBone {
                    GuardrailBadge(text: "⚠️ " + LocalizedStrings.boneOsteoGuardrail)
                }
            }
        }
    }

    private var comorbiditiesStep: some View {
        questionCard(title: LocalizedStrings.secComorbidities) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.selectAllThatApplyOptional)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                MultiTagChips(selection: $comorbidities, options: comorbidityOptions)
            }
        }
    }

    private var redFlagsStep: some View {
        questionCard(title: LocalizedStrings.secRedFlags) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.anyConcerningSignsOptional)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                MultiTagChips(selection: $redFlags, options: redFlagOptions)

                if showsRedFlagsWarning {
                    GuardrailBadge(text: "⚠️ " + LocalizedStrings.redFlagsEscalateGuardrail)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            if !completedSteps.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if !etiology.isEmpty {
                            summaryChip(labelFor(etiology, in: etiologyOptions), icon: "checkmark.circle.fill")
                        }
                        if !tissue.isEmpty {
                            summaryChip(labelFor(tissue, in: tissueOptions), icon: "drop.fill")
                        }
                        if infection != "none" && !infection.isEmpty {
                            summaryChip(
                                labelFor(infection, in: infectionOptions),
                                icon: "exclamationmark.triangle.fill",
                                color: infection == "systemic" ? .red : .orange
                            )
                        }
                        if !moisture.isEmpty {
                            summaryChip(labelFor(moisture, in: moistureOptions), icon: "drop.fill")
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 32)
            }

            HStack(spacing: 10) {
                Button { goBack() } label: {
                    Label(LocalizedStrings.backAction, systemImage: "chevron.left")
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
                        Text(isLastStep ? LocalizedStrings.saveAndAnalyze : LocalizedStrings.nextAction)
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

    // MARK: - Navigation

    private var estimatedTotalSteps: Int {
        var total = 6 // etiology, duration, tissue, infection, moisture, edge
        
        if etiology == "arterial" || etiology == "diabeticFoot" {
            total += 1 // perfusion
        }
        
        if etiology == "diabeticFoot" || tissue == "necrosis" {
            total += 1 // bone
        }
        
        total += 2 // comorbidities, redflags
        
        return total
    }

    private var isLastStep: Bool {
        step == .redFlags
    }

    private var hasAnyInfectionSign: Bool {
        hasPurulence || hasErythema || hasSystemicSigns
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
        case .etiology:
            return .duration
            
        case .duration:
            return .tissue
            
        case .tissue:
            return .infection
            
        case .infection:
            return .moisture
            
        case .moisture:
            return .edge
            
        case .edge:
            if etiology == "venous" || etiology == "pressure" {
                return .comorbidities
            }
            return .perfusion
            
        case .perfusion:
            if etiology != "diabeticFoot" && tissue != "necrosis" {
                return .comorbidities
            }
            return .boneInvolvement
            
        case .boneInvolvement:
            return .comorbidities
            
        case .comorbidities:
            return .redFlags
            
        case .redFlags:
            return nil
        }
    }

    private func isStepAnswered(_ s: Step) -> Bool {
        switch s {
        case .etiology: return !etiology.isEmpty
        case .duration: return !duration.isEmpty
        case .tissue: return !tissue.isEmpty
        case .infection:
            if infection.isEmpty { return false }
            if infection != "none" && showInfectionDetail {
                return hasAnyInfectionSign
            }
            return true
        case .moisture: return !moisture.isEmpty
        case .edge: return !edge.isEmpty
        case .perfusion: return !abi.isEmpty && !pulses.isEmpty
        case .boneInvolvement: return true
        case .comorbidities: return true
        case .redFlags: return true
        }
    }

    private func markComplete(_ step: Step) {
        completedSteps.insert(step)
    }

    // MARK: - Logic

    private var showsRedFlagsWarning: Bool {
        redFlags.contains("spreadingErythema") ||
        redFlags.contains("crepitus") ||
        redFlags.contains("systemicUnwell")
    }

    private var urgentBannerText: String? {
        if infection == "systemic" || showsRedFlagsWarning {
            return LocalizedStrings.urgentBannerSystemic
        }
        if abi == "lt0_5" {
            return LocalizedStrings.urgentBannerSevereIschemia
        }
        return nil
    }

    private func save() {
        isSaving = true

        if isQuickScan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSaving = false
                clearDraft()
                showNextView = true
            }
            return
        }

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
                    clearDraft()
                    showNextView = true
                }
            }
        }
    }

    // MARK: - Auto-save

    private func autoSave() {
        let draft: [String: Any] = [
            "etiology": etiology,
            "duration": duration,
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
        
        if let timestamp = draft["timestamp"] as? TimeInterval {
            let age = Date().timeIntervalSince1970 - timestamp
            if age > 86400 {
                clearDraft()
                return
            }
        }
        
        etiology = draft["etiology"] as? String ?? ""
        duration = draft["duration"] as? String ?? ""
        tissue = draft["tissue"] as? String ?? ""
        infection = draft["infection"] as? String ?? ""
        moisture = draft["moisture"] as? String ?? ""
        edge = draft["edge"] as? String ?? ""
        abi = draft["abi"] as? String ?? ""
        pulses = draft["pulses"] as? String ?? ""
        exposedBone = draft["exposedBone"] as? Bool ?? false
        probeToBone = draft["probeToBone"] as? Bool ?? false
        comorbidities = Set(draft["comorbidities"] as? [String] ?? [])
        redFlags = Set(draft["redFlags"] as? [String] ?? [])
    }

    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: "questionnaire_draft_\(woundGroupId)")
    }

    // MARK: - Helpers

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

    private func labelFor(_ id: String, in options: [Option]) -> String {
        options.first(where: { $0.id == id })?.label ?? id.capitalized
    }
}

// MARK: - UI Components

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
            Text(LocalizedStrings.stepProgress(current: currentIndex, total: total, title: title))
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

// Input components

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
        .onChange(of: isOn) { _ in Haptics.light() }
    }
}

private struct Option: Identifiable, Hashable {
    let id: String
    let label: String
    let sfSymbol: String?
}

// Options

private var etiologyOptions: [Option] {
    [
        .init(id: "venous", label: LocalizedStrings.optEtiologyVenous, sfSymbol: "drop.fill"),
        .init(id: "arterial", label: LocalizedStrings.optEtiologyArterial, sfSymbol: "heart.fill"),
        .init(id: "diabeticFoot", label: LocalizedStrings.optEtiologyDiabetic, sfSymbol: "figure.walk"),
        .init(id: "pressure", label: LocalizedStrings.optEtiologyPressure, sfSymbol: "bed.double.fill"),
        .init(id: "trauma", label: LocalizedStrings.optEtiologyTrauma, sfSymbol: "bandage.fill"),
        .init(id: "surgical", label: LocalizedStrings.optEtiologySurgical, sfSymbol: "scissors")
    ]
}

private var durationOptions: [Option] {
    [
        .init(id: "lt4w", label: LocalizedStrings.optDurationLt4w, sfSymbol: nil),
        .init(id: "w4to12", label: LocalizedStrings.optDuration4to12, sfSymbol: nil),
        .init(id: "gt12w", label: LocalizedStrings.optDurationGt12w, sfSymbol: nil)
    ]
}

private var tissueOptions: [Option] {
    [
        .init(id: "granulation", label: LocalizedStrings.optTissueGranulation, sfSymbol: nil),
        .init(id: "slough", label: LocalizedStrings.optTissueSlough, sfSymbol: nil),
        .init(id: "necrosis", label: LocalizedStrings.optTissueNecrosis, sfSymbol: nil)
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
        .init(id: "lt0_5", label: LocalizedStrings.optAbiLT0_5, sfSymbol: nil)
    ]
}

private var pulsesOptions: [Option] {
    [
        .init(id: "yes", label: LocalizedStrings.optYes, sfSymbol: nil),
        .init(id: "no", label: LocalizedStrings.optNo, sfSymbol: nil)
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

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
