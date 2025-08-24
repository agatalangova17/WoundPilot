import SwiftUI

struct SharingView: View {
    @ObservedObject var langManager = LocalizationManager.shared  // re-render on language switch

    @ScaledMetric(relativeTo: .title3) private var cardRadius: CGFloat = 14
    @ScaledMetric(relativeTo: .title3) private var rowHeight: CGFloat = 64

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // Subtle header (ONLY subtitle; title lives in the nav bar)
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Color.blue.opacity(0.12)).frame(width: 32, height: 32)
                            Image(systemName: "person.2.wave.2.fill")
                                .foregroundColor(.blue)
                                .imageScale(.medium)
                        }
                        Text(LocalizedStrings.caseSharingHeaderSubtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Action rows
                    VStack(spacing: 12) {

                        NavigationLink { ShareCaseView() } label: {
                            ShareActionRowCard(
                                icon: "paperplane.fill",
                                tint: .blue,
                                title: LocalizedStrings.shareNewCaseTitle,
                                subtitle: LocalizedStrings.shareNewCaseSubtitle,
                                radius: cardRadius,
                                height: rowHeight
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        NavigationLink { ReceivedCasesView() } label: {
                            ShareActionRowCard(
                                icon: "tray.and.arrow.down.fill",
                                tint: .green,
                                title: LocalizedStrings.viewReceivedCasesTitle,
                                subtitle: LocalizedStrings.viewReceivedCasesSubtitle,
                                radius: cardRadius,
                                height: rowHeight
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 12)
            }
            .navigationTitle(LocalizedStrings.sharingTab)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct ShareActionRowCard: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let radius: CGFloat
    let height: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.15))
                Image(systemName: icon).foregroundColor(tint)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .imageScale(.small)
        }
        .padding(14)
        .frame(height: height)
        .background(shape.fill(Color(.secondarySystemBackground)))
        .overlay(shape.stroke(Color.black.opacity(0.05), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
        .contentShape(shape)
    }
}
