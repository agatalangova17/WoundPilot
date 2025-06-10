import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    
    // Real-time validation
    @State private var emailError = ""
    @State private var passwordError = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Email field
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
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
            SecureField("Password", text: $password)
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
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            // Forgot password button (will be updated later to use a view)
            NavigationLink(destination: ForgotPasswordView()) {
                Text("Forgot Password?")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

            // Register link
            NavigationLink(destination: RegisterView(isUserLoggedIn: $isUserLoggedIn)) {
                Text("No account? Register here")
                    .foregroundColor(.blue)
                    .font(.footnote)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Validation Functions
    private func validateEmail(_ email: String) {
        if !email.contains("@") || !email.contains(".") {
            emailError = "Invalid email address."
        } else {
            emailError = ""
        }
    }

    private func validatePassword() {
        let passwordRegex = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$"#
        if !NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password) {
            passwordError = "Must be 8+ characters with uppercase, lowercase, number & symbol."
        } else {
            passwordError = ""
        }
    }

    // MARK: - Firebase Actions
    private func loginUser() {
        guard emailError.isEmpty, passwordError.isEmpty else {
            errorMessage = "Fix validation errors first."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                isUserLoggedIn = true
            }
        }
    }
}
