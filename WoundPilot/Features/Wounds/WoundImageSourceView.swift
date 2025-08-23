import SwiftUI

struct WoundImageSourceView: View {
    let selectedPatient: Patient?

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
                            color: Color.primaryBlue
                        ) {
                            pickerSource = .camera
                            showImagePicker = true
                        }

                        OptionCard(
                            icon: "photo.on.rectangle",
                            title: LocalizedStrings.choosePhoto,
                            caption: LocalizedStrings.choosePhotoCaption,
                            color: Color.accentBlue.opacity(0.15),
                            foreground: .accentBlue
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
                            foreground: .gray
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
    var foreground: Color = .white
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
                        .foregroundColor(foreground)

                    Text(caption)
                        .font(.caption)
                        .foregroundColor(foreground.opacity(0.7))
                }

                Spacer()
            }
            .padding()
            .background(color)
            .cornerRadius(14)
        }
    }
}
