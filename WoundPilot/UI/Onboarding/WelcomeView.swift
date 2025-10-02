import SwiftUI
import UIKit

struct WelcomeView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var currentTab = 0
    @State private var displayedText = ""

    // Typewriter
    @State private var typingTask: Task<Void, Never>? = nil
    var fullAssistantText: String { LocalizedStrings.assistantTypingText }

    // Navigation to auth chooser (Login/Register)
    @State private var showAuthChooser = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                TabView(selection: $currentTab) {

                    // TAB 0: Language selection
                    LanguageSelectionPage(
                        title: LocalizedStrings.welcomeTitle,
                        onEnglish: {
                            Haptics.light()
                            langManager.setLanguage(.en)
                            withAnimation(.easeInOut) { currentTab = 1 }
                        },
                        onSlovak: {
                            Haptics.light()
                            langManager.setLanguage(.sk)
                            withAnimation(.easeInOut) { currentTab = 1 }
                        }
                    )
                    .tag(0)

                    // TAB 1: Assistant greeting + single CTA
                    AssistantGreetingPage(
                        appTitle: LocalizedStrings.appTitle,
                        subtitle: LocalizedStrings.appSubtitle,
                        introLine: LocalizedStrings.assistantIntroLine,
                        displayedText: $displayedText,
                        onAppearTyping: { typeWriterEffect() },
                        onDisappearTyping: { stopTyping() },
                        onContinue: { showAuthChooser = true }
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
            // Push the Login/Register chooser
            .navigationDestination(isPresented: $showAuthChooser) {
                GetStartedPage(
                    title: LocalizedStrings.authChooserTitle,
                    subtitle: LocalizedStrings.authChooserSubtitle,
                    loginTitle: LocalizedStrings.loginButton,
                    registerTitle: LocalizedStrings.registerButton,
                    isUserLoggedIn: $isUserLoggedIn
                )
            }
        }
        // restart typing when language changes
        .onChangeCompat(langManager.currentLanguage) { typeWriterEffect() }
    }

    // MARK: - Typing effect
    private func typeWriterEffect() { startTyping(fullAssistantText) }

    private func startTyping(_ text: String) {
        typingTask?.cancel()
        displayedText = ""
        guard !text.isEmpty else { return }

        typingTask = Task {
            for ch in text {
                try? await Task.sleep(nanoseconds: 28_000_000) // ~28ms
                if Task.isCancelled { return }
                await MainActor.run { displayedText.append(ch) }
            }
        }
    }

    private func stopTyping() {
        typingTask?.cancel()
        typingTask = nil
    }
}

// MARK: - Page 0: Language Selection
private struct LanguageSelectionPage: View {
    let title: String
    let onEnglish: () -> Void
    let onSlovak: () -> Void

    @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = 44
    @ScaledMetric(relativeTo: .title3) private var cardPadding: CGFloat = 12
    @ScaledMetric(relativeTo: .title3) private var cardRadius: CGFloat = 12
    @ScaledMetric(relativeTo: .title3) private var minButtonHeight: CGFloat = 50

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.primaryBlue.opacity(0.14), Color.accentBlue.opacity(0.14)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: iconSize + 22, height: iconSize + 22)
                        .overlay(Circle().stroke(Color.primaryBlue.opacity(0.15), lineWidth: 1))
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)

                    Image(systemName: "globe")
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundColor(.primaryBlue)
                }

                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.top, 4)

            // Options
            VStack(spacing: 10) {
                LanguageCard(
                    flag: "🇬🇧",
                    label: "English",
                    hint: "Tap to continue",
                    tint: .primaryBlue,
                    minHeight: minButtonHeight,
                    padding: cardPadding,
                    radius: cardRadius,
                    action: onEnglish
                )

                LanguageCard(
                    flag: "🇸🇰",
                    label: "Slovenčina",
                    hint: "Zvoľte pre pokračovanie",
                    tint: .accentBlue,
                    minHeight: minButtonHeight,
                    padding: cardPadding,
                    radius: cardRadius,
                    action: onSlovak
                )
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LanguageCard: View {
    let flag: String
    let label: String
    let hint: String
    let tint: Color
    let minHeight: CGFloat
    let padding: CGFloat
    let radius: CGFloat
    let action: () -> Void

    @ScaledMetric private var chip: CGFloat = 34

    var body: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

            HStack(spacing: 12) {
                // Flag chip
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.10))
                    Text(flag).font(.headline)
                }
                .frame(width: chip, height: chip)

                // Texts
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(hint)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(padding)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(shape.fill(Color(.secondarySystemBackground)))
            .overlay(
                HStack(spacing: 0) {
                    Rectangle().fill(tint.opacity(0.16)).frame(width: 4)
                    Spacer()
                }
                .clipShape(shape)
            )
            .overlay(shape.stroke(Color.black.opacity(0.05), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
            .contentShape(shape)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityHint(hint)
    }
}

