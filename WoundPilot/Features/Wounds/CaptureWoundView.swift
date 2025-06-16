import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct CaptureWoundView: View {
    let patient: Patient?
    let image: UIImage?
    let woundGroupId: String
    let woundGroupName: String

    @State private var selectedLocation: String?
    @State private var isUploading = false
    @State private var uploadMessage = ""
    @State private var showLocationPicker = false
    @State private var savedWound: Wound? = nil

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Image Preview
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: - Wound Location
                    VStack(spacing: 8) {
                        Button(action: {
                            showLocationPicker = true
                        }) {
                            Text(selectedLocation == nil ? "Select Wound Location" : "Change Location")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        if let location = selectedLocation {
                            Text("Location: \(location.replacingOccurrences(of: "_", with: " ").capitalized)")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                    }

                    // MARK: - Save Button
                    Button(action: uploadWound) {
                        Text("Save Wound Entry")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedLocation != nil ? Color.accentBlue : Color.gray.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(selectedLocation == nil || isUploading)

                    // MARK: - Retake Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Retake Photo")
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }

                    // MARK: - Upload Status
                    if isUploading {
                        ProgressView("Uploading...")
                            .padding(.top, 10)
                    }

                    if !uploadMessage.isEmpty {
                        Text(uploadMessage)
                            .font(.footnote)
                            .foregroundColor(.green)
                    }

                    // MARK: - Navigation
                    if let wound = savedWound {
                        NavigationLink(destination: SingleWoundDetailView(wound: wound)) {
                            Text("Proceed to Analysis")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
            .navigationTitle("Review & Save")
            .sheet(isPresented: $showLocationPicker) {
                WoundLocationPickerView(selectedRegion: $selectedLocation)
            }
        }
    }

    // MARK: - Upload Logic
    private func uploadWound() {
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
                    saveWoundMetadata(imageURL: url.absoluteString, userId: user.uid)
                } else {
                    uploadMessage = "Failed to get download URL."
                }
            }
        }
    }

    private func saveWoundMetadata(imageURL: String, userId: String) {
        let db = Firestore.firestore()
        let newDoc = db.collection("wounds").document()

        var data: [String: Any] = [
            "imageURL": imageURL,
            "userId": userId,
            "woundGroupId": woundGroupId,
            "woundGroupName": woundGroupName,
            "timestamp": Timestamp(date: Date())
        ]

        if let patient = patient {
            data["patientId"] = patient.id
        }
        if let location = selectedLocation {
            data["location"] = location
        }

        newDoc.setData(data) { error in
            if let error = error {
                uploadMessage = "Failed to save wound: \(error.localizedDescription)"
                return
            }

            savedWound = Wound(
                id: newDoc.documentID,
                imageURL: imageURL,
                timestamp: Date(),
                location: selectedLocation,
                patientId: patient?.id ?? "",
                userId: userId,
                woundGroupId: woundGroupId,
                woundGroupName: woundGroupName
            )

            uploadMessage = "✅ Wound saved successfully!"
        }
    }
}
