import SwiftUI
import FirebaseCore

@main
struct WoundPilotApp: App {
    // Initialize Firebase when the app starts
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
