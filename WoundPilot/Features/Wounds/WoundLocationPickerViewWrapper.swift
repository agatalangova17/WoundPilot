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
                Button("Confirm Location") {
                    navigateToPrep = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
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
