import SwiftUI

struct WoundLocationPickerViewWrapper: View {
    let image: UIImage
    let patient: Patient?

    @State private var selectedRegion: String?
    @State private var showNextScreen = false
    @State private var selectedGroupId: String?
    @State private var selectedGroupName: String?

    var body: some View {
        VStack {
            WoundLocationPickerView(
                selectedRegion: $selectedRegion,
                onConfirm: { region in
                    selectedRegion = region

                    if patient != nil {
                        // show group picker if patient exists
                        showNextScreen = true
                    } else {
                        // skip group picker if fast flow
                        selectedGroupId = "fast-capture"
                        selectedGroupName = "Fast Capture"
                        showNextScreen = true
                    }
                }
            )

            if selectedRegion != nil {
                Button(action: {
                    if patient != nil {
                        showNextScreen = true
                    } else {
                        selectedGroupId = "fast-capture"
                        selectedGroupName = "Fast Capture"
                        showNextScreen = true
                    }
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
        .navigationDestination(isPresented: $showNextScreen) {
            if let region = selectedRegion {
                if let patient = patient, selectedGroupId == nil {
                    WoundGroupPickerView(patient: patient) { groupId, groupName in
                        self.selectedGroupId = groupId
                        self.selectedGroupName = groupName
                        self.showNextScreen = true
                    }
                } else if let groupId = selectedGroupId,
                          let groupName = selectedGroupName {
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
