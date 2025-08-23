import SwiftUI

struct PreparingAnalysisView: View {
    let image: UIImage
    let location: String
    let patient: Patient?
    let woundGroupId: String
    let woundGroupName: String

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var savedWound: Wound?
    @State private var navigate = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView(LocalizedStrings.analyzingSizeProgress)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $navigate) {
            if let wound = savedWound {
                SizeAnalysisView(wound: wound)
            }
        }
        .onAppear {
            print("🟦 PreparingAnalysisView appeared")
            saveWound()

            // Optional: timeout fallback (debug only)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if !navigate {
                    print("🟨 Timeout: saveWound did not complete in 5 seconds.")
                }
            }
        }
    }

    private func saveWound() {
        print("🔵 saveWound() started")

        WoundService.shared.saveWound(
            image: image,
            location: location,
            patient: patient,
            woundGroupId: woundGroupId,
            woundGroupName: woundGroupName
        ) { result in
            DispatchQueue.main.async {
                print("🟢 saveWound completion handler called")

                switch result {
                case .success(let wound):
                    print("✅ Wound saved successfully: \(wound.id)")
                    self.savedWound = wound
                    self.navigate = true

                case .failure(let error):
                    print("❌ Wound save failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
