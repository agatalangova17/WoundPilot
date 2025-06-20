import SwiftUI

struct ReceivedCasesView: View {
    // Dummy data — replace with Firebase fetch later
    let receivedCases = [
        ("Patient A", "Received from dr.john@example.com"),
        ("Patient B", "Received from dr.smith@example.com"),
        ("Patient C", "Received from nurse.lee@example.com")
    ]

    var body: some View {
        List {
            ForEach(receivedCases, id: \.0) { patient, sender in
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient)
                        .font(.headline)
                    Text(sender)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Received Cases")
    }
}
