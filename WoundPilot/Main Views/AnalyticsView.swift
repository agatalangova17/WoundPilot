import SwiftUI
import FirebaseFirestore

enum TimeRange: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case allTime = "All Time"
}

struct AnalyticsView: View {
    @State private var timeRange: TimeRange = .allTime
    @State private var patientCount: Int? = nil
    @State private var woundCount: Int? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Time Range Picker
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // MARK: - Analytics Cards
                    VStack(spacing: 16) {
                        AnalyticsCard(
                            title: "Total Patients",
                            value: patientCount.map(String.init) ?? "42",
                            icon: "person.2.fill",
                            iconColor: .primaryBlue,
                            bgColor: Color(.systemGray6)
                        )

                        AnalyticsCard(
                            title: "Total Wound Captures",
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
            .navigationTitle("Analytics")
            .onAppear {
                fetchAnalyticsData()
            }
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
