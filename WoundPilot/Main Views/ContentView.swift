import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil

    var body: some View {
        if isUserLoggedIn {
            MainTabView(isUserLoggedIn: $isUserLoggedIn)
        } else {
            WelcomeView(isUserLoggedIn: $isUserLoggedIn)
        }
    }
}
