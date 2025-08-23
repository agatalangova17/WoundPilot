import SwiftUI

struct ClinicalTip: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct ClinicalTipsView: View {
    @ObservedObject var langManager = LocalizationManager.shared  // react to language switches

    // Recompute on language change
    var tips: [ClinicalTip] {
        [
            ClinicalTip(
                title: LocalizedStrings.tipMoistureTitle,
                description: LocalizedStrings.tipMoistureDesc,
                icon: "drop.fill",
                color: .blue
            ),
            ClinicalTip(
                title: LocalizedStrings.tipEdgeTitle,
                description: LocalizedStrings.tipEdgeDesc,
                icon: "scope",
                color: .purple
            ),
            ClinicalTip(
                title: LocalizedStrings.tipTimeTitle,
                description: LocalizedStrings.tipTimeDesc,
                icon: "puzzlepiece.fill",
                color: .green
            ),
            ClinicalTip(
                title: LocalizedStrings.tipGranulationTitle,
                description: LocalizedStrings.tipGranulationDesc,
                icon: "heart.fill",
                color: .red
            ),
            ClinicalTip(
                title: LocalizedStrings.tipInfectionTitle,
                description: LocalizedStrings.tipInfectionDesc,
                icon: "exclamationmark.triangle.fill",
                color: .orange
            ),
            ClinicalTip(
                title: LocalizedStrings.tipSizeTitle,
                description: LocalizedStrings.tipSizeDesc,
                icon: "ruler.fill",
                color: .indigo
            ),
            ClinicalTip(
                title: LocalizedStrings.tipEpithelialTitle,
                description: LocalizedStrings.tipEpithelialDesc,
                icon: "checkmark.seal.fill",
                color: .teal
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(LocalizedStrings.clinicalTipsTitle)
                    .font(.largeTitle.bold())
                    .padding(.top, 16)

                Text(LocalizedStrings.clinicalTipsSubtitle)
                    .font(.body)
                    .foregroundColor(.secondary)

                ForEach(tips) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tip.icon)
                            .font(.system(size: 26))
                            .foregroundColor(tip.color)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title)
                                .font(.headline)

                            Text(tip.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
