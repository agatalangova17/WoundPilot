import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct CaptureWoundView: View {
    @State private var image: UIImage?
    @State private var isPickerPresented = false
    @State private var isUploading = false
    @State private var uploadMessage = ""
    @State private var showLocationPicker = false
    @State private var selectedLocation: String?

    var body: some View {
        VStack(spacing: 16) {
            // Image Preview
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

            // Capture Button
            Button("Capture Wound Photo") {
                isPickerPresented = true
            }
            .buttonStyle(.borderedProminent)
            
#if targetEnvironment(simulator)
Button("Use Dummy Wound Image") {
    image = UIImage(named: "dummy_wound")
}
.buttonStyle(.bordered)
.padding(.bottom, 4)
#endif

            // Location Picker Button
            Button("Select Wound Location") {
                showLocationPicker = true
            }
            .disabled(image == nil)
            .buttonStyle(.bordered)

            // Show selected location
            if let location = selectedLocation {
                Text("Selected Location: \(location.replacingOccurrences(of: "_", with: " ").capitalized)")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

            // Upload Button
            Button("Upload to Firebase") {
                uploadWound()
            }
            .disabled(image == nil || isUploading || selectedLocation == nil)
            .buttonStyle(.bordered)

            // Upload Progress & Result
            if isUploading {
                ProgressView("Uploading...")
            }

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                    .font(.footnote)
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Capture Wound")
        .sheet(isPresented: $isPickerPresented) {
            ImagePicker(image: $image)
        }
        .sheet(isPresented: $showLocationPicker) {
            WoundLocationPickerView(selectedRegion: $selectedLocation)
        }
    }

    // MARK: - Upload Image + Save Metadata
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
                    self.image = nil
                    self.selectedLocation = nil
                } else {
                    uploadMessage = "Failed to get download URL."
                }
            }
        }
    }

    func saveWoundMetadata(imageURL: String, userId: String) {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "imageURL": imageURL,
            "userId": userId,
            "timestamp": Timestamp(date: Date())
        ]

        if let location = selectedLocation {
            data["location"] = location
        }

        db.collection("wounds").addDocument(data: data)
    }
}
