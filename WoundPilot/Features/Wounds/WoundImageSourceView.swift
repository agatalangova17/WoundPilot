import SwiftUI


struct WoundImageSourceView: View {
    let selectedPatient: Patient?
    let preselectedWoundGroupId: String?    // default lets you call it without passing
    let preselectedLocation: String?

    init(selectedPatient: Patient?,
         preselectedWoundGroupId: String? = nil,
         preselectedLocation: String? = nil) {
        self.selectedPatient = selectedPatient
        self.preselectedWoundGroupId = preselectedWoundGroupId
        self.preselectedLocation = preselectedLocation
    }

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?

    @State private var showConfirmationView = false
    @State private var navigateToPrepare = false
    @State private var nextStepTriggered = false
    

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle background
                LinearGradient(colors: [Color(white: 0.96), .white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 32) {

                    // MARK: - Image Input Options
                    VStack(spacing: 16) {
                        OptionCard(
                            icon: "camera.fill",
                            title: LocalizedStrings.takePhoto,
                            caption: LocalizedStrings.takePhotoCaption,
                            color: Color.primaryBlue,
                            foreground: Color.white
                        ) {
                            pickerSource = .camera
                            showImagePicker = true
                        }

                        OptionCard(
                            icon: "photo.on.rectangle",
                            title: LocalizedStrings.choosePhoto,
                            caption: LocalizedStrings.choosePhotoCaption,
                            color: Color.accentBlue.opacity(0.15),
                            foreground: Color.accentBlue.darker(by: 0.25) // darker turquoise
                        ) {
                            pickerSource = .photoLibrary
                            showImagePicker = true
                        }

                        #if targetEnvironment(simulator)
                        OptionCard(
                            icon: "photo.fill.on.rectangle.fill",
                            title: LocalizedStrings.useDummyWoundImage,
                            caption: LocalizedStrings.simulatorOnlyTestingImage,
                            color: Color.gray.opacity(0.1),
                            foreground: Color.gray.darker(by: 0.25) // darker gray
                        ) {
                            selectedImage = UIImage(named: "dummy_wound")
                            showConfirmationView = true
                        }
                        #endif
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
            .navigationTitle(LocalizedStrings.newWoundTitle)
            .navigationBarTitleDisplayMode(.inline)

            // MARK: - Sheets
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: pickerSource)
                    .onDisappear {
                        if selectedImage != nil {
                            showConfirmationView = true
                        }
                    }
            }

            .sheet(isPresented: $showConfirmationView) {
                if let image = selectedImage {
                    ImageConfirmationView(
                        image: image,
                        onConfirm: {
                            showConfirmationView = false
                            nextStepTriggered = true
                        },
                        onRetake: {
                            selectedImage = nil
                            showConfirmationView = false
                            showImagePicker = true
                        }
                    )
                }
            }

            // MARK: - Navigation Trigger
            .navigationDestination(isPresented: $navigateToPrepare) {
                if let image = selectedImage {
                    PrepareWoundAnalysisView(image: image, patient: selectedPatient)
                }
            }

            // iOS 17-safe onChange (zero-parameter closure)
            .onChange(of: nextStepTriggered) {
                if nextStepTriggered {
                    navigateToPrepare = true
                    nextStepTriggered = false
                }
            }
        }
    }
}

// MARK: - Card Component
struct OptionCard: View {
    var icon: String
    var title: String
    var caption: String
    var color: Color
    var foreground: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(foreground)
                    .padding(10)
                    .background(foreground.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(foreground) // darker applied here

                    Text(caption)
                        .font(.caption)
                        .foregroundColor(foreground.opacity(0.85)) // slightly stronger opacity
                }

                Spacer()
            }
            .padding()
            .background(color)
            .cornerRadius(14)
        }
    }
}

extension Color {
    func darker(by amount: CGFloat = 0.05) -> Color {
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return Color(uiColor: UIColor(
                hue: h,
                saturation: s,
                brightness: max(b - amount, 0),
                alpha: a
            ))
        }

        return self
    }
}
