import SwiftUI

struct ImageConfirmationView: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void

    @ObservedObject var langManager = LocalizationManager.shared
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 28) {
            // Title
            VStack(spacing: 8) {
                Text(LocalizedStrings.confirmWoundPhotoTitle)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(LocalizedStrings.confirmWoundPhotoSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)

            // Image Card
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .padding(8)
            }
            .frame(height: 260)
            .padding(.horizontal)

            // Buttons
            VStack(spacing: 16) {
                Button(action: onRetake) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text(LocalizedStrings.retakeButton)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(isLoading)

                Button {
                    guard !isLoading else { return }
                    isLoading = true
                    onConfirm()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(LocalizedStrings.usePhotoButton)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                .background(Color.accentBlue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}
