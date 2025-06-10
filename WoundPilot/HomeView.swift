import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // App Title
                VStack(spacing: 8) {
                    Text("WoundPilot")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Your AI assistant for wound care.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Navigation Buttons
                VStack(spacing: 16) {
                    NavigationLink(destination: CaptureWoundView()) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Capture Wound")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    NavigationLink(destination: WoundListView()) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                            Text("View Wound History")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // Logout
                Button(action: {
                    do {
                        try Auth.auth().signOut()
                        isUserLoggedIn = false
                    } catch {
                        print("Logout failed: \(error)")
                    }
                }) {
                    Text("Log Out")
                        .foregroundColor(.red)
                        .padding(.top, 20)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
        }
    }
}
