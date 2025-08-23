import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @ObservedObject var langManager = LocalizationManager.shared

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var message = ""
    @State private var error = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizedStrings.resetPasswordTitle)
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField(LocalizedStrings.enterEmailPlaceholder, text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            if !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.green)
                    .font(.caption)
            }

            Button(LocalizedStrings.sendResetEmailButton) {
                sendPasswordReset()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button(LocalizedStrings.backToLoginButton) {
                dismiss()
            }
            .foregroundColor(.blue)
            .font(.footnote)

            Spacer()
        }
        .padding()
    }

    private func sendPasswordReset() {
        error = ""
        message = ""

        guard !email.isEmpty else {
            error = LocalizedStrings.enterEmailError
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { err in
            if let err = err {
                // You can map Firebase error codes to localized messages later if you want.
                error = err.localizedDescription
            } else {
                message = LocalizedStrings.resetEmailSentMessage
            }
        }
    }
}
