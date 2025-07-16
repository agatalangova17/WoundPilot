import SwiftUI

struct PrepareWoundAnalysisView: View {
    let image: UIImage
    let patient: Patient?

    @State private var proceedToLocation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 28) {
                    // MARK: - Avatar + Title + Steps
                    VStack(spacing: 16) {
                        Image(systemName: "stethoscope.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.accentBlue)
                            .padding(.top, 8)

                        Text("You're just 3 steps away from an AI-powered wound evaluation.")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        stepList
                    }

                    // MARK: - Continue Button
                    Button {
                        proceedToLocation = true
                    } label: {
                        Text("Continue")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentBlue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $proceedToLocation) {
                WoundLocationPickerViewWrapper(
                    image: image,
                    patient: patient
                )
            }
        }
    }

    // MARK: - Step List
    private var stepList: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepRow("mappin.and.ellipse", "Step 1", "Select wound location")
            stepRow("doc.text.magnifyingglass", "Step 2", "Answer clinical questions")
            stepRow("brain.head.profile", "Step 3", "AI analyzes wound")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func stepRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentBlue)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.subheadline).foregroundColor(.gray)
            }
        }
    }
}
