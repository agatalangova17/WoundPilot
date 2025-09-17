import SwiftUI

struct ImageConfirmationView: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void

    @ObservedObject var langManager = LocalizationManager.shared
    @State private var isLoading = false

    // Guide collapsed by default
    @State private var showGuide = false

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

            // ---- GUIDE at the bottom (collapsed by default) ----
            VStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showGuide.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.mint)
                        Text(LocalizedStrings.photoGuideTitle) // localized
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(showGuide ? 90 : 0))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showGuide {
                    GuideCard()
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.bottom, 4)

            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Guide Card
private struct GuideCard: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        VStack(alignment: .leading, spacing: 10) {
            GuideRow(icon: "camera.aperture", text: LocalizedStrings.photoGuideTipCaptureCenter)
            GuideRow(icon: "ruler",              text: LocalizedStrings.photoGuideTipAddScale)
            GuideRow(icon: "sun.max",            text: LocalizedStrings.photoGuideTipLighting)
            GuideRow(icon: "deskclock",          text: LocalizedStrings.photoGuideTipTopDown)
            GuideRow(icon: "paintbrush.pointed", text: LocalizedStrings.photoGuideTipCleanLens)
            GuideRow(icon: "exclamationmark.triangle", text: LocalizedStrings.photoGuideTipRemoveObstructions)
        }
        .padding(14)
        .background(shape.fill(Color(.secondarySystemBackground)))
        .overlay(shape.stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
    }
}

private struct GuideRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .imageScale(.medium)
                .frame(width: 18)
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
