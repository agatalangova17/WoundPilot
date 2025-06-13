import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @Binding var isUserLoggedIn: Bool
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
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                
                // Name Input
                TextField("Full Name", text: $name)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                
            
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
                HStack(alignment: .center, spacing: 8) {
                    Button(action: { agreedToTerms.toggle() }) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreedToTerms ? .blue : .gray)
                    }
                    .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 0) {
                            Text("I agree to the ")
                                .font(.footnote)
                            Text("Terms & Conditions")
                                .underline()
                                .foregroundColor(.blue)
                                .font(.footnote)
                                .onTapGesture { showTerms = true }
                        }

                        HStack(spacing: 0) {
                            Text("and ")
                                .font(.footnote)
                            Text("Privacy Policy")
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
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(agreedToTerms ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!agreedToTerms)
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
        guard !name.isEmpty else {
            errorMessage = "Full name is required."
            return
        }
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        guard agreedToTerms else {
            errorMessage = "You must agree to the Terms and Privacy Policy."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
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
                        errorMessage = "Error saving agreement: \(err.localizedDescription)"
                    } else {
                        isUserLoggedIn = true
                    }
                }
            }
        }
    }}
