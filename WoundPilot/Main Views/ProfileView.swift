import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var dateJoined: String = ""
    @Environment(\.dismiss) var dismiss
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // MARK: - Avatar & Title
                VStack(spacing: 8) {
                    Image(systemName: "person.text.rectangle.fill") // or any option above
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.primaryBlue)

                    Text("Your Profile")
                        .font(.title2.bold())
                }
                .padding(.top)

                // MARK: - Info Cards
                VStack(spacing: 12) {
                    infoCard(icon: "person.fill", label: "Full Name", value: fullName)
                    infoCard(icon: "envelope.fill", label: "Email", value: email)
                    infoCard(icon: "calendar", label: "Joined", value: dateJoined)
                }
                .padding(.horizontal)

                // MARK: - Contact Support
                Button {
                    // Action for support
                    if let url = URL(string: "mailto:support@woundpilot.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Contact Support", systemImage: "questionmark.circle")
                        .font(.body.bold())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentBlue.opacity(0.1))
                        .foregroundColor(.accentBlue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // MARK: - Log Out
                Button(role: .destructive) {
                    try? Auth.auth().signOut()
                    isUserLoggedIn = false
                    dismiss()
                } label: {
                    Text("Log Out")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadUserInfo)
        }
    }

    // MARK: - Info Card
    func infoCard(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentBlue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    // MARK: - Firebase Fetch
    func loadUserInfo() {
        if let user = Auth.auth().currentUser {
            self.email = user.email ?? ""
            self.fullName = user.displayName ?? "Unknown"
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            self.dateJoined = formatter.string(from: user.metadata.creationDate ?? Date())
        }
    }
}

