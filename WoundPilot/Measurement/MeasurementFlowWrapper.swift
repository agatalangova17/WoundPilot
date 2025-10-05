import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct MeasurementFlowWrapper: View {
    let patient: Patient?
    let woundGroupId: String?
    let locationString: String?
    
    @State private var goToQuestionnaire = false
    @State private var isSaving = false
    @State private var savedWoundId: String?
    @State private var measurementResult: WoundMeasurementResult?
    
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
            QuestionnaireView(
                woundGroupId: savedWoundId ?? "quick_scan_\(UUID().uuidString)",
                patientId: patient?.id ?? "anonymous",
                isQuickScan: patient == nil,
                measurementResult: measurementResult
            )
        }
    }
    
    private func saveAndProceed(_ result: WoundMeasurementResult) {
        measurementResult = result
        
        // If we have a patient, save to Firebase
        if let patient = patient {
            isSaving = true
            uploadImage(result.capturedImage) { imageURL in
                createWound(result: result, imageURL: imageURL, patientId: patient.id)
            }
        } else {
            // Quick scan - skip Firebase, go directly to questionnaire
            goToQuestionnaire = true
        }
    }
    
    private func uploadImage(_ image: UIImage?, completion: @escaping (String?) -> Void) {
        guard let image = image,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
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
        let woundGroupIdToUse = woundGroupId ?? UUID().uuidString
        
        // Save to woundGroups (new architecture - for questionnaire)
        let woundGroupData: [String: Any] = [
            "patientId": patientId,
            "location": locationString ?? "",
            "imageURL": imageURL ?? "",
            "lengthCm": result.lengthCm,
            "widthCm": result.widthCm,
            "areaCm2": result.areaCm2 ?? 0,
            "measurementMethod": result.method.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore()
            .collection("woundGroups")
            .document(woundGroupIdToUse)
            .setData(woundGroupData, merge: true)
        
        // ALSO save to wounds collection (old architecture - for display)
        guard let userId = Auth.auth().currentUser?.uid else {
            isSaving = false
            return
        }
        
        let woundData: [String: Any] = [
            "imageURL": imageURL ?? "",
            "timestamp": FieldValue.serverTimestamp(),
            "location": locationString ?? "",
            "woundGroupId": woundGroupIdToUse,
            "woundGroupName": "Wound \(Date().formatted(date: .abbreviated, time: .omitted))",
            "patientId": patientId,
            "userId": userId
        ]
        
        Firestore.firestore().collection("wounds").addDocument(data: woundData) { error in
                DispatchQueue.main.async {
                    isSaving = false
                    if error == nil {
                        savedWoundId = woundGroupIdToUse
                        goToQuestionnaire = true
                    }
                }
            }
    }
}
