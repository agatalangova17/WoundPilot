import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)

                Text("Your Profile")
                    .font(.title2)
                    .fontWeight(.semibold)

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
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}
