import SwiftUI

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        TabView {
            // 1. Dashboard Tab
            HomeView(isUserLoggedIn: $isUserLoggedIn)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            // 2. Analytics Tab (placeholder for now)
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

            SharingView()
                .tabItem {
                    Label("Sharing", systemImage: "person.2.circle")
                }
        }
    }
}
