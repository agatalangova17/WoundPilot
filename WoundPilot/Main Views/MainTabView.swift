import SwiftUI

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject private var langManager = LocalizationManager.shared

    var body: some View {
        TabView {
            // 1) Dashboard
            HomeView(isUserLoggedIn: $isUserLoggedIn)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(LocalizedStrings.dashboardTab)
                }
                .accessibilityLabel(LocalizedStrings.dashboardTab)

            // 2) Analytics
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text(LocalizedStrings.analyticsTab)
                }
                .accessibilityLabel(LocalizedStrings.analyticsTab)

            // 3) Sharing
            SharingView()
                .tabItem {
                    Image(systemName: "person.2.circle")
                    Text(LocalizedStrings.sharingTab)
                }
                .accessibilityLabel(LocalizedStrings.sharingTab)
        }
        // make the whole tab bar react to language change
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
    }
}
