import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var message = ""
    @State private var error = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Enter your email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
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

            Button("Send Reset Email") {
                sendPasswordReset()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Back to Login") {
                presentationMode.wrappedValue.dismiss()
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
            error = "Please enter your email."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { err in
            if let err = err {
                error = err.localizedDescription
            } else {
                message = "Password reset email sent."
            }
        }
    }
}
