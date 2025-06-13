import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct CaptureWoundView: View {
    let patient: Patient
    let image: UIImage?
    let woundGroupId: String
    let woundGroupName: String

    @State private var selectedLocation: String?
    @State private var isUploading = false
    @State private var uploadMessage = ""
    @State private var showLocationPicker = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(10)
                }

                Button("Select Wound Location") {
                    showLocationPicker = true
                }
                .buttonStyle(.bordered)

                if let location = selectedLocation {
                    Text("Location: \(location.replacingOccurrences(of: "_", with: " ").capitalized)")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }

                Text("Group: \(woundGroupName)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Button("Save Wound Entry") {
                    uploadWound()
                }
                .disabled(selectedLocation == nil)
                .buttonStyle(.borderedProminent)

                Button("Retake Photo") {
                    dismiss()
                }
                .foregroundColor(.red)

                if isUploading {
                    ProgressView("Uploading...")
                }

                if !uploadMessage.isEmpty {
                    Text(uploadMessage)
                        .font(.footnote)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .navigationTitle("Review & Save")
        .sheet(isPresented: $showLocationPicker) {
            WoundLocationPickerView(selectedRegion: $selectedLocation)
        }
    }

    func uploadWound() {
        guard let image = image,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let user = Auth.auth().currentUser else {
            uploadMessage = "Missing image or user."
            return
        }

        isUploading = true
        uploadMessage = ""

        let storageRef = Storage.storage().reference()
        let filename = "wounds/\(user.uid)/\(UUID().uuidString).jpg"
        let imageRef = storageRef.child(filename)

        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                isUploading = false
                uploadMessage = "Upload failed: \(error.localizedDescription)"
                return
            }

            imageRef.downloadURL { url, error in
                isUploading = false
                if let url = url {
                    saveWoundMetadata(
                        imageURL: url.absoluteString,
                        userId: user.uid,
                        patientId: patient.id,
                        woundGroupId: woundGroupId,
                        woundGroupName: woundGroupName
                    )
                    uploadMessage = "Wound saved successfully!"
                } else {
                    uploadMessage = "Failed to get download URL."
                }
            }
        }
    }

    func saveWoundMetadata(imageURL: String, userId: String, patientId: String, woundGroupId: String, woundGroupName: String) {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "imageURL": imageURL,
            "userId": userId,
            "patientId": patientId,
            "woundGroupId": woundGroupId,
            "woundGroupName": woundGroupName,
            "timestamp": Timestamp(date: Date())
        ]

        if let location = selectedLocation {
            data["location"] = location
        }

        db.collection("wounds").addDocument(data: data)
    }
}
