import SwiftUI

struct SharingView: View {
    @ObservedObject var langManager = LocalizationManager.shared  // re-render on language switch

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStrings.caseSharingHeaderTitle)
                            .font(.title2.bold())
                        Text(LocalizedStrings.caseSharingHeaderSubtitle)
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
                                    Text(LocalizedStrings.shareNewCaseTitle)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(LocalizedStrings.shareNewCaseSubtitle)
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
                                    Text(LocalizedStrings.viewReceivedCasesTitle)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(LocalizedStrings.viewReceivedCasesSubtitle)
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
            .navigationTitle(LocalizedStrings.sharingTab) // uses the same key you added for the tab title
        }
    }
}
