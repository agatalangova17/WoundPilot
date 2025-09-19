import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @ObservedObject var langManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var message = ""
    @State private var error = ""

    private var isEmailValid: Bool {
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.contains("@") && t.contains(".")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Email field (no extra label)
                TextField(LocalizedStrings.enterEmailPlaceholder, text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .submitLabel(.send)
                    .onSubmit(sendPasswordReset)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(error.isEmpty ? Color.accentBlue.opacity(0.20) : .red.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Feedback
                if !error.isEmpty {
                    Text(error).wpCaption().foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !message.isEmpty {
                    Text(message).wpCaption().foregroundColor(.green)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Primary action (solid blue, no gradient)
                Button(LocalizedStrings.sendResetEmailButton) {
                    sendPasswordReset()
                }
                .buttonStyle(WPSolidPrimaryButtonStyle_Forgot())
                .disabled(!isEmailValid)
                .opacity(isEmailValid ? 1 : 0.6)
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(LocalizedStrings.resetPasswordTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChangeCompat(email) {
            error = ""; message = ""
        }
    }

    private func sendPasswordReset() {
        error = ""; message = ""

        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = LocalizedStrings.enterEmailError
            return
        }

        Auth.auth().sendPasswordReset(withEmail: trimmed) { err in
            if let err = err {
                error = err.localizedDescription
            } else {
                message = LocalizedStrings.resetEmailSentMessage
            }
        }
    }
}

// MARK: - Solid Blue Primary Button (local copy)
private struct WPSolidPrimaryButtonStyle_Forgot: ButtonStyle {
    @ScaledMetric private var height: CGFloat = 52
    @ScaledMetric private var corner: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.primaryBlue) // solid brand blue
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: Color.primaryBlue.opacity(configuration.isPressed ? 0.10 : 0.18),
                    radius: 10, y: 6)
            .animation(.spring(response: 0.25, dampingFraction: 0.85),
                       value: configuration.isPressed)
    }
}
