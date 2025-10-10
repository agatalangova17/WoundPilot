import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct MeasurementFlowWrapper: View {
    let patient: Patient?
    let woundGroupId: String?
    let locationString: String?
    let bodyRegionCode: String?

    @State private var goToQuestionnaire = false
    @State private var isSaving = false
    @State private var savedWoundId: String?
    @State private var measurementResult: WoundMeasurementResult?

    // Stable IDs so we don't generate fresh UUIDs every render
    @State private var quickScanId = UUID().uuidString
    @State private var fallbackWoundGroupId = UUID().uuidString

    var body: some View {
        ZStack {
            WoundMeasurementView { result in
                saveAndProceed(result)
            }

            if isSaving {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView().scaleEffect(1.5).tint(.white)
                        Text(LocalizedStrings.savingWoundSpinner).foregroundColor(.white)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                }
            }
        }
        .navigationDestination(isPresented: $goToQuestionnaire) {
            if let p = patient {
                QuestionnaireView(
                    woundGroupId: savedWoundId ?? woundGroupId ?? fallbackWoundGroupId,
                    context: makePatientContext(for: p),
                    isQuickScan: false,
                    measurementResult: measurementResult
                )
            } else {
                QuestionnaireView(
                    woundGroupId: quickScanId,
                    context: makeQuickScanContext(),
                    isQuickScan: true,
                    measurementResult: measurementResult
                )
            }
        }
    }

    // MARK: - Context Builders

    private func makePatientContext(for p: Patient) -> QuestionnaireContext {
        // Convert Float? from measurementResult to Double? explicitly
        let len: Double?  = measurementResult.map { Double($0.lengthCm) }
        let wid: Double?  = measurementResult.map { Double($0.widthCm) }
        let area: Double? = measurementResult?.areaCm2.flatMap { Double($0) }

        return QuestionnaireContext(
            patientId: p.id,
            hasDiabetes: p.hasDiabetes,
            hasPAD: p.hasPAD,
            hasVenousDisease: p.hasVenousDisease,
            isImmunosuppressed: p.isImmunosuppressed,
            hasMobilityImpairment: p.hasMobilityImpairment,
            canOffload: p.canOffload,
            isOnAnticoagulants: p.isOnAnticoagulants,
            allergyToAdhesives: p.allergyToAdhesives,
            allergyToIodine: p.allergyToIodine,
            allergyToSilver: p.allergyToSilver,
            allergyToLatex: p.allergyToLatex,
            otherAllergies: p.otherAllergies,
            bodyLocation: locationString,
            bodyRegionCode: bodyRegionCode,
            isLowerLimb: isLowerLimbLocation(bodyRegionCode),
            lengthCm: len,
            widthCm: wid,
            areaCm2: area
        )
    }

    private func makeQuickScanContext() -> QuestionnaireContext {
        let len: Double?  = measurementResult.map { Double($0.lengthCm) }
        let wid: Double?  = measurementResult.map { Double($0.widthCm) }
        let area: Double? = measurementResult?.areaCm2.flatMap { Double($0) }

        return QuestionnaireContext(
            patientId: "anonymous",
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
            bodyLocation: nil,
            bodyRegionCode: nil,
            isLowerLimb: false,
            lengthCm: len,
            widthCm: wid,
            areaCm2: area
        )
    }

    // MARK: - Helpers

    private func isLowerLimbLocation(_ regionCode: String?) -> Bool {
        guard let code = regionCode?.lowercased() else { return false }
        let lowerLimbRegions = ["foot", "ankle", "lower_leg", "knee", "thigh", "heel", "toe", "calf", "shin"]
        return lowerLimbRegions.contains(where: { code.contains($0) })
    }

    private func saveAndProceed(_ result: WoundMeasurementResult) {
        measurementResult = result

        if let p = patient {
            isSaving = true
            uploadImage(result.capturedImage) { imageURL in
                createWound(result: result, imageURL: imageURL, patientId: p.id)
            }
        } else {
            goToQuestionnaire = true
        }
    }

    private func uploadImage(_ image: UIImage?, completion: @escaping (String?) -> Void) {
        guard let image = image, let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }

        let filename = UUID().uuidString + ".jpg"
        let storageRef = Storage.storage().reference().child("wounds").child(filename)

        storageRef.putData(imageData, metadata: nil) { _, error in
            guard error == nil else {
                print("Upload failed: \(error!)")
                completion(nil)
                return
            }
            storageRef.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }

    private func createWound(result: WoundMeasurementResult, imageURL: String?, patientId: String) {
        let woundGroupIdToUse = woundGroupId ?? fallbackWoundGroupId

        let woundGroupData: [String: Any] = [
            "patientId": patientId,
            "location": locationString ?? "",
            "bodyRegionCode": bodyRegionCode ?? "",
            "imageURL": imageURL ?? "",
            "lengthCm": Double(result.lengthCm),                  // store as Double for consistency
            "widthCm": Double(result.widthCm),
            "areaCm2": Double(result.areaCm2 ?? 0),
            "measurementMethod": result.method.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ]

        Firestore.firestore()
            .collection("woundGroups")
            .document(woundGroupIdToUse)
            .setData(woundGroupData, merge: true)

        guard let userId = Auth.auth().currentUser?.uid else {
            isSaving = false
            return
        }

        let woundData: [String: Any] = [
            "imageURL": imageURL ?? "",
            "timestamp": FieldValue.serverTimestamp(),
            "location": locationString ?? "",
            "woundGroupId": woundGroupIdToUse,
            "woundGroupName": (locationString?
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "|", with: " - ")
                .capitalized) ?? "Wound \(Date().formatted(date: .abbreviated, time: .omitted))",
            "patientId": patientId,
            "userId": userId
        ]

        Firestore.firestore().collection("wounds").addDocument(data: woundData) { error in
            DispatchQueue.main.async {
                isSaving = false
                if error == nil {
                    savedWoundId = woundGroupIdToUse
                    // Ensure the same ID is used after save
                    fallbackWoundGroupId = woundGroupIdToUse
                    goToQuestionnaire = true
                }
            }
        }
    }
}
