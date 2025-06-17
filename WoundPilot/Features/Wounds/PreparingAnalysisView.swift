import SwiftUI

struct PreparingAnalysisView: View {
    let image: UIImage
    let location: String
    let patient: Patient?
    let woundGroupId: String
    let woundGroupName: String

    @State private var savedWound: Wound?
    @State private var navigate = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView("Analysing size…")
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
            saveWound()
        }
    }

    private func saveWound() {
        WoundService.shared.saveWound(
            image: image,
            location: location,
            patient: patient,
            woundGroupId: woundGroupId,
            woundGroupName: woundGroupName
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let wound):
                    self.savedWound = wound
                    self.navigate = true
                case .failure(let error):
                    self.error = error.localizedDescription
                    // Optional: show alert or fallback UI
                }
            }
        }
    }
}
