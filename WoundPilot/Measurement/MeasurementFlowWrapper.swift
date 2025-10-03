import SwiftUI
import FirebaseFirestore
import FirebaseStorage

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
                        Text("Saving wound...").foregroundColor(.white)
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
        let woundData: [String: Any] = [
            "patientId": patientId,
            "woundGroupId": woundGroupId ?? "",
            "location": locationString ?? "",
            "imageURL": imageURL ?? "",
            "lengthCm": result.lengthCm,
            "widthCm": result.widthCm,
            "areaCm2": result.areaCm2 ?? 0,
            "measurementMethod": result.method.rawValue,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore().collection("wounds").addDocument(data: woundData) { error in
            DispatchQueue.main.async {
                isSaving = false
                if error == nil {
                    savedWoundId = woundGroupId
                    goToQuestionnaire = true
                }
            }
        }
    }
}