// MARK: - Page 1: Assistant Greeting (single CTA)
private struct AssistantGreetingPage: View {
    let appTitle: String
    let subtitle: String
    let introLine: String
    @Binding var displayedText: String
    let onAppearTyping: () -> Void
    let onDisappearTyping: () -> Void
    let onContinue: () -> Void

    @ScaledMetric(relativeTo: .title)  private var avatarSize: CGFloat = 132
    @ScaledMetric(relativeTo: .title3) private var bubblePadding: CGFloat = 16
    @ScaledMetric(relativeTo: .title3) private var bubbleRadius: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text(appTitle)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)

                AvatarWithHalo(size: avatarSize)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(introLine)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(displayedText)
                        .font(.body)
                        .padding(bubblePadding)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: bubbleRadius)
                                .stroke(Color.accentBlue.opacity(0.20), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: bubbleRadius))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                }
                .padding(.horizontal)

               
                // Single primary CTA
                Button(LocalizedStrings.continueCTA) {
                    onContinue()
                }
                .buttonStyle(WPRectPrimaryStyle())

                Spacer(minLength: 0)
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .onAppear { onAppearTyping() }
        .onDisappear { onDisappearTyping() }
    }
}

// MARK: - Avatar Halo
private struct AvatarWithHalo: View {
    let size: CGFloat
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentBlue.opacity(0.10))
                .frame(width: size * 1.25, height: size * 1.25)
                .scaleEffect(pulse ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)

            Circle()
                .stroke(Color.accentBlue.opacity(0.18), lineWidth: 2)
                .frame(width: size * 1.15, height: size * 1.15)

            Image("avatar")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.accentBlue.opacity(0.25), lineWidth: 2))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Get Started (Auth chooser) with localized Back/Späť
private struct GetStartedPage: View {
    let title: String
    let subtitle: String
    let loginTitle: String
    let registerTitle: String
    @Binding var isUserLoggedIn: Bool

    @Environment(\.dismiss) private var dismiss

    @ScaledMetric(relativeTo: .title3) private var buttonVPad: CGFloat = 16
    @ScaledMetric(relativeTo: .title3) private var corner: CGFloat = 12

    var body: some View {
        VStack(spacing: 26) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 16) {
                // Primary: Login
                NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn)) {
                    Text(loginTitle)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonVPad)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .fill(Color.primaryBlue)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.primaryBlue.opacity(0.18), radius: 10, y: 6)
                        .accessibilityHint("Opens login screen")
                }
                .buttonStyle(ScaleButtonStyle())

                
                // Secondary: Register (tonal fill)
                NavigationLink(destination: RegisterView(isUserLoggedIn: $isUserLoggedIn)) {
                    Text(registerTitle)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonVPad)
                        .foregroundColor(.accentBlue)
                        .background(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .fill(Color.accentBlue.opacity(0.12))   // ← soft aqua fill
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .stroke(Color.accentBlue.opacity(0.45), lineWidth: 1) // ← clearer border
                        )
                        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                        .shadow(color: Color.accentBlue.opacity(0.10), radius: 6, y: 3)
                        .accessibilityHint("Opens registration screen")
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // ← localized custom back button
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(LocalizedStrings.t("Back", "Späť"))
                    }
                }
            }
        }
    }
}

// MARK: - Shared styles/utilities

// iOS 17+/16 compatibility for onChange
extension View {
    @ViewBuilder
    func onChangeCompat<T: Equatable>(_ value: T, perform action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, _ in action() }
        } else {
            self.onChange(of: value) { _ in action() }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// Solid blue narrow rectangle button used on the greeting page
private struct WPRectPrimaryStyle: ButtonStyle {
    @ScaledMetric private var height: CGFloat = 52
    @ScaledMetric private var corner: CGFloat = 14
    var width: CGFloat = 260

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.primaryBlue)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: Color.primaryBlue.opacity(configuration.isPressed ? 0.10 : 0.18),
                    radius: 10, y: 6)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

enum Haptics { static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() } }
