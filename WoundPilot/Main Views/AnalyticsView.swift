import SwiftUI
import FirebaseFirestore

enum TimeRange: String, CaseIterable {
    case today
    case thisWeek
    case allTime
    // Localized label for the picker
    var title: String {
        switch self {
        case .today:    return LocalizedStrings.timeToday
        case .thisWeek: return LocalizedStrings.timeThisWeek
        case .allTime:  return LocalizedStrings.timeAllTime
        }
    }
}

struct AnalyticsView: View {
    @ObservedObject var langManager = LocalizationManager.shared   // <- make view react to language changes

    @State private var timeRange: TimeRange = .allTime
    @State private var patientCount: Int? = nil
    @State private var woundCount: Int? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Time Range Picker
                    Picker(LocalizedStrings.timeRangeLabel, selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // MARK: - Analytics Cards
                    VStack(spacing: 16) {
                        AnalyticsCard(
                            title: LocalizedStrings.totalPatients,
                            value: patientCount.map(String.init) ?? "42",
                            icon: "person.2.fill",
                            iconColor: .primaryBlue,
                            bgColor: Color(.systemGray6)
                        )

                        AnalyticsCard(
                            title: LocalizedStrings.totalWoundCaptures,
                            value: woundCount.map(String.init) ?? "128",
                            icon: "bandage.fill",
                            iconColor: .accentBlue,
                            bgColor: Color(.systemGray6)
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle(LocalizedStrings.analyticsTitle)
            .onAppear { fetchAnalyticsData() }
        }
    }

    // MARK: - Firestore Fetch (Dummy fallback)
    func fetchAnalyticsData() {
        let db = Firestore.firestore()

        db.collection("patients").getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                self.patientCount = docs.count
            }
        }

        db.collection("wounds").getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                self.woundCount = docs.count
            }
        }
    }
}
