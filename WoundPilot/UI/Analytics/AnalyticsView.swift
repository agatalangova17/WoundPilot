import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum TimeRange: String, CaseIterable {
    case today
    case thisWeek
    case allTime

    var title: String {
        switch self {
        case .today:    return LocalizedStrings.timeToday
        case .thisWeek: return LocalizedStrings.timeThisWeek
        case .allTime:  return LocalizedStrings.timeAllTime
        }
    }
}

struct AnalyticsView: View {
    @ObservedObject var langManager = LocalizationManager.shared
    @State private var timeRange: TimeRange = .allTime
    @State private var patientCount: Int?
    @State private var woundCount: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Time range picker
                    Picker(LocalizedStrings.timeRangeLabel, selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Cards
                    VStack(spacing: 16) {
                        AnalyticsCard(
                            title: LocalizedStrings.totalPatients,
                            value: patientCount.map(String.init) ?? "—",
                            icon: "person.2.fill",
                            iconColor: .primaryBlue,
                            bgColor: Color(.systemGray6)
                        )

                        AnalyticsCard(
                            title: LocalizedStrings.totalWoundCaptures,
                            value: woundCount.map(String.init) ?? "—",
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
            // iOS 16/17-safe change listener
            .onChangeCompat(timeRange) { fetchAnalyticsData() }
        }
    }

    // MARK: - Firestore (per-user + time range)
    func fetchAnalyticsData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // derive start date
        let now = Date()
        let startDate: Date? = {
            switch timeRange {
            case .allTime:  return nil
            case .today:    return Calendar.current.startOfDay(for: now)
            case .thisWeek:
                let cal = Calendar.current
                return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))
            }
        }()

        // Patients
        var patientsQuery: Query = db.collection("users").document(uid).collection("patients")
        if let start = startDate {
            patientsQuery = patientsQuery.whereField("createdAt", isGreaterThanOrEqualTo: start)
        }
        patientsQuery.count.getAggregation(source: .server) { snap, _ in
            // Handle NSNumber or Int64, whichever the SDK returns
            let anyCount: Any? = snap?.count
            let count: Int =
                (anyCount as? NSNumber)?.intValue ??
                (anyCount as? Int).map { $0 } ??
                (anyCount as? Int64).map { Int(truncatingIfNeeded: $0) } ?? 0

            DispatchQueue.main.async { self.patientCount = count }
        }

        // Wounds
        var woundsQuery: Query = db.collectionGroup("wounds").whereField("ownerUID", isEqualTo: uid)
        if let start = startDate {
            woundsQuery = woundsQuery.whereField("createdAt", isGreaterThanOrEqualTo: start)
        }
        woundsQuery.count.getAggregation(source: .server) { snap, _ in
            let anyCount: Any? = snap?.count
            let count: Int =
                (anyCount as? NSNumber)?.intValue ??
                (anyCount as? Int).map { $0 } ??
                (anyCount as? Int64).map { Int(truncatingIfNeeded: $0) } ?? 0

            DispatchQueue.main.async { self.woundCount = count }
        }
    }
    }


private struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let bgColor: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(bgColor)
        .cornerRadius(16)
    }
}
