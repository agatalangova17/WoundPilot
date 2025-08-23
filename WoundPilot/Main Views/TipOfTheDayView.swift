import SwiftUI

struct TipOfTheDayView: View {
    let tip: String
    @State private var isExpanded = false

    // Re-render when the language changes
    @ObservedObject var langManager = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)

                // Localized title
                Text(LocalizedStrings.tipOfTheDay)
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                Text(tip)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}
