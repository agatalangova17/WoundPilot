import SwiftUI
import FirebaseFirestore
import FirebaseStorage

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
            WoundMeasurementView { result in
                handleMeasurementComplete(result)
            }
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
                    Text(LocalizedStrings.t("Sub-site", "Podlokalita"))
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
            Text(localizeSubsite(opt))
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
                title: LocalizedStrings.t("Foot detail", "Detail chodidla"),
                value: localizeFootDetail(detail),
                action: { showFootDetailSheet = true }
            )
        }
    }
    
    @ViewBuilder
    private var handDetailSection: some View {
        if let region = selectedRegion, isHandRegion(region), let detail = handDetail {
            detailChipRow(
                title: LocalizedStrings.t("Hand detail", "Detail ruky"),
                value: localizeHandDetail(detail),
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
        
        // Reset context
        selectedSubsite = nil
        footDetail = nil
        handDetail = nil
        
        // Extract side from region code (no picker needed)
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
    
    private func handleMeasurementComplete(_ result: WoundMeasurementResult) {
        guard let patient = patient else { return }
        
        // Upload image to Firebase Storage
        uploadImageIfPresent(result.capturedImage) { imageURL in
            self.createWoundRecord(
                result: result,
                imageURL: imageURL,
                patientId: patient.id
            )
        }
    }
    
    private func uploadImageIfPresent(_ image: UIImage?, completion: @escaping (String?) -> Void) {
        guard let image = image else {
            completion(nil)
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        let filename = UUID().uuidString + ".jpg"
        let storageRef = Storage.storage().reference()
            .child("wounds")
            .child(filename)
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Upload failed: \(error!)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                completion(url?.absoluteString)
            }
        }
    }
    
    private func createWoundRecord(result: WoundMeasurementResult, imageURL: String?, patientId: String) {
        let woundData: [String: Any] = [
            "patientId": patientId,
            "woundGroupId": woundGroupId ?? "",
            "location": composedLocationString() ?? "",
            "imageURL": imageURL ?? "",
            "lengthCm": result.lengthCm,
            "widthCm": result.widthCm,
            "areaCm2": result.areaCm2 ?? 0,
            "measurementMethod": result.method.rawValue,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore().collection("wounds").addDocument(data: woundData) { error in
            if let error = error {
                print("Error creating wound: \(error)")
            } else {
                print("Wound saved successfully!")
                // TODO: Navigate to questionnaire or dismiss
            }
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
        // Skip subsites for abdomen/chest (they use quadrants already)
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
    
    // MARK: - Localization
    
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
        case "toe_5": return LocalizedStrings.t("5th toe", "5. prst")
        case "heel_central": return LocalizedStrings.t("Heel (central)", "Päta (stred)")
        case "heel_medial": return LocalizedStrings.t("Heel (medial)", "Päta (mediálna)")
        case "heel_lateral": return LocalizedStrings.t("Heel (lateral)", "Päta (laterálna)")
        case "forefoot": return LocalizedStrings.t("Forefoot", "Predonožie")
        case "midfoot": return LocalizedStrings.t("Midfoot", "Strednožie")
        case "hindfoot": return LocalizedStrings.t("Hindfoot", "Zadnožie")
        case "plantar_arch": return LocalizedStrings.t("Plantar arch", "Plantárna klenba")
        default: return code.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private func localizeHandDetail(_ code: String) -> String {
        switch code {
        case "palm": return LocalizedStrings.t("Palm", "Dlań")
        case "thumb": return LocalizedStrings.t("Thumb", "Palec")
        case "index": return LocalizedStrings.t("Index finger", "Ukazovák")
        case "middle": return LocalizedStrings.t("Middle finger", "Prostredník")
        case "ring": return LocalizedStrings.t("Ring finger", "Prstenník")
        case "pinky": return LocalizedStrings.t("Pinky", "Malíček")
        case "wrist": return LocalizedStrings.t("Wrist", "Zápästie")
        case "thenar": return "Thenar"
        case "hypothenar": return "Hypothenar"
        case "dorsum": return LocalizedStrings.t("Back of hand", "Chrbát ruky")
        default: return code.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
