import SwiftUI
import FirebaseAuth

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    
    @State private var emailError = ""
    @State private var passwordError = ""

    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    private enum Field { case email, password }

    // Derived
    private var isEmailValid: Bool {
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.contains("@") && t.contains(".")
    }
    private var isPasswordValid: Bool {
        let pattern = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }
    private var formValid: Bool { isEmailValid && isPasswordValid }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Email
                TextField(LocalizedStrings.email, text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(emailError.isEmpty ? Color.accentBlue.opacity(0.20) : .red.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if !emailError.isEmpty {
                    Text(emailError).wpCaption().foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Password with eye toggle
                ZStack(alignment: .trailing) {
                    Group {
                        if showPassword {
                            TextField(LocalizedStrings.password, text: $password)
                        } else {
                            SecureField(LocalizedStrings.password, text: $password)
                        }
                    }
                    .textContentType(.password)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit { loginUser() }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(passwordError.isEmpty ? Color.accentBlue.opacity(0.20) : .red.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.body)
                            .padding(.trailing, 12)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }

                if !passwordError.isEmpty {
                    Text(passwordError).wpCaption().foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Global error
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .wpCaption()
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // Login (solid blue, no gradient)
                Button(LocalizedStrings.loginButton) { loginUser() }
                    .buttonStyle(WPSolidPrimaryButtonStyle())
                    .disabled(!formValid)
                    .opacity(formValid ? 1 : 0.6)
                    .padding(.top, 4)

                // Links — small, centered, true link style
                VStack(spacing: 8) {
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text(LocalizedStrings.forgotPassword).wpCaption()
                    }
                    .buttonStyle(.plain)
                    .tint(.accentBlue)

                    NavigationLink(destination: RegisterView(isUserLoggedIn: $isUserLoggedIn)) {
                        Text(LocalizedStrings.noAccountRegister).wpCaption()
                    }
                    .buttonStyle(.plain)
                    .tint(.accentBlue)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(LocalizedStrings.loginTitle)
        .navigationBarTitleDisplayMode(.inline)
        // Real-time validation (iOS 16/17 safe)
        .onChangeCompat(email) {
            errorMessage = ""
            emailError = isEmailValid ? "" : LocalizedStrings.invalidEmail
        }
        .onChangeCompat(password) {
            errorMessage = ""
            passwordError = isPasswordValid ? "" : LocalizedStrings.passwordRequirement
        }
    }

    // Actions
    private func loginUser() {
        emailError = isEmailValid ? "" : LocalizedStrings.invalidEmail
        passwordError = isPasswordValid ? "" : LocalizedStrings.passwordRequirement
        guard formValid else {
            errorMessage = LocalizedStrings.fixValidationFirst
            return
        }

        Auth.auth().signIn(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines),
                           password: password) { _, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                isUserLoggedIn = true
            }
        }
    }
}

// MARK: - Solid Blue Primary Button (shared style)
private struct WPSolidPrimaryButtonStyle: ButtonStyle {
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
