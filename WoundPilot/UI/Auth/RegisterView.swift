import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var langManager = LocalizationManager.shared

    // Inputs
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false

    // UI
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @FocusState private var focused: Field?
    private enum Field { case name, email, password, confirm }

    // Feedback
    @State private var errorMessage = ""

    // MARK: - Validation
    private var isNameValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var isEmailValid: Bool {
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.contains("@") && t.contains(".")
    }
    private var isPasswordStrong: Bool {
        let pattern = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }
    private var doPasswordsMatch: Bool { !confirmPassword.isEmpty && confirmPassword == password }
    private var formValid: Bool { isNameValid && isEmailValid && isPasswordStrong && doPasswordsMatch && agreedToTerms }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Name
                TextField(LocalizedStrings.fullNameLabel, text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .submitLabel(.next)
                    .focused($focused, equals: .name)
                    .onSubmit { focused = .email }
                    .fieldStyle(isError: !isNameValid && !name.isEmpty)

                // Email
                TextField(LocalizedStrings.email, text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .submitLabel(.next)
                    .focused($focused, equals: .email)
                    .onSubmit { focused = .password }
                    .fieldStyle(isError: !isEmailValid && !email.isEmpty)

                // Password
                PasswordField(
                    placeholder: LocalizedStrings.password,
                    text: $password,
                    isVisible: $showPassword,
                    submitLabel: .next,
                    onSubmit: { focused = .confirm }
                )
                .focused($focused, equals: .password)
                .fieldStyle(isError: !isPasswordStrong && !password.isEmpty)

                // Confirm Password
                PasswordField(
                    placeholder: LocalizedStrings.confirmPassword,
                    text: $confirmPassword,
                    isVisible: $showConfirmPassword,
                    submitLabel: .go,
                    onSubmit: registerUser
                )
                .focused($focused, equals: .confirm)
                .fieldStyle(isError: !doPasswordsMatch && !confirmPassword.isEmpty)

                // Inline hints (caption style)
                if !isPasswordStrong && !password.isEmpty {
                    Text(LocalizedStrings.passwordRequirement)
                        .wpCaption().foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !doPasswordsMatch && !confirmPassword.isEmpty {
                    Text(LocalizedStrings.passwordsDontMatch)
                        .wpCaption().foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Terms & Privacy
                TermsRow(
                    agreed: $agreedToTerms,
                    onTerms: { showTerms = true },
                    onPrivacy: { showPrivacy = true }
                )

                // Global error
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .wpCaption()
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Register (solid blue, no gradient)
                Button(LocalizedStrings.registerButton) { registerUser() }
                    .buttonStyle(WPSolidPrimaryButtonStyle_Register())
                    .disabled(!formValid)
                    .opacity(formValid ? 1 : 0.6)
                    .padding(.top, 4)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(LocalizedStrings.registerTitle)
        .navigationBarTitleDisplayMode(.inline)
        // Clear global error while editing
        .onChangeCompat(name) { errorMessage = "" }
        .onChangeCompat(email) { errorMessage = "" }
        .onChangeCompat(password) { errorMessage = "" }
        .onChangeCompat(confirmPassword) { errorMessage = "" }
        // Sheets
        .sheet(isPresented: $showTerms) { TermsAndConditionsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    // MARK: - Actions
    private func registerUser() {
        errorMessage = ""

        guard formValid else {
            if !isNameValid { errorMessage = LocalizedStrings.fullNameRequired; return }
            if !isEmailValid { errorMessage = LocalizedStrings.invalidEmail; return }
            if !isPasswordStrong { errorMessage = LocalizedStrings.passwordRequirement; return }
            if !doPasswordsMatch { errorMessage = LocalizedStrings.passwordsDontMatch; return }
            if !agreedToTerms { errorMessage = LocalizedStrings.mustAgreeToTerms; return }
            return
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Auth.auth().createUser(withEmail: trimmedEmail, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            guard let user = result?.user else { return }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "email": trimmedEmail,
                "name": name,
                "agreedToTerms": true,
                "termsVersion": "1.0",
                "agreedAt": Timestamp(date: Date())
            ]) { err in
                if let err = err {
                    errorMessage = LocalizedStrings.savingAgreementError("\(err.localizedDescription)")
                } else {
                    isUserLoggedIn = true
                }
            }
        }
    }
}

// MARK: - Reusable pieces

/// Compact password field with eye toggle
private struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(.password)
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.body)
                    .padding(.trailing, 12)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
    }
}

// Uniform field container style (+ error state)
private struct FieldStyle: ViewModifier {
    let isError: Bool
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isError ? .red.opacity(0.5) : Color.accentBlue.opacity(0.20), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
private extension View {
    func fieldStyle(isError: Bool = false) -> some View {
        modifier(FieldStyle(isError: isError))
    }
}

/// Terms & Privacy row with a checkbox-like toggle and tappable links
private struct TermsRow: View {
    @Binding var agreed: Bool
    var onTerms: () -> Void
    var onPrivacy: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Button(action: { agreed.toggle() }) {
                Image(systemName: agreed ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(agreed ? .accentBlue : .secondary)
                    .accessibilityLabel(agreed ? "Agreed to terms" : "Agree to terms")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(LocalizedStrings.iAgreePrefix).wpCaption()
                    Button(LocalizedStrings.termsLinkText, action: onTerms)
                        .buttonStyle(.plain)
                        .tint(.accentBlue)
                        .wpCaption()
                        .underline()
                }
                HStack(spacing: 4) {
                    Text(LocalizedStrings.andPrefix).wpCaption()
                    Button(LocalizedStrings.privacyLinkText, action: onPrivacy)
                        .buttonStyle(.plain)
                        .tint(.accentBlue)
                        .wpCaption()
                        .underline()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

// MARK: - Solid Blue Primary Button (local copy to avoid cross-file conflicts)
private struct WPSolidPrimaryButtonStyle_Register: ButtonStyle {
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
