import SwiftUI

struct SharingView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Case Sharing")
                            .font(.title2.bold())
                        Text("Easily share patient cases and wound data with colleagues for a second opinion or remote collaboration.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // MARK: - Action Cards
                    VStack(spacing: 16) {

                        NavigationLink(destination: ShareCaseView()) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.blue)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Share a New Case")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Send patient data securely")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }

                        NavigationLink(destination: ReceivedCasesView()) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.15))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "tray.full.fill")
                                        .foregroundColor(.green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("View Received Cases")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Check referrals from colleagues")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Sharing")
        }
    }
}
