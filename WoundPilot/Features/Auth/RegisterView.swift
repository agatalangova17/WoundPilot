import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @Binding var isUserLoggedIn: Bool

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var agreedToTerms = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var name = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title
                Text(LocalizedStrings.registerTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Name
                TextField(LocalizedStrings.fullNameLabel, text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // Email
                TextField(LocalizedStrings.email, text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // Password
                SecureField(LocalizedStrings.password, text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // Confirm Password
                SecureField(LocalizedStrings.confirmPassword, text: $confirmPassword)
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

                // Terms & Privacy
                HStack(alignment: .center, spacing: 8) {
                    Button(action: { agreedToTerms.toggle() }) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreedToTerms ? .blue : .gray)
                    }
                    .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 0) {
                            Text(LocalizedStrings.iAgreePrefix)
                                .font(.footnote)
                            Text(LocalizedStrings.termsLinkText)
                                .underline()
                                .foregroundColor(.blue)
                                .font(.footnote)
                                .onTapGesture { showTerms = true }
                        }
                        HStack(spacing: 0) {
                            Text(LocalizedStrings.andPrefix)
                                .font(.footnote)
                            Text(LocalizedStrings.privacyLinkText)
                                .underline()
                                .foregroundColor(.blue)
                                .font(.footnote)
                                .onTapGesture { showPrivacy = true }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Register Button
                Button(action: registerUser) {
                    Text(LocalizedStrings.registerButton)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(agreedToTerms ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!agreedToTerms)

                Spacer(minLength: 0)
            }
            .padding()
            .sheet(isPresented: $showTerms) {
                TermsAndConditionsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
    }

    // MARK: - Register User with Firebase
    private func registerUser() {
        errorMessage = ""

        guard !name.isEmpty else {
            errorMessage = LocalizedStrings.fullNameRequired
            return
        }
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = LocalizedStrings.emailPasswordRequired
            return
        }
        guard password == confirmPassword else {
            errorMessage = LocalizedStrings.passwordsDontMatch
            return
        }
        guard agreedToTerms else {
            errorMessage = LocalizedStrings.mustAgreeToTerms
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                // (Optional) Map AuthErrorCode to friendlier localized messages later
                errorMessage = error.localizedDescription
                return
            }
            guard let user = result?.user else { return }

            // Store agreement in Firestore
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "email": email,
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
