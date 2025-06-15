import SwiftUI
enum WoundNavigation: Hashable {
    case capture(image: UIImage, groupId: String, groupName: String)
}
struct WoundImageSourceView: View {
    let selectedPatient: Patient?

    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?

    @State private var showGroupPicker = false
    @State private var selectedGroupId: String?
    @State private var selectedGroupName: String?

    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: pickerSource)
                    .onDisappear {
                        if selectedImage != nil {
                            showGroupPicker = true
                        }
                    }
            }
            .sheet(isPresented: $showGroupPicker) {
                if let patient = selectedPatient {
                    WoundGroupPickerView(
                        patientId: patient.id,
                        onGroupSelected: { groupId, groupName in
                            selectedGroupId = groupId
                            selectedGroupName = groupName
                            showGroupPicker = false
                            pushCaptureView()
                        }
                    )
                } else {
                    VStack(spacing: 16) {
                        Text("No patient selected.")
                            .foregroundColor(.gray)

                        Button("Continue Without Group") {
                            selectedGroupId = UUID().uuidString
                            selectedGroupName = "Fast Capture \(Date().formatted(date: .abbreviated, time: .shortened))"
                            showGroupPicker = false
                            pushCaptureView()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationDestination(for: WoundNavigation.self) { route in
                switch route {
                case .capture(let image, let groupId, let groupName):
                    CaptureWoundView(
                        patient: selectedPatient,
                        image: image,
                        woundGroupId: groupId,
                        woundGroupName: groupName
                    )
                }
            }
        }
    }

    private func pushCaptureView() {
        if let image = selectedImage,
           let groupId = selectedGroupId,
           let groupName = selectedGroupName {
            navigationPath.append(WoundNavigation.capture(image: image, groupId: groupId, groupName: groupName))
        }
    }
}
