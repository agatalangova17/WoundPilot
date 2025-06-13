import SwiftUI

struct WoundImageSourceView: View {
    let patient: Patient
    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
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
                showCaptureScreen = true
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
                        showCaptureScreen = true
                    }
                }
        }
        .background(
            NavigationLink(
                destination: CaptureWoundView(patient: patient, image: selectedImage),
                isActive: $showCaptureScreen
            ) { EmptyView() }
        )
    }
}
