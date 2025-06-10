import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to WoundPilot 👨‍⚕️")
                    .font(.title)

                NavigationLink(destination: CaptureWoundView()) {
                    Text("📸 Capture New Wound")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button("Logout") {
                    do {
                        try Auth.auth().signOut()
                        isUserLoggedIn = false
                    } catch {
                        print("Logout failed: \(error)")
                    }
                }
                .padding()
                .foregroundColor(.red)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}
