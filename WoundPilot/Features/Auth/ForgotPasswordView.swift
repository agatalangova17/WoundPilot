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

                // Primary action only
                Button(LocalizedStrings.sendResetEmailButton) {
                    sendPasswordReset()
                }
                .buttonStyle(WPPrimaryButtonStyle())
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
