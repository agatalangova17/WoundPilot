import SwiftUI

enum DashboardCardLayout {
    case large
    case square
}

struct DashboardCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let bgColor: Color
    var layout: DashboardCardLayout = .square
    var textColor: Color = .primary
    var showsChevron: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            switch layout {
            case .large:
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)

                    HStack(alignment: .center, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(iconColor.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(iconColor)
                        }

                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(textColor)

                        Spacer()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .background(bgColor)
                .cornerRadius(14)

            case .square:
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(textColor)
                        Spacer()
                    }

                    // Icon + Subtitle
                    HStack(alignment: .center, spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(iconColor.opacity(0.15))
                                .frame(width: 32, height: 32)

                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(iconColor)
                        }

                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(textColor)

                        Spacer()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                .background(bgColor)
                .cornerRadius(14)
            }

            // Chevron (top-right) for both layouts
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textColor)
                    .padding(10)
            }
        }
    }
}
