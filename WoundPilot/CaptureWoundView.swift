import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct CaptureWoundView: View {
    @State private var image: UIImage?
    @State private var isPickerPresented = false
    @State private var isUploading = false
    @State private var uploadMessage = ""

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .cornerRadius(10)
            } else {
                Text("No image selected")
                    .foregroundColor(.gray)
            }

            Button("Capture Wound Photo") {
                isPickerPresented = true
            }
            .padding()
            .buttonStyle(.borderedProminent)

            Button("Upload to Firebase") {
                uploadWound()
            }
            .disabled(image == nil || isUploading)
            .padding()
            .buttonStyle(.bordered)

            if isUploading {
                ProgressView("Uploading...")
            }

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                    .font(.footnote)
                    .foregroundColor(.green)
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            ImagePicker(image: $image)
        }
        .padding()
        .navigationTitle("Capture Wound")
    }

    func uploadWound() {
        guard let image = image,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let user = Auth.auth().currentUser else {
            uploadMessage = "Image or user missing."
            return
        }

        isUploading = true
        uploadMessage = ""

        let storageRef = Storage.storage().reference()
        let filename = "wounds/\(user.uid)/\(UUID().uuidString).jpg"
        let imageRef = storageRef.child(filename)

        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                isUploading = false
                uploadMessage = "Upload failed: \(error.localizedDescription)"
                return
            }

            imageRef.downloadURL { url, error in
                isUploading = false
                if let url = url {
                    saveWoundMetadata(imageURL: url.absoluteString, userId: user.uid)
                    uploadMessage = "Upload successful!"
                    self.image = nil // Reset after success
                } else {
                    uploadMessage = "Failed to get download URL."
                }
            }
        }
    }

    func saveWoundMetadata(imageURL: String, userId: String) {
        let db = Firestore.firestore()
        db.collection("wounds").addDocument(data: [
            "imageURL": imageURL,
            "userId": userId,
            "timestamp": Timestamp(date: Date())
        ])
    }
}
