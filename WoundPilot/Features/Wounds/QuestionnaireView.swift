import SwiftUI
import UIKit
import FirebaseFirestore

// MARK: - Questionnaire (Wizard / one-step-at-a-time)

struct QuestionnaireView: View {
    let woundGroupId: String
    let patientId: String

    @ObservedObject var langManager = LocalizationManager.shared

    // Steps in order
    enum Step: Int, CaseIterable, Hashable {
        case etiology
        case duration
        case tissue
        case exposedBone
        case infection
        case probeToBone
        case moisture
        case edge
        case perfusionABI
        case pulses
        case comorbidities
        case redflags
        case review

        var title: String {
            switch self {
            case .etiology:      return LocalizedStrings.secEtiology
            case .duration:      return LocalizedStrings.secDuration
            case .tissue:        return LocalizedStrings.secTissue
            case .exposedBone:   return LocalizedStrings.rowExposedBone
            case .infection:     return LocalizedStrings.secInfection
            case .probeToBone:   return LocalizedStrings.rowProbeToBone
            case .moisture:      return LocalizedStrings.secMoisture
            case .edge:          return LocalizedStrings.secEdge
            case .perfusionABI:  return LocalizedStrings.secPerfusion + " (ABI)"
            case .pulses:        return LocalizedStrings.rowPulses
            case .comorbidities: return LocalizedStrings.secComorbidities
            case .redflags:      return LocalizedStrings.secRedFlags
            case .review:        return LocalizedStrings.t("Review", "Kontrola")
            }
        }
    }

    // Stored values (stable IDs for Firestore)
    @State private var etiology: String = "unknown"
    @State private var duration: String = "unknown"

    @State private var tissue: String = "unknown"
    @State private var exposedBone = false

    @State private var infection: String = "unknown"   // require explicit answer
    @State private var probeToBone = false

    @State private var moisture: String = "unknown"
    @State private var edge: String = "unknown"

    @State private var abi: String = "unknown"
    @State private var pulses: String = "unknown" // yes / no / unknown

    @State private var comorbidities: Set<String> = []
    @State private var redFlags: Set<String> = []

    // UX
    @State private var isSaving = false
    @State private var showNextView = false
    @State private var errorMessage: String?
    @State private var step: Step = .etiology

