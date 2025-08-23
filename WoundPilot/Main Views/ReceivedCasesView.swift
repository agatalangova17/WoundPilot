import SwiftUI

struct ReceivedCasesView: View {
    @ObservedObject var langManager = LocalizationManager.shared

    // Dummy data — replace with Firebase fetch later
    let receivedCases: [(patient: String, senderEmail: String)] = [
        ("Patient A", "dr.john@example.com"),
        ("Patient B", "dr.smith@example.com"),
        ("Patient C", "nurse.lee@example.com")
    ]

    var body: some View {
        List {
            if receivedCases.isEmpty {
                Text(LocalizedStrings.noReceivedCases)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(receivedCases, id: \.patient) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.patient)
                            .font(.headline)
                        Text(LocalizedStrings.receivedFrom(item.senderEmail))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizedStrings.receivedCasesTitle)
    }
}
