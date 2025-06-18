import SwiftUI

struct ImageConfirmationView: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Confirm Wound Photo")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal)

            Text("Is this photo clear and accurate?")
                .foregroundColor(.gray)
                .font(.subheadline)

            HStack(spacing: 20) {
                Button(action: onRetake) {
                    Label("Retake", systemImage: "arrow.counterclockwise")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .disabled(isLoading)

                Button(action: {
                    isLoading = true
                    onConfirm()
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Label("Use Photo", systemImage: "checkmark.circle.fill")
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}
