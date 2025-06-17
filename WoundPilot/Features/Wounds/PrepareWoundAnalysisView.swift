import SwiftUI

struct PrepareWoundAnalysisView: View {
    let image: UIImage
    let patient: Patient?
    let woundGroupId: String
    let woundGroupName: String

    @State private var proceedToLocation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Wound Image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 4)
                    .padding(.top)

                // Title & Subtitle
                VStack(spacing: 8) {
                    Text("Prepare Wound Analysis")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("You're just 3 steps away from an AI-powered wound evaluation.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Step List
                VStack(alignment: .leading, spacing: 12) {
                    stepRow(icon: "mappin.and.ellipse", title: "Step 1", detail: "Select wound location")
                    stepRow(icon: "doc.text.magnifyingglass", title: "Step 2", detail: "Answer quick clinical questions")
                    stepRow(icon: "brain.head.profile", title: "Step 3", detail: "AI analyzes wound")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Continue Button
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
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $proceedToLocation) {
                WoundLocationPickerViewWrapper(
                    image: image,
                    patient: patient,
                    woundGroupId: woundGroupId,
                    woundGroupName: woundGroupName
                )
            }
        }
    }

    // MARK: - Step UI
    private func stepRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentBlue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}
