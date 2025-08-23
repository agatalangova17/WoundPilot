import SwiftUI

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var langManager = LocalizationManager.shared   // re-render on language change

    var body: some View {
        TabView {
            // 1) Dashboard
            HomeView(isUserLoggedIn: $isUserLoggedIn)
                .tabItem { Label(LocalizedStrings.dashboardTab, systemImage: "house.fill") }

            // 2) Analytics
            AnalyticsView()
                .tabItem { Label(LocalizedStrings.analyticsTab, systemImage: "chart.bar.fill") }

            // 3) Sharing
            SharingView()
                .tabItem { Label(LocalizedStrings.sharingTab, systemImage: "person.2.circle") }
        }
    }
}
