import SwiftUI

struct SharingView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Case Sharing")
                    .font(.title2.bold())

                Text("Easily share patient cases and wound data with colleagues for a second opinion or remote collaboration.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                VStack(spacing: 16) {
                    NavigationLink(destination: ShareCaseView()) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                            Text("Share a New Case")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }

                    NavigationLink(destination: ReceivedCasesView()) {
                        HStack {
                            Image(systemName: "tray.full.fill")
                                .foregroundColor(.green)
                            Text("View Received Cases")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Sharing")
        }
    }
}

// Placeholder destination views
struct ShareCaseView: View {
    var body: some View {
        Text("Share Case Flow")
            .navigationTitle("Share Case")
    }
}

struct ReceivedCasesView: View {
    var body: some View {
        Text("Received Shared Cases")
            .navigationTitle("Received Cases")
    }
}

#Preview {
    SharingView()
}


