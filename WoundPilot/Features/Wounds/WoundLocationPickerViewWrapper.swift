import SwiftUI

struct BodyLocalizationView: View {
    let patient: Patient?            // nil in Quick Scan, non-nil in patient flow
    let woundGroupId: String?        // nil in Quick Scan
    let woundGroupName: String?      // optional label

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var selectedRegion: String?
    @State private var goNext = false

    var body: some View {
        VStack {
            WoundLocationPickerView(
                selectedRegion: $selectedRegion,
                onConfirm: { region in
                    selectedRegion = region
                    goNext = true
                }
            )

            if selectedRegion != nil {
                Button(LocalizedStrings.confirm) {
                    goNext = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .navigationTitle(LocalizedStrings.selectWoundLocationTitle)
        .navigationBarTitleDisplayMode(.inline)

        // ➜ move to image source / measurement
        .navigationDestination(isPresented: $goNext) {
            WoundImageSourceView(
                selectedPatient: patient,
                preselectedWoundGroupId: woundGroupId,
                preselectedLocation: selectedRegion
            )
        }
    }
}
