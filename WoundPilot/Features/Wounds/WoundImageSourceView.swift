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
            VStack(spacing: 24) {
                Text("Add Wound Image")
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack(spacing: 12) {
                    Button("Take Photo") {
                        pickerSource = .camera
                        showImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Choose Photo") {
                        pickerSource = .photoLibrary
                        showImagePicker = true
                    }
                    .buttonStyle(.bordered)
                }

#if targetEnvironment(simulator)
                Button("Use Dummy Wound Image") {
                    selectedImage = UIImage(named: "dummy_wound")
                    if selectedPatient != nil {
                        showGroupPicker = true
                    } else {
                        assignFastGroupAndNavigate()
                    }
                }
                .buttonStyle(.bordered)
#endif

                Spacer()
            }
            .padding()
            .navigationTitle("New Wound")

            // Step 1: Image Picker
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

            // Step 2: Wound Group Picker
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
                    EmptyView() // should never be hit now
                }
            }

            // Step 3: Navigation to CaptureWoundView
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

    private func assignFastGroupAndNavigate() {
        selectedGroupId = UUID().uuidString
        selectedGroupName = "Quick Analysis \(Date().formatted(date: .abbreviated, time: .shortened))"
        showCaptureScreen = true
    }
}
