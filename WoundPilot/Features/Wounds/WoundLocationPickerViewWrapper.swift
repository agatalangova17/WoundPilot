import SwiftUI

struct WoundLocationPickerViewWrapper: View {
    let image: UIImage
    let patient: Patient?

    @State private var selectedRegion: String?
    @State private var showGroupPicker = false
    @State private var selectedGroupId: String?
    @State private var selectedGroupName: String?

    var body: some View {
        VStack {
            WoundLocationPickerView(
                selectedRegion: $selectedRegion,
                onConfirm: { region in
                    selectedRegion = region
                    showGroupPicker = true
                }
            )

            if selectedRegion != nil {
                Button(action: {
                    showGroupPicker = true
                }) {
                    Text("Confirm")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.accentBlue, Color.primaryBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }
        }
        .navigationDestination(isPresented: $showGroupPicker) {
            if let region = selectedRegion {
                WoundGroupPickerView(patient: patient) { groupId, groupName in
                    self.selectedGroupId = groupId
                    self.selectedGroupName = groupName
                    // Proceed to preparing view after group selection
                }
                .navigationDestination(isPresented: .constant(selectedGroupId != nil)) {
                    if let groupId = selectedGroupId,
                       let groupName = selectedGroupName,
                       let region = selectedRegion {
                        PreparingAnalysisView(
                            image: image,
                            location: region,
                            patient: patient,
                            woundGroupId: groupId,
                            woundGroupName: groupName
                        )
                    }
                }
            }
        }
    }
}
