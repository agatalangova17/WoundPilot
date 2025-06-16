import SwiftUI

struct WoundImageSourceView: View {
    let selectedPatient: Patient?

    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?

    @State private var showGroupPicker = false
    @State private var selectedGroupId: String?
    @State private var selectedGroupName: String?

    @State private var showCaptureScreen = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // MARK: - Icon + Title
                VStack(spacing: 10) {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentBlue)

                    Text("Add Wound Image")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                .padding(.top, 30)

                // MARK: - Main Buttons
                VStack(spacing: 16) {
                    Button {
                        pickerSource = .camera
                        showImagePicker = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button {
                        pickerSource = .photoLibrary
                        showImagePicker = true
                    } label: {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentBlue.opacity(0.15))
                            .foregroundColor(.accentBlue)
                            .cornerRadius(10)
                    }

#if targetEnvironment(simulator)
                    Button {
                        selectedImage = UIImage(named: "dummy_wound")
                        if selectedPatient != nil {
                            showGroupPicker = true
                        } else {
                            assignFastGroupAndNavigate()
                        }
                    } label: {
                        Label("Use Dummy Wound Image", systemImage: "photo.fill.on.rectangle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .foregroundColor(.gray)
                            .cornerRadius(10)
                    }
#endif
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("New Wound")
            .navigationBarTitleDisplayMode(.inline)

            // MARK: - Image Picker
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: pickerSource)
                    .onDisappear {
                        if selectedImage != nil {
                            if selectedPatient != nil {
                                showGroupPicker = true
                            } else {
                                assignFastGroupAndNavigate()
                            }
                        }
                    }
            }

            // MARK: - Group Picker
            .sheet(isPresented: $showGroupPicker) {
                if let patient = selectedPatient {
                    WoundGroupPickerView(
                        patientId: patient.id,
                        onGroupSelected: { groupId, groupName in
                            selectedGroupId = groupId
                            selectedGroupName = groupName
                            showGroupPicker = false
                            showCaptureScreen = true
                        }
                    )
                } else {
                    EmptyView()
                }
            }

            // MARK: - Navigate to Capture
            .navigationDestination(isPresented: $showCaptureScreen) {
                if let image = selectedImage,
                   let groupId = selectedGroupId,
                   let groupName = selectedGroupName {
                    CaptureWoundView(
                        patient: selectedPatient,
                        image: image,
                        woundGroupId: groupId,
                        woundGroupName: groupName
                    )
                } else {
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Assign Group for Fast Capture
    private func assignFastGroupAndNavigate() {
        selectedGroupId = UUID().uuidString
        selectedGroupName = "Quick Analysis \(Date().formatted(date: .abbreviated, time: .shortened))"
        showCaptureScreen = true
    }
}
