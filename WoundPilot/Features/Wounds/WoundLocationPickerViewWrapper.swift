import SwiftUI

struct WoundLocationPickerViewWrapper: View {
    let image: UIImage
    let patient: Patient?
    let woundGroupId: String
    let woundGroupName: String

    @State private var selectedRegion: String?
    @State private var navigateToPrep = false

    var body: some View {
        VStack {
            WoundLocationPickerView(
                selectedRegion: $selectedRegion,
                onConfirm: { region in
                    selectedRegion = region
                    navigateToPrep = true
                }
            )

            if selectedRegion != nil {
                Button(action: {
                    navigateToPrep = true
                }) {
                    VStack(spacing: 3) {

                        Text("Confirm")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
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
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }
        }
        .navigationDestination(isPresented: $navigateToPrep) {
            if let region = selectedRegion {
                PreparingAnalysisView(
                    image: image,
                    location: region,
                    patient: patient,
                    woundGroupId: woundGroupId,
                    woundGroupName: woundGroupName
                )
            }
        }
    }
}
