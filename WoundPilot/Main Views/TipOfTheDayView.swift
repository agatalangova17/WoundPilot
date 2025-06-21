import SwiftUI

struct TipOfTheDayView: View {
    let tip: String

    var body: some View {
        ZStack(alignment: .leading) {
            // Clean white background with subtle border and shadow
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(Color.blue)

                    Text("Tip of the Day")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.blue)
                }

                Text(tip)
                    .font(.body)
                    .foregroundColor(.black.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 110)
    }
}
