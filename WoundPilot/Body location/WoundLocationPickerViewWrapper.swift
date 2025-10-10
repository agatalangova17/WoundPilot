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
    @State private var footDetail: String? = nil
    @State private var handDetail: String? = nil
    
    @State private var showFootDetailSheet = false
    @State private var showHandDetailSheet = false
    @State private var goToMeasurement = false
    @State private var isSavingMeta = false

    enum Side: String, CaseIterable, Identifiable {
        case left, right, midline
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                bodyMapSection
                subsiteSection
                footDetailSection
                handDetailSection
                Spacer(minLength: 24)
            }
            .padding(.top, 8)
        }
        .navigationTitle(LocalizedStrings.selectWoundLocationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .safeAreaInset(edge: .bottom) {
            confirmButton
        }
        .navigationDestination(isPresented: $goToMeasurement) {
            MeasurementFlowWrapper(
                patient: patient,
                woundGroupId: woundGroupId,
                locationString: composedLocationString(),
                bodyRegionCode: selectedRegion  
            )
        }
        .sheet(isPresented: $showFootDetailSheet) {
            FootDetailSheet(selection: $footDetail, onDone: { showFootDetailSheet = false })
        }
        .sheet(isPresented: $showHandDetailSheet) {
            HandDetailSheet(selection: $handDetail, onDone: { showHandDetailSheet = false })
        }
    }
    
    // MARK: - Sections
    
    private var bodyMapSection: some View {
        WoundLocationPickerView(
            selectedRegion: $selectedRegion,
            onConfirm: handleRegionSelected
        )
    }
    
    @ViewBuilder
    private var subsiteSection: some View {
        if let region = selectedRegion, regionNeedsSubsite(region) {
            let options = subsites(for: region)
            if !options.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.subsiteLabel)
                        .font(.subheadline.weight(.semibold))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(options, id: \.self) { opt in
                                subsiteChip(opt)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func subsiteChip(_ opt: String) -> some View {
        Button {
            selectedSubsite = opt
        } label: {
            Text(LocalizedStrings.subsiteName(opt))
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill((selectedSubsite == opt) ? Color.accentColor.opacity(0.18) : Color(.systemGray6))
                )
                .overlay(
                    Capsule()
                        .stroke((selectedSubsite == opt) ? Color.accentColor : Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var footDetailSection: some View {
        if let region = selectedRegion, isFootRegion(region), let detail = footDetail {
            detailChipRow(
                title: LocalizedStrings.footDetailTitle,
                value: LocalizedStrings.footDetailLabel(detail),
                action: { showFootDetailSheet = true }
            )
        }
    }
    
    @ViewBuilder
    private var handDetailSection: some View {
        if let region = selectedRegion, isHandRegion(region), let detail = handDetail {
            detailChipRow(
                title: LocalizedStrings.handDetailTitle,
                value: LocalizedStrings.handDetailLabel(detail),
                action: { showHandDetailSheet = true }
            )
        }
    }
    
    private func detailChipRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button(value) { action() }
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(.systemGray6)))
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var confirmButton: some View {
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

    // MARK: - Actions
    
    private func handleRegionSelected(_ region: String) {
        selectedRegion = region
        
        
        selectedSubsite = nil
        footDetail = nil
        handDetail = nil
        
        
        selectedSide = extractSide(from: region)
        
        if regionNeedsSubsite(region) {
            selectedSubsite = subsites(for: region).first
        }
        
        if isFootRegion(region) {
            footDetail = "forefoot"
            showFootDetailSheet = true
        }
        
        if isHandRegion(region) {
            handDetail = "palm"
            showHandDetailSheet = true
        }
    }

    private func confirmAndProceed() {
        guard let region = selectedRegion else { return }
        
        if let woundGroupId {
            isSavingMeta = true
            saveLocationMetadata(woundGroupId: woundGroupId, region: region)
        } else {
            goToMeasurement = true
        }
    }
    
    private func saveLocationMetadata(woundGroupId: String, region: String) {
        var payload: [String: Any] = [
            "bodyRegionCode": region,
            "side": selectedSide?.rawValue ?? NSNull(),
            "subsite": selectedSubsite ?? NSNull()
        ]
        if let fd = footDetail { payload["footDetail"] = fd }
        if let hd = handDetail { payload["handDetail"] = hd }
        
        Firestore.firestore()
            .collection("woundGroups")
            .document(woundGroupId)
            .setData(payload, merge: true) { _ in
                isSavingMeta = false
                goToMeasurement = true
            }
    }
    
    private func composedLocationString() -> String? {
        guard let region = selectedRegion else { return nil }
        var chunks = [region]
        if let s = selectedSide?.rawValue { chunks.append(s) }
        if let ss = selectedSubsite { chunks.append(ss) }
        if let fd = footDetail { chunks.append(fd) }
        if let hd = handDetail { chunks.append(hd) }
        return chunks.joined(separator: "|")
    }

    // MARK: - Region Classification
    
    private func isFootRegion(_ code: String) -> Bool {
        code.contains("foot") || code.contains("toes") || code.contains("heel")
    }
    
    private func isHandRegion(_ code: String) -> Bool {
        code.contains("hand")
    }
    
    private func isArmRegion(_ code: String) -> Bool {
        ["shoulder","elbow","forearm","triceps","scapula"].contains { code.contains($0) }
    }
    
    private func regionNeedsSubsite(_ code: String) -> Bool {
        if code.hasPrefix("abdomen_") || code.contains("chest") { return false }
        return isFootRegion(code) || isHandRegion(code) || isArmRegion(code) ||
               code.contains("thigh") || code.contains("shin") || code.contains("calf") || code.contains("knee")
    }
    
    private func extractSide(from code: String) -> Side? {
        if code.contains("left") { return .left }
        if code.contains("right") { return .right }
        if code.contains("midline") { return .midline }
        return nil
    }
    
    private func subsites(for code: String) -> [String] {
        if isFootRegion(code) { return ["plantar","dorsal","lateral","medial"] }
        if code.contains("hand") { return ["palmar","dorsal","thenar","hypothenar"] }
        if code.contains("forearm") { return ["anterior","posterior","lateral","medial"] }
        if code.contains("elbow") { return ["olecranon","medial","lateral"] }
        if code.contains("shoulder") { return ["acromial","deltoid","scapular"] }
        if code.contains("scapula") { return ["superior","inferior","medial","lateral"] }
        if code.contains("knee") { return ["anterior","posterior","lateral","medial"] }
        if code.contains("shin") { return ["anterior","medial","lateral"] }
        if code.contains("calf") { return ["posterior","lateral","medial"] }
        if code.contains("thigh") { return ["anterior","posterior","lateral","medial"] }
        return []
    }
}
