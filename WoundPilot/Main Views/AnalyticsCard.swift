import SwiftUI
struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let bgColor: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(bgColor)
        .cornerRadius(16)
    }
}
