import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isUserLoggedIn: Bool

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    // Real-time validation
    @State private var emailError = ""
    @State private var passwordError = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizedStrings.loginTitle)
                .font(.largeTitle)
                .fontWeight(.bold)

            // Email field
            TextField(LocalizedStrings.email, text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .onChange(of: email) { _, newValue in
                    validateEmail(newValue)
                }

            if !emailError.isEmpty {
                Text(emailError)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Password field
            SecureField(LocalizedStrings.password, text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .onChange(of: password) { _, _ in
                    validatePassword()
                }

            if !passwordError.isEmpty {
                Text(passwordError)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Login button
            Button(action: loginUser) {
                Text(LocalizedStrings.loginButton)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            // Forgot password
            NavigationLink(destination: ForgotPasswordView()) {
                Text(LocalizedStrings.forgotPassword)
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

            // Register link
            NavigationLink(destination: RegisterView(isUserLoggedIn: $isUserLoggedIn)) {
                Text(LocalizedStrings.noAccountRegister)
                    .foregroundColor(.blue)
                    .font(.footnote)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Validation
    private func validateEmail(_ email: String) {
        if !email.contains("@") || !email.contains(".") {
            emailError = LocalizedStrings.invalidEmail
        } else {
            emailError = ""
        }
    }

    private func validatePassword() {
        let passwordRegex = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$"#
        if !NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password) {
            passwordError = LocalizedStrings.passwordRequirement
        } else {
            passwordError = ""
        }
    }

    // MARK: - Firebase Actions
    private func loginUser() {
        guard emailError.isEmpty, passwordError.isEmpty else {
            errorMessage = LocalizedStrings.fixValidationFirst
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                // (Optional) Map AuthErrorCode to friendlier localized strings later
                errorMessage = error.localizedDescription
            } else {
                isUserLoggedIn = true
            }
        }
    }
}