    var body: some View {
        VStack(spacing: 0) {

            // Top progress & urgent banner
            VStack(spacing: 10) {
                StepIndicator(currentIndex: currentIndex, total: Step.allCases.count, title: step.title)
                    .padding(.top, 8)

                if let urgent = urgentBannerText {
                    Banner(text: urgent, style: .danger)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 8)

            // Paged steps
            TabView(selection: $step) {
                // 1 Etiology
                questionCard(title: LocalizedStrings.secEtiology) {
                    IconChoiceGrid(selection: $etiology, options: etiologyOptions) {
                        goNext()
                    }
                }
                .tag(Step.etiology)

                // 2 Duration
                questionCard(title: LocalizedStrings.secDuration) {
                    SegmentedChips(selection: $duration, options: durationOptions) {
                        goNext()
                    }
                }
                .tag(Step.duration)

                // 3 Tissue
                questionCard(title: LocalizedStrings.secTissue) {
                    SegmentedChips(selection: $tissue, options: tissueOptions) {
                        goNext()
                    }
                }
                .tag(Step.tissue)

                // 4 Exposed bone
                questionCard(title: LocalizedStrings.rowExposedBone) {
                    ToggleRow(title: LocalizedStrings.rowExposedBone, isOn: $exposedBone)
                        .padding(.top, 2)
                }
                .tag(Step.exposedBone)

                // 5 Infection severity
                questionCard(title: LocalizedStrings.secInfection) {
                    SeverityScale(selection: $infection, options: infectionOptions) {
                        goNext()
                    }
                    if infection == "systemic" {
                        GuardrailBadge(text: LocalizedStrings.badgeSystemicInfectionUrgent)
                    }
                }
                .tag(Step.infection)

                // 6 Probe to bone
                questionCard(title: LocalizedStrings.rowProbeToBone) {
                    ToggleRow(title: LocalizedStrings.rowProbeToBone, isOn: $probeToBone)
                    if probeToBone {
                        GuardrailBadge(text: LocalizedStrings.badgeProbeToBone)
                    }
                }
                .tag(Step.probeToBone)

                // 7 Moisture
                questionCard(title: LocalizedStrings.secMoisture) {
                    SegmentedChips(selection: $moisture, options: moistureOptions) {
                        goNext()
                    }
                }
                .tag(Step.moisture)

                // 8 Edge
                questionCard(title: LocalizedStrings.secEdge) {
                    TagChips(selection: $edge, options: edgeOptions) {
                        goNext()
                    }
                }
                .tag(Step.edge)

                // 9 ABI
                questionCard(title: LocalizedStrings.secPerfusion + " (ABI)") {
                    SegmentedChips(selection: $abi, options: abiOptions) {
                        goNext()
                    }
                    if abi == "lt0_5" {
                        GuardrailBadge(text: LocalizedStrings.badgeCompressionContraindicated)
                    }
                }
                .tag(Step.perfusionABI)

                // 10 Pulses
                questionCard(title: LocalizedStrings.rowPulses) {
                    SegmentedChips(selection: $pulses, options: pulsesOptions) {
                        goNext()
                    }
                }
                .tag(Step.pulses)

                // 11 Comorbidities
                questionCard(title: LocalizedStrings.secComorbidities) {
                    MultiTagChips(selection: $comorbidities, options: comorbidityOptions)
                }
                .tag(Step.comorbidities)

                // 12 Red flags
                questionCard(title: LocalizedStrings.secRedFlags) {
                    MultiTagChips(selection: $redFlags, options: redFlagOptions)
                    if showsRedFlagsWarning {
                        GuardrailBadge(text: LocalizedStrings.badgeRedFlagsEscalate)
                    }
                }
                .tag(Step.redflags)

                // 13 Review
                reviewCard()
                    .tag(Step.review)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Footer (Back / Next or Save)
            footer
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNextView) {
            AIAnalysisView(woundGroupId: woundGroupId, patientId: patientId)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Button(action: goBack) {
                Label(LocalizedStrings.t("Back", "Späť"), systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .disabled(step == .etiology)

            if step == .review {
                Button(action: save) {
                    if isSaving {
                        ProgressView().frame(maxWidth: .infinity).padding(.vertical, 12)
                    } else {
                        Text(LocalizedStrings.t("Save & Analyze", "Uložiť a analyzovať"))
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.primaryBlue)

            } else {
                Button(action: goNext) {
                    Text(LocalizedStrings.t("Next", "Ďalej"))
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.primaryBlue)
                .disabled(!isStepAnswered(step))
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.regularMaterial)
    }

    // MARK: - Step helpers

    private var currentIndex: Int {
        Step.allCases.firstIndex(of: step)! + 1
    }

    private func goNext() {
        Haptics.light()
        if let i = Step.allCases.firstIndex(of: step),
           i + 1 < Step.allCases.count {
            withAnimation(.easeInOut(duration: 0.25)) {
                step = Step.allCases[i + 1]
            }
        }
    }

    private func goBack() {
        Haptics.light()
        if let i = Step.allCases.firstIndex(of: step),
           i - 1 >= 0 {
            withAnimation(.easeInOut(duration: 0.25)) {
                step = Step.allCases[i - 1]
            }
        }
    }

    private func isStepAnswered(_ s: Step) -> Bool {
        switch s {
        case .etiology:      return etiology != "unknown"
        case .duration:      return duration != "unknown"
        case .tissue:        return tissue != "unknown"
        case .exposedBone:   return true          // toggle is always a valid answer
        case .infection:     return infection != "unknown"
        case .probeToBone:   return true
        case .moisture:      return moisture != "unknown"
        case .edge:          return edge != "unknown"
        case .perfusionABI:  return abi != "unknown"
        case .pulses:        return pulses != "unknown"
        case .comorbidities: return true
        case .redflags:      return true
        case .review:        return true
        }
    }

    // MARK: - Logic (banners & save)

    private var showsRedFlagsWarning: Bool {
        redFlags.contains("spreadingErythema")
        || redFlags.contains("crepitus")
        || redFlags.contains("systemicUnwell")
    }

    private var urgentBannerText: String? {
        if infection == "systemic" || showsRedFlagsWarning { return LocalizedStrings.bannerUrgentAssessment }
        if abi == "lt0_5" { return LocalizedStrings.bannerSevereIschaemia }
        return nil
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let ref = db.collection("woundGroups").document(woundGroupId)

        let payload: [String: Any] = [
            "etiology": etiology,
            "duration": duration,
            "tissue": tissue,
            "exposedBone": exposedBone,
            "infection": infection,
            "probeToBone": probeToBone,
            "moisture": moisture,
            "edge": edge,
            "abi": abi,
            "pulses": pulses,
            "comorbidities": Array(comorbidities),
            "redFlags": Array(redFlags),
            "completedAt": FieldValue.serverTimestamp(),
            "patientId": patientId
        ]

        ref.setData(["questionnaire": payload], merge: true) { error in
            DispatchQueue.main.async {
                isSaving = false
                if let error = error {
                    errorMessage = LocalizedStrings.failedToSave(error.localizedDescription)
                } else {
                    showNextView = true
                }
            }
        }
    }

    // MARK: - Cards

    private func questionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title3.bold()).padding(.horizontal)

            GroupCard { content() }
                .padding(.horizontal)

            if let err = errorMessage {
                Text(err).font(.footnote).foregroundColor(.red).padding(.horizontal)
            }

            Spacer(minLength: 24)
        }
    }

    private func reviewCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStrings.t("Review", "Kontrola"))
                .font(.title3.bold())
                .padding(.horizontal)

            GroupCard {
                KeyValueRow(k: LocalizedStrings.secEtiology, v: labelFor(etiology, in: etiologyOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.secDuration, v: labelFor(duration, in: durationOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.secTissue, v: labelFor(tissue, in: tissueOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.secInfection, v: labelFor(infection, in: infectionOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.secMoisture, v: labelFor(moisture, in: moistureOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.secEdge, v: labelFor(edge, in: edgeOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: "ABI", v: labelFor(abi, in: abiOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.rowPulses, v: labelFor(pulses, in: pulsesOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.rowExposedBone, v: exposedBone ? LocalizedStrings.optYes : LocalizedStrings.optNo)
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.rowProbeToBone, v: probeToBone ? LocalizedStrings.optYes : LocalizedStrings.optNo)
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.secComorbidities, v: listLabels(for: comorbidities, options: comorbidityOptions))
                Divider().opacity(0.08)
                KeyValueRow(k: LocalizedStrings.secRedFlags, v: listLabels(for: redFlags, options: redFlagOptions))
            }
            .padding(.horizontal)

            if let urgent = urgentBannerText {
                Banner(text: urgent, style: .danger)
                    .padding(.horizontal)
            }

            Spacer(minLength: 24)
        }
    }

    private func labelFor(_ id: String, in options: [Option]) -> String {
        options.first(where: { $0.id == id })?.label ?? LocalizedStrings.optUnknown
    }
    private func listLabels(for set: Set<String>, options: [Option]) -> String {
        let dict = Dictionary(uniqueKeysWithValues: options.map { ($0.id, $0.label) })
        let labels = set.compactMap { dict[$0] }
        return labels.isEmpty ? "—" : labels.joined(separator: ", ")
    }
}

// MARK: - Small UI Bits

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
            Text("\(LocalizedStrings.t("Step", "Krok")) \(currentIndex) \(LocalizedStrings.t("of", "z")) \(total)  •  \(title)")
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
        let bg: Color = {
            switch style {
            case .danger: return Color.red.opacity(0.12)
            case .warning: return Color.orange.opacity(0.12)
            case .info: return Color.accentColor.opacity(0.12)
            }
        }()
        let fg: Color = {
            switch style {
            case .danger: return .red
            case .warning: return .orange
            case .info: return .accentColor
            }
        }()
        return HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text).font(.footnote.weight(.semibold))
            Spacer()
        }
        .foregroundColor(fg)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(bg))
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

private struct KeyValueRow: View {
    let k: String
    let v: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(k).font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
            Spacer(minLength: 16)
            Text(v).font(.body)
        }
    }
}

// Fixed GroupCard: store built view (avoid escaping-closure error)
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

private func SectionHeader(_ title: String) -> some View {
    Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
}

// 1) Icon cards grid (Etiology)
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
                    onSelect()
                } label: {
                    VStack(spacing: 8) {
                        if let s = opt.sfSymbol {
                            Image(systemName: s)
                                .font(.system(size: 22, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(selected ? .white : .primary)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                                )
                        }
                        Text(opt.label)
                            .font(.callout.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 76)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selected ? Color.primaryBlue : Color(.systemGray6))
                    )
                    .foregroundColor(selected ? .white : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selected ? Color.primaryBlue.opacity(0.9) : Color.black.opacity(0.04), lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// 2) Segmented chips (single select) — adaptive grid
private struct SegmentedChips: View {
    var title: String? = nil
    @Binding var selection: String
    let options: [Option]
    var onSelect: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dts
    private var minChip: CGFloat { dts >= .accessibility2 ? 120 : 110 }
    private var cols: [GridItem] { [GridItem(.adaptive(minimum: minChip), spacing: 8)] }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title { SectionHeader(title) }
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(options) { opt in
                    let selected = selection == opt.id
                    Button {
                        selection = opt.id
                        onSelect()
                    } label: {
                        Text(opt.label)
                            .font(.callout.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(selected ? Color.primaryBlue : Color(.systemGray6))
                            .foregroundColor(selected ? .white : .primary)
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// 3) Severity bar (single select)
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
                    onSelect()
                } label: {
                    Text(opt.label)
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(color(for: opt.id, selected: selected)))
                        .foregroundColor(selected ? .white : .primary)
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40)
    }

    private func color(for id: String, selected: Bool) -> Color {
        switch id {
        case "none":     return selected ? .green : .green.opacity(0.15)
        case "local":    return selected ? .orange : .orange.opacity(0.18)
        case "systemic": return selected ? .red : .red.opacity(0.18)
        default:         return Color(.systemGray5)
        }
    }
}

// 4) Tag chips (single select)
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
                    onSelect()
                } label: {
                    HStack(spacing: 6) {
                        if selected { Image(systemName: "checkmark.circle.fill").imageScale(.small) }
                        Text(opt.label).font(.callout.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.9)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(RoundedRectangle(cornerRadius: 999).fill(selected ? Color.primaryBlue : Color(.systemGray6)))
                    .foregroundColor(selected ? .white : .primary)
                    .contentShape(RoundedRectangle(cornerRadius: 999))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// 5) Multi-select tag chips
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
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isSel ? "checkmark.circle.fill" : "circle").imageScale(.small)
                        Text(opt.label).font(.callout.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.9)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(RoundedRectangle(cornerRadius: 999).fill(isSel ? Color.primaryBlue : Color(.systemGray6)))
                    .foregroundColor(isSel ? .white : .primary)
                    .contentShape(RoundedRectangle(cornerRadius: 999))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Toggle row
private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).font(.subheadline).foregroundColor(.primary)
        }
    }
}

