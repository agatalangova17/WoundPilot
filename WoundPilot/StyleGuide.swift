import SwiftUI

// ---------- TYPOGRAPHY (single source of truth) ----------
private struct WPH1: ViewModifier { // Big page titles
    func body(content: Content) -> some View {
        content.font(.largeTitle.bold()).foregroundColor(Color(.label))
    }
}
private struct WPH2: ViewModifier { // Section titles
    func body(content: Content) -> some View {
        content.font(.title2.weight(.semibold)).foregroundColor(Color(.label))
    }
}
private struct WPBody: ViewModifier { // Normal paragraphs
    func body(content: Content) -> some View {
        content.font(.body).foregroundColor(Color(.label))
    }
}
private struct WPCaption: ViewModifier { // Helper/notes
    func body(content: Content) -> some View {
        content.font(.callout).foregroundColor(Color(.secondaryLabel))
    }
}

// ---------- COMPONENTS ----------
struct WPPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(WPButtonText())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient(colors: [Color.primaryBlue, Color.accentBlue],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.primaryBlue.opacity(0.25), radius: 10, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
struct WPSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(WPButtonText())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentBlue.opacity(0.25), lineWidth: 1))
            .foregroundColor(.accentBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.accentBlue.opacity(0.15), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private struct WPButtonText: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.title3.weight(.semibold))
    }
}

struct WPCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentBlue.opacity(0.20), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// ---------- CONVENIENCE ----------
extension View {
    // Text styles
    func wpH1() -> some View     { modifier(WPH1()) }
    func wpH2() -> some View     { modifier(WPH2()) }
    func wpBody() -> some View   { modifier(WPBody()) }
    func wpCaption() -> some View { modifier(WPCaption()) }

    // Card styling
    func wpCard() -> some View   { modifier(WPCard()) }
}

// ---------- Brand colors (already in your project) ----------
extension Color {
    static let primaryBlue = Color(red: 0.20, green: 0.45, blue: 0.95)
    static let accentBlue  = Color(red: 0.25, green: 0.80, blue: 0.85)
    static let primaryText   = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
}
