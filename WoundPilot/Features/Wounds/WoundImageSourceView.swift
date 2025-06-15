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
                showGroupPicker = true
            }
            .buttonStyle(.bordered)
#endif

            Spacer()
        }
        .padding()
        .navigationTitle("New Wound")

        // Step 1: Show image picker
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: pickerSource)
                .onDisappear {
                    if selectedImage != nil {
                        showGroupPicker = true
                    }
                }
        }

        // Step 2: Show wound group picker
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
                // Fast capture mode (no patient)
                VStack(spacing: 16) {
                    Text("No patient selected.")
                        .foregroundColor(.gray)

                    Button("Continue Without Group") {
                        selectedGroupId = UUID().uuidString
                        selectedGroupName = "Fast Capture \(Date().formatted(date: .abbreviated, time: .shortened))"
                        showGroupPicker = false
                        showCaptureScreen = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }

        // Step 3: Navigate to CaptureWoundView
        .background(
            NavigationLink(
                destination: showCaptureScreen && selectedImage != nil && selectedGroupId != nil && selectedGroupName != nil ?
                    AnyView(CaptureWoundView(
                        patient: selectedPatient,
                        image: selectedImage!,
                        woundGroupId: selectedGroupId!,
                        woundGroupName: selectedGroupName!
                    )) :
                    AnyView(EmptyView()),
                isActive: $showCaptureScreen
            ) {
                EmptyView()
            }
        )
    }
}
