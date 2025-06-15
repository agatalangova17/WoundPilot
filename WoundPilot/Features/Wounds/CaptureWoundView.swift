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
                VStack(spacing: 16) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .cornerRadius(10)
                    }

                    if let patient = patient {
                        Text("Patient: \(patient.name)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        Text("⚠️ Fast Capture (Saved without patient)")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }

                    Text("Group: \(woundGroupName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Button("Select Wound Location") {
                        showLocationPicker = true
                    }
                    .buttonStyle(.bordered)

                    if let location = selectedLocation {
                        Text("Location: \(location.replacingOccurrences(of: "_", with: " ").capitalized)")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }

                    Button("Save Wound Entry") {
                        uploadWound()
                    }
                    .disabled(selectedLocation == nil || isUploading)
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

                    // ✅ Navigate only if savedWound is set
                    if let wound = savedWound {
                        NavigationLink(
                            destination: SingleWoundDetailView(wound: wound),
                            label: {
                                Text("Proceed to Analysis")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                        )
                        .buttonStyle(.borderedProminent)
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

            uploadMessage = "Wound saved successfully!"
        }
    }
}
