import SwiftUI
import FirebaseAuth

struct RegisterView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Email Input
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // Password Input
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // Confirm Password
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Register Button
                Button(action: registerUser) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Register User with Firebase
    private func registerUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                isUserLoggedIn = true
            }
        }
    }
}
