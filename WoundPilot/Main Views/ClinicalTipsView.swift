import SwiftUI

struct ClinicalTip: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct ClinicalTipsView: View {
    let tips: [ClinicalTip] = [
        ClinicalTip(title: "Moisture Balance",
                    description: "Keeping wounds moist—not wet—accelerates epithelialization and tissue repair.",
                    icon: "drop.fill",
                    color: .blue),

        ClinicalTip(title: "Edge Assessment",
                    description: "Monitor wound edges for maceration, undermining, or rolled borders to guide interventions.",
                    icon: "scope",
                    color: .purple),

        ClinicalTip(title: "TIME Framework",
                    description: "Apply the TIME approach: Tissue management, Inflammation/Infection control, Moisture balance, and Edge advancement.",
                    icon: "puzzlepiece.fill",
                    color: .green),

        ClinicalTip(title: "Granulation Tissue",
                    description: "Bright red, bumpy tissue in the wound bed is a positive sign of healing progress.",
                    icon: "heart.fill",
                    color: .red),

        ClinicalTip(title: "Infection Indicators",
                    description: "Look for increased pain, redness, warmth, swelling, or odor — signs that may require antimicrobial therapy.",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange),

        ClinicalTip(title: "Size Monitoring",
                    description: "Document wound dimensions regularly to track healing trajectory and adjust treatment.",
                    icon: "ruler.fill",
                    color: .indigo),

        ClinicalTip(title: "Epithelialization",
                    description: "Thin, pale pink tissue covering the wound indicates closure is approaching.",
                    icon: "checkmark.seal.fill",
                    color: .teal)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Clinical Tips")
                    .font(.largeTitle.bold())
                    .padding(.top, 16)

                Text("Best-practice wound care guidelines for clinicians. These tips are rooted in evidence and regularly reviewed.")
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
