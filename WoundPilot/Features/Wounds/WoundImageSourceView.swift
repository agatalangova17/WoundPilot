import SwiftUI

struct WoundImageSourceView: View {
    let selectedPatient: Patient?

    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?

    @State private var showConfirmationView = false
    @State private var navigateToGroupPicker = false
    @State private var navigateToPrepare = false

    @State private var woundGroupId = UUID().uuidString
    @State private var woundGroupName = "Quick Analysis \(Date().formatted(date: .abbreviated, time: .shortened))"

    @State private var nextStepTriggered = false  // ✅ Triggers transition after confirmation sheet closes
    

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
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
                        showConfirmationView = true
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

            // MARK: - Image Picker Sheet
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: pickerSource)
                    .onDisappear {
                        if selectedImage != nil {
                            showConfirmationView = true
                        }
                    }
            }

            // MARK: - Image Confirmation Sheet
            .sheet(isPresented: $showConfirmationView) {
                if let image = selectedImage {
                    ImageConfirmationView(
                        image: image,
                        onConfirm: {
                            showConfirmationView = false
                            nextStepTriggered = true  // ✅ Advance flow
                        },
                        onRetake: {
                            selectedImage = nil
                            showConfirmationView = false
                            showImagePicker = true
                        }
                    )
                }
            }

            // MARK: - Navigation to Group Picker (New!)
            .navigationDestination(isPresented: $navigateToGroupPicker) {
                if let patient = selectedPatient {
                    WoundGroupPickerView(
                        patientId: patient.id,
                        onGroupSelected: { groupId, groupName in
                            print("🧩 Group selected: \(groupId) — \(groupName)")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.woundGroupId = groupId
                                self.woundGroupName = groupName
                                self.navigateToGroupPicker = false
                                self.navigateToPrepare = true
                                print("🚀 Triggered prepare navigation after delay")
                            }
                        }
                    )
                }
            }

            // MARK: - Navigation to Prepare Analysis
            .navigationDestination(isPresented: $navigateToPrepare) {
                if let image = selectedImage {
                    PrepareWoundAnalysisView(
                        image: image,
                        patient: selectedPatient,
                        woundGroupId: woundGroupId,
                        woundGroupName: woundGroupName
                    )
                }
            }

            // MARK: - Control Flow Trigger
            .onChange(of: nextStepTriggered) {
                if nextStepTriggered {
                    if selectedPatient != nil {
                        navigateToGroupPicker = true
                    } else {
                        navigateToPrepare = true
                    }
                    nextStepTriggered = false
                }
            }
        }
    }
}