// Shared models/options
private struct Option: Identifiable, Hashable {
    let id: String
    let label: String
    let sfSymbol: String?
}

// Options
private var etiologyOptions: [Option] {
    [
        .init(id: "venous",       label: LocalizedStrings.optEtiologyVenous,   sfSymbol: "drop.fill"),
        .init(id: "arterial",     label: LocalizedStrings.optEtiologyArterial, sfSymbol: "heart.fill"),
        .init(id: "diabeticFoot", label: LocalizedStrings.optEtiologyDiabetic, sfSymbol: "figure.walk"),
        .init(id: "pressure",     label: LocalizedStrings.optEtiologyPressure, sfSymbol: "bed.double.fill"),
        .init(id: "trauma",       label: LocalizedStrings.optEtiologyTrauma,   sfSymbol: "bandage.fill"),
        .init(id: "surgical",     label: LocalizedStrings.optEtiologySurgical, sfSymbol: "scissors"),
        .init(id: "unknown",      label: LocalizedStrings.optUnknown,          sfSymbol: "questionmark.circle")
    ]
}
private var durationOptions: [Option] {
    [
        .init(id: "lt4w",   label: LocalizedStrings.optDurationLt4w,  sfSymbol: nil),
        .init(id: "w4to12", label: LocalizedStrings.optDuration4to12, sfSymbol: nil),
        .init(id: "gt12w",  label: LocalizedStrings.optDurationGt12w, sfSymbol: nil),
        .init(id: "unknown",label: LocalizedStrings.optUnknown,       sfSymbol: nil)
    ]
}
private var tissueOptions: [Option] {
    [
        .init(id: "granulation", label: LocalizedStrings.optTissueGranulation, sfSymbol: nil),
        .init(id: "slough",      label: LocalizedStrings.optTissueSlough,      sfSymbol: nil),
        .init(id: "necrosis",    label: LocalizedStrings.optTissueNecrosis,    sfSymbol: nil),
        .init(id: "unknown",     label: LocalizedStrings.optUnknown,           sfSymbol: nil)
    ]
}
private var infectionOptions: [Option] {
    [
        .init(id: "none",     label: LocalizedStrings.optInfectionNone,     sfSymbol: nil),
        .init(id: "local",    label: LocalizedStrings.optInfectionLocal,    sfSymbol: nil),
        .init(id: "systemic", label: LocalizedStrings.optInfectionSystemic, sfSymbol: nil)
    ]
}
private var moistureOptions: [Option] {
    [
        .init(id: "dry",      label: LocalizedStrings.optMoistureDry,      sfSymbol: nil),
        .init(id: "low",      label: LocalizedStrings.optMoistureLow,      sfSymbol: nil),
        .init(id: "moderate", label: LocalizedStrings.optMoistureModerate, sfSymbol: nil),
        .init(id: "high",     label: LocalizedStrings.optMoistureHigh,     sfSymbol: nil),
        .init(id: "unknown",  label: LocalizedStrings.optUnknown,          sfSymbol: nil)
    ]
}
private var edgeOptions: [Option] {
    [
        .init(id: "attached",   label: LocalizedStrings.optEdgeAttached,   sfSymbol: nil),
        .init(id: "rolled",     label: LocalizedStrings.optEdgeRolled,     sfSymbol: nil),
        .init(id: "undermined", label: LocalizedStrings.optEdgeUndermined, sfSymbol: nil),
        .init(id: "unknown",    label: LocalizedStrings.optUnknown,        sfSymbol: nil)
    ]
}
private var abiOptions: [Option] {
    [
        .init(id: "ge0_8",      label: LocalizedStrings.optAbiGE0_8,      sfSymbol: nil),
        .init(id: "p0_5to0_79", label: LocalizedStrings.optAbi0_5to0_79,  sfSymbol: nil),
        .init(id: "lt0_5",      label: LocalizedStrings.optAbiLT0_5,      sfSymbol: nil),
        .init(id: "unknown",    label: LocalizedStrings.optUnknown,       sfSymbol: nil)
    ]
}
private var pulsesOptions: [Option] {
    [
        .init(id: "yes",     label: LocalizedStrings.optYes,     sfSymbol: nil),
        .init(id: "no",      label: LocalizedStrings.optNo,      sfSymbol: nil),
        .init(id: "unknown", label: LocalizedStrings.optUnknown, sfSymbol: nil)
    ]
}
private var comorbidityOptions: [Option] {
    [
        .init(id: "diabetes",        label: LocalizedStrings.optCoDiabetes,   sfSymbol: nil),
        .init(id: "pad",             label: LocalizedStrings.optCoPAD,        sfSymbol: nil),
        .init(id: "neuropathy",      label: LocalizedStrings.optCoNeuropathy, sfSymbol: nil),
        .init(id: "immunosuppressed",label: LocalizedStrings.optCoImmuno,     sfSymbol: nil),
        .init(id: "anticoagulants",  label: LocalizedStrings.optCoAnticoag,   sfSymbol: nil)
    ]
}
private var redFlagOptions: [Option] {
    [
        .init(id: "spreadingErythema", label: LocalizedStrings.optRFSpread,   sfSymbol: nil),
        .init(id: "severePain",        label: LocalizedStrings.optRFPain,     sfSymbol: nil),
        .init(id: "crepitus",          label: LocalizedStrings.optRFCrepitus, sfSymbol: nil),
        .init(id: "systemicUnwell",    label: LocalizedStrings.optRFSystemic, sfSymbol: nil)
    ]
}

