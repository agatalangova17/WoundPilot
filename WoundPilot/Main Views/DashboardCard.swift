import SwiftUI

enum DashboardCardLayout {
    case large
    case square
}

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let bgColor: Color
    var layout: DashboardCardLayout = .square
    var textColor: Color = .primary
    var showsChevron: Bool = false

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in
                            isPressed = false
                            lightHaptic()
                        }
                )

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textColor.opacity(0.4))
                    .padding(10)
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: layout == .large ? 12 : 10) {
            Text(title)
                .font(.system(size: layout == .large ? 18 : 15, weight: .semibold))
                .foregroundColor(textColor)

            Text(subtitle)
                .font(.system(size: layout == .large ? 14 : 13))
                .foregroundColor(textColor.opacity(0.65))

            Spacer()

            HStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(textColor.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(textColor)
                }
            }
        }
        .padding()
        .frame(
            width: layout == .square ? (UIScreen.main.bounds.width - 48) / 2 : nil,
            height: layout == .square ? 150 : 160,
            alignment: .topLeading
        )
        .background(bgColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 2)
    }

    private func lightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
