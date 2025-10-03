import SwiftUI
import FirebaseFirestore

struct BodyLocalizationView: View {
    let patient: Patient?
    let woundGroupId: String?
    let woundGroupName: String?

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var selectedRegion: String?
    @State private var selectedSide: Side? = nil
    @State private var selectedSubsite: String? = nil

    // precise foot detail (e.g., toe_5, heel_medial, forefoot)
    @State private var footDetail: String? = nil
    @State private var showFootDetailSheet = false

    @State private var goNext = false
    @State private var isSavingMeta = false

    enum Side: String, CaseIterable, Identifiable {
        case left, right, midline
        var id: String { rawValue }
        var title: String {
            switch self {
            case .left: return LocalizedStrings.t("Left", "Ľavá")
            case .right: return LocalizedStrings.t("Right", "Pravá")
            case .midline: return LocalizedStrings.t("Midline", "Stred")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Body map
                WoundLocationPickerView(
                    selectedRegion: $selectedRegion,
                    onConfirm: { region in
                        selectedRegion = region

                        // Reset context when switching regions
                        selectedSide = nil
                        selectedSubsite = nil
                        footDetail = nil

                        // 1) Sides only where useful (limbs/hands/feet), NOT abdomen quadrants
                        if regionSupportsSide(region) {
                            selectedSide = defaultSide(for: region)
                        }

                        // 2) Subsites only for arms/hands and feet (not abdomen)
                        if needsGenericSubsites(region),
                           let first = subsites(for: region).first {
                            selectedSubsite = first
                        }

                        // 3) Foot deep detail (toes/heel/zones)
                        if isFootRegion(region) {
                            footDetail = "forefoot" // sensible default
                            showFootDetailSheet = true
                        }
                    }
                )

                // Side (left/right/midline) — only when useful
                if let region = selectedRegion, regionSupportsSide(region) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStrings.t("Side", "Strana"))
                            .font(.subheadline.weight(.semibold))

                        Picker("", selection: Binding(
                            get: { selectedSide ?? .right },
                            set: { selectedSide = $0 }
                        )) {
                            ForEach(Side.allCases) { side in
                                Text(side.title).tag(side)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                }

                // Generic subsites — only for arms/hands/feet (not abdomen quadrants, chest, etc.)
                if let region = selectedRegion, needsGenericSubsites(region) {
                    let options = subsites(for: region)
                    if !options.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStrings.t("Sub-site", "Podlokalita"))
                                .font(.subheadline.weight(.semibold))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(options, id: \.self) { opt in
                                        Button {
                                            selectedSubsite = opt
                                        } label: {
                                            Text(localizeSubsite(opt))
                                                .font(.footnote.weight(.semibold))
                                                .lineLimit(1)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill((selectedSubsite == opt) ? Color.accentColor.opacity(0.18)
                                                                                       : Color(.systemGray6))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke((selectedSubsite == opt) ? Color.accentColor
                                                                                         : Color.black.opacity(0.08), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Foot detail chip + edit button (only for foot regions)
                if let region = selectedRegion, isFootRegion(region), let detail = footDetail {
                    HStack(spacing: 10) {
                        Text(LocalizedStrings.t("Foot detail", "Detail chodidla"))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Button(localizeFootDetail(detail)) {
                            showFootDetailSheet = true
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Capsule().fill(Color(.systemGray6)))
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 8)
        }
        .navigationTitle(LocalizedStrings.selectWoundLocationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))

        // Confirm bar
        .safeAreaInset(edge: .bottom) {
            if selectedRegion != nil {
                VStack {
                    Button { confirmAndProceed() } label: {
                        HStack(spacing: 8) {
                            if isSavingMeta { ProgressView().tint(.white) }
                            Text(LocalizedStrings.confirm).bold()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
            }
        }

        // Next screen
        .navigationDestination(isPresented: $goNext) {
            WoundImageSourceView(
                selectedPatient: patient,
                preselectedWoundGroupId: woundGroupId,
                preselectedLocation: composedLocationString()
            )
        }

        // Foot detail sheet
        .sheet(isPresented: $showFootDetailSheet) {
            FootDetailSheet(
                selection: $footDetail,
                onDone: { showFootDetailSheet = false }
            )
        }
    }

    // MARK: - Save + helpers

    private func confirmAndProceed() {
        guard let region = selectedRegion else { return }
        if let woundGroupId {
            isSavingMeta = true
            var payload: [String: Any] = [
                "bodyRegionCode": region,
                "side": selectedSide?.rawValue ?? NSNull(),
                "subsite": selectedSubsite ?? NSNull()
            ]
            if let fd = footDetail { payload["footDetail"] = fd }
            Firestore.firestore().collection("woundGroups").document(woundGroupId)
                .setData(payload, merge: true) { _ in
                    isSavingMeta = false
                    goNext = true
                }
        } else {
            goNext = true
        }
    }

    private func composedLocationString() -> String? {
        guard let region = selectedRegion else { return nil }
        var chunks = [region]
        if let s  = selectedSide?.rawValue { chunks.append(s) }
        if let ss = selectedSubsite       { chunks.append(ss) }
        if let fd = footDetail            { chunks.append(fd) }
        return chunks.joined(separator: "|")
    }

    // MARK: - Region rules (HYBRID)

    private func isFootRegion(_ code: String) -> Bool {
        code.contains("foot") || code.contains("toes") || code.contains("heel")
    }

    private func isArmHandRegion(_ code: String) -> Bool {
        ["shoulder","elbow","forearm","hand","triceps","scapula"].contains { code.contains($0) }
    }

    private func isDetailedByPoints(_ code: String) -> Bool {
        code.hasPrefix("abdomen_") || code.contains("chest")
    }

    private func regionSupportsSide(_ code: String) -> Bool {
        if isDetailedByPoints(code) { return false }
        return isFootRegion(code) || isArmHandRegion(code) ||
               code.contains("thigh") || code.contains("shin") || code.contains("calf") || code.contains("knee")
    }

    private func needsGenericSubsites(_ code: String) -> Bool {
        if isDetailedByPoints(code) { return false }
        return isFootRegion(code) || isArmHandRegion(code)
    }

    private func defaultSide(for code: String) -> Side {
        code.contains("midline") ? .midline : .right
    }

    private func subsites(for code: String) -> [String] {
        if isFootRegion(code)       { return ["plantar","dorsal","lateral","medial"] }
        if code.contains("hand")    { return ["palmar","dorsal","thenar","hypothenar"] }
        if code.contains("forearm") { return ["anterior","posterior","lateral","medial"] }
        if code.contains("elbow")   { return ["olecranon","medial","lateral"] }
        if code.contains("shoulder"){ return ["acromial","deltoid","scapular"] }
        if code.contains("scapula") { return ["superior","inferior","medial","lateral"] }
        if code.contains("knee")    { return ["anterior","posterior","lateral","medial"] }
        if code.contains("shin")    { return ["anterior","medial","lateral"] }
        if code.contains("calf")    { return ["posterior","lateral","medial"] }
        if code.contains("thigh")   { return ["anterior","posterior","lateral","medial"] }
        return []
    }

    private func localizeSubsite(_ code: String) -> String {
        switch code {
        case "plantar": return LocalizedStrings.t("Plantar", "Plantárna")
        case "dorsal": return LocalizedStrings.t("Dorsal", "Dorzálna")
        case "anterior": return LocalizedStrings.t("Anterior", "Predná")
        case "posterior": return LocalizedStrings.t("Posterior", "Zadná")
        case "lateral": return LocalizedStrings.t("Lateral", "Laterálna")
        case "medial": return LocalizedStrings.t("Medial", "Mediálna")
        case "palmar": return LocalizedStrings.t("Palmar", "Palmárna")
        case "thenar": return "Thenar"
        case "hypothenar": return "Hypothenar"
        case "olecranon": return "Olecranon"
        case "acromial": return "Acromial"
        case "deltoid": return "Deltoid"
        case "scapular": return "Scapular"
        case "superior": return LocalizedStrings.t("Superior", "Horná")
        case "inferior": return LocalizedStrings.t("Inferior", "Dolná")
        default: return code.capitalized
        }
    }

    private func localizeFootDetail(_ code: String) -> String {
        switch code {
        case "toe_1": return LocalizedStrings.t("Hallux", "Palec")
        case "toe_2": return LocalizedStrings.t("2nd toe", "2. prst")
        case "toe_3": return LocalizedStrings.t("3rd toe", "3. prst")
        case "toe_4": return LocalizedStrings.t("4th toe", "4. prst")
        case "toe_5": return LocalizedStrings.t("5th toe (pinky)", "5. prst (malík)")
        case "heel_central": return LocalizedStrings.t("Heel (central)", "Päta (stred)")
        case "heel_medial":  return LocalizedStrings.t("Heel (medial)", "Päta (mediálna)")
        case "heel_lateral": return LocalizedStrings.t("Heel (lateral)", "Päta (laterálna)")
        case "forefoot":     return LocalizedStrings.t("Forefoot", "Predonožie")
        case "midfoot":      return LocalizedStrings.t("Midfoot", "Strednožie")
        case "hindfoot":     return LocalizedStrings.t("Hindfoot", "Zadnožie")
        case "plantar_arch": return LocalizedStrings.t("Plantar arch", "Plantárna klenba")
        default: return code.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// MARK: - Foot detail sheet (now visible to other files)
struct FootDetailSheet: View {
    @Binding var selection: String?
    var onDone: () -> Void

    struct ChipItem: Identifiable {
        let id: String   // code
        let label: String
    }

    private let toeItems: [ChipItem] = [
        .init(id: "toe_1", label: "Hallux"),
        .init(id: "toe_2", label: "2nd toe"),
        .init(id: "toe_3", label: "3rd toe"),
        .init(id: "toe_4", label: "4th toe"),
        .init(id: "toe_5", label: "5th toe"),
    ]

    private let heelItems: [ChipItem] = [
        .init(id: "heel_central", label: "Heel (central)"),
        .init(id: "heel_medial",  label: "Heel (medial)"),
        .init(id: "heel_lateral", label: "Heel (lateral)"),
    ]

    private let zones: [ChipItem] = [
        .init(id: "forefoot",     label: "Forefoot"),
        .init(id: "midfoot",      label: "Midfoot"),
        .init(id: "hindfoot",     label: "Hindfoot"),
        .init(id: "plantar_arch", label: "Plantar arch"),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Toes")  { flow(toeItems)  }
                Section("Heel")  { flow(heelItems) }
                Section("Zones") { flow(zones)     }
            }
            .navigationTitle("Foot detail")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
    }

    private func flow(_ items: [ChipItem]) -> some View {
        FlowLayout(items) { item in
            Button {
                selection = item.id
            } label: {
                Text(item.label)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(selection == item.id ? Color.accentColor.opacity(0.18)
                                                       : Color(.systemGray6))
                    )
                    .overlay(
                        Capsule()
                            .stroke(selection == item.id ? Color.accentColor
                                                         : Color.black.opacity(0.08), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tiny flow layout for chips (shared)
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            generateContent(in: geo.size)
        }
        .frame(minHeight: 44) // grows with content
    }

    private func generateContent(in size: CGSize) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(data) { item in
                content(item)
                    .alignmentGuide(.leading) { d in
                        let nextX = x + d.width
                        let res = (nextX > size.width) ? 0 : x
                        if nextX > size.width {
                            x = d.width
                            y -= d.height
                        } else {
                            x = nextX
                        }
                        return res
                    }
                    .alignmentGuide(.top) { _ in y }
            }
        }
    }
}
