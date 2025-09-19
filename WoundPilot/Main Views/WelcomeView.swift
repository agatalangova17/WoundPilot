import SwiftUI
import UIKit

// MARK: - WelcomeView (container)
struct WelcomeView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var currentTab = 0
    @State private var selectedStep = 1
    @State private var expandedQuestion: String?
    @State private var displayedText = ""

    // Single running typewriter task (prevents duplicated letters)
    @State private var typingTask: Task<Void, Never>? = nil

    var fullAssistantText: String { LocalizedStrings.assistantTypingText }

    var steps: [(Int, String, String)] {
        let imgs = ["log","start analysis","photo","location","size","questions","ai"]
        return (1...7).map { i in (i, LocalizedStrings.stepDescription(i), imgs[i-1]) }
    }
    var faqList: [(question: String, answer: String)] { LocalizedStrings.faqList }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                TabView(selection: $currentTab) {
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

                    AssistantGreetingPage(
                        appTitle: LocalizedStrings.appTitle,
                        subtitle: LocalizedStrings.appSubtitle,
                        introLine: LocalizedStrings.assistantIntroLine,
                        displayedText: $displayedText,
                        onAppearTyping: { typeWriterEffect() },        // start (auto-cancels previous)
                        onDisappearTyping: { stopTyping() },            // stop when leaving
                        onContinue: { withAnimation(.spring()) { currentTab = 2 } }, // CTA -> next page
                        loginLinkTitle: LocalizedStrings.alreadyUsing,
                        isUserLoggedIn: $isUserLoggedIn
                    )
                    .tag(1)

                    IntroVideoPage(
                        title: LocalizedStrings.introVideoTitle,
                        subtitle: LocalizedStrings.introVideoSubtitle
                    )
                    .tag(2)

                    HowItWorksPage(
                        title: LocalizedStrings.howItWorksTitle,
                        selectedStep: $selectedStep,
                        steps: steps
                    )
                    .tag(3)

                    FAQPage(
                        title: LocalizedStrings.faqTitle,
                        faqList: faqList,
                        expandedQuestion: $expandedQuestion
                    )
                    .tag(4)

                    GetStartedPage(
                        title: LocalizedStrings.getStartedTitle,
                        subtitle: LocalizedStrings.getStartedSubtitle,
                        loginTitle: LocalizedStrings.loginButton,
                        registerTitle: LocalizedStrings.registerButton,
                        isUserLoggedIn: $isUserLoggedIn
                    )
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
        }
        // Restart typing on language change (previous run is cancelled first)
        .onChangeCompat(langManager.currentLanguage) { typeWriterEffect() }
    }

    // MARK: - Typing effect (Task-based, cancellable)
    func typeWriterEffect() {
        startTyping(fullAssistantText)
    }

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

// MARK: - Page 0: Language Selection (compact)
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
                    .font(.title3.weight(.semibold)) // smaller than before
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
                    hint: "Ťuknite pre pokračovanie",
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
                        .font(.headline)            // smaller than .title3
                        .foregroundColor(.primary)
                    Text(hint)
                        .font(.footnote)            // smaller than .subheadline
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")   // no extra chip
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(padding)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(shape.fill(Color(.secondarySystemBackground)))
            .overlay(
                // thin accent at left, subtle border
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

// MARK: - Page 1: Assistant Greeting (with CTA + pulsing halo)
// MARK: - Page 0: Assistant Greeting (solid blue CTA)
private struct AssistantGreetingPage: View {
    let appTitle: String
    let subtitle: String
    let introLine: String
    @Binding var displayedText: String
    let onAppearTyping: () -> Void
    let onDisappearTyping: () -> Void
    let onContinue: () -> Void

    let loginLinkTitle: String
    @Binding var isUserLoggedIn: Bool

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
                        .fixedSize(horizontal: false, vertical: true)

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
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)

                // Solid blue CTA (narrow rectangle)
                Button(LocalizedStrings.getStartedTitle) {
                    onContinue()
                }
                .buttonStyle(WPRectPrimaryStyle())

                NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn)) {
                    Text(loginLinkTitle)
                        .font(.body)
                        .foregroundColor(.accentBlue)
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)

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

// MARK: - Solid Blue Narrow Rect Button
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
                    .fill(Color.primaryBlue) // solid blue
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
// MARK: - Page 2: Intro Video Placeholder (scales with width)
private struct IntroVideoPage: View {
    let title: String
    let subtitle: String

    @ScaledMetric(relativeTo: .title3) private var corner: CGFloat = 18

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)

            GeometryReader { proxy in
                let maxW = min(proxy.size.width - 32, 520)
                let h = maxW * 0.6

                ZStack {
                    RoundedRectangle(cornerRadius: corner)
                        .fill(LinearGradient(
                            colors: [Color.primaryBlue.opacity(0.12), Color.accentBlue.opacity(0.12)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: maxW, height: h)
                        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)

                    VStack(spacing: 10) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 66))
                            .foregroundColor(.accentBlue)
                            .accessibilityHidden(true)
                        Text(subtitle)
                            .foregroundColor(.accentBlue)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 240)

            Spacer(minLength: 0)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Page 3: How It Works (fully scales)
private struct HowItWorksPage: View {
    let title: String
    @Binding var selectedStep: Int
    let steps: [(Int, String, String)]

    @Environment(\.dynamicTypeSize) private var dts

    private var scale: CGFloat {
        switch dts {
        case .xLarge:          return 1.20
        case .xxLarge:         return 1.35
        case .xxxLarge:        return 1.55
        case .accessibility1:  return 1.75
        case .accessibility2:  return 1.95
        case .accessibility3:  return 2.15
        case .accessibility4:  return 2.35
        case .accessibility5:  return 2.55
        default:               return 1.00
        }
    }
    private var isHuge: Bool { dts >= .accessibility2 }

    var body: some View {
        VStack(spacing: 22) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)

            Group {
                if isHuge {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 64 * scale), spacing: 12)], spacing: 12) {
                        stepButtons
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) { stepButtons }
                            .padding(.horizontal)
                    }
                }
            }

            if let s = steps.first(where: { $0.0 == selectedStep }) {
                VStack(spacing: 14) {
                    Text(s.1)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    GeometryReader { proxy in
                        let maxW = min(proxy.size.width - 32, 520)
                        let h = (maxW * 0.75) * min(scale, 1.8)

                        Image(s.2)
                            .resizable()
                            .scaledToFit()
                            .frame(width: maxW, height: h)
                            .clipShape(RoundedRectangle(cornerRadius: 14 * scale))
                            .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
                            .accessibilityLabel("Illustration for step \(selectedStep)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 220 * scale)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var stepButtons: some View {
        ForEach(steps, id: \.0) { (index, _, _) in
            let diameter = 44 * scale
            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    selectedStep = index
                }
            } label: {
                Text("\(index)")
                    .font(isHuge ? .title.weight(.bold) : .title3.weight(.bold))
                    .minimumScaleFactor(0.85)
                    .frame(width: diameter, height: diameter)
                    .background(
                        selectedStep == index
                        ? AnyShapeStyle(Color.primaryBlue)          // ← solid blue (no gradient)
                        : AnyShapeStyle(Color.gray.opacity(0.15))
                    )
                    .foregroundColor(selectedStep == index ? .white : .primary)
                    .clipShape(Circle())
                    .shadow(color: selectedStep == index ? Color.primaryBlue.opacity(0.25) : .clear,
                            radius: 8, y: 4)
                    .contentShape(Circle())
                    .accessibilityLabel("Step \(index)")
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Page 4: FAQ (refined)
private struct FAQPage: View {
    let title: String
    let faqList: [(question: String, answer: String)]
    @Binding var expandedQuestion: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.accentBlue)
                        .imageScale(.large)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                VStack(spacing: 12) {
                    ForEach(faqList, id: \.question) { faq in
                        FAQRow(
                            faq: faq,
                            isExpanded: expandedQuestion == faq.question,
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedQuestion = (expandedQuestion == faq.question) ? nil : faq.question
                                }
                                Haptics.light()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
            .padding(.bottom, 24)
        }
    }
}

private struct FAQRow: View {
    let faq: (question: String, answer: String)
    let isExpanded: Bool
    let onToggle: () -> Void

    @ScaledMetric(relativeTo: .title3) private var pad: CGFloat = 14
    @ScaledMetric(relativeTo: .title3) private var radius: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(faq.question)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 10)

                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    .foregroundColor(.secondary)
                    .imageScale(.medium)
            }
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }

            if isExpanded {
                Text(faq.answer)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top))) // fixed (no parentheses)
            }
        }
        .padding(pad)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(Color.accentBlue.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

// MARK: - Page 5: Get Started (Login / Register)
private struct GetStartedPage: View {
    let title: String
    let subtitle: String
    let loginTitle: String
    let registerTitle: String
    @Binding var isUserLoggedIn: Bool

    @ScaledMetric(relativeTo: .title3) private var buttonVPad: CGFloat = 16
    @ScaledMetric(relativeTo: .title3) private var corner: CGFloat = 12

    var body: some View {
        VStack(spacing: 26) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 16) {
                // Solid blue (no gradient) — primary action
                NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn)) {
                    Text(loginTitle)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonVPad)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .fill(Color.primaryBlue)                                   // ← solid blue
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)            // subtle highlight
                        )
                        .shadow(color: Color.primaryBlue.opacity(0.18), radius: 10, y: 6)
                        .accessibilityHint("Opens login screen")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(ScaleButtonStyle())

                // Secondary action (outlined)
                NavigationLink(destination: RegisterView(isUserLoggedIn: $isUserLoggedIn)) {
                    Text(registerTitle)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonVPad)
                        .foregroundColor(.accentBlue)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .stroke(Color.accentBlue.opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                        .shadow(color: Color.accentBlue.opacity(0.12), radius: 8, y: 4)
                        .accessibilityHint("Opens registration screen")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// NEW: narrower rectangle CTA used ONLY for the "Začnime" button on the greeting page
struct WPRectCTAStyle: ButtonStyle {
    var width: CGFloat = 220   // adjust to make narrower/wider
    var corner: CGFloat = 14
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(width: width) // fixed narrow width
            .background(
                LinearGradient(colors: [Color.primaryBlue, Color.accentBlue],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .shadow(color: Color.primaryBlue.opacity(0.20), radius: 8, y: 4)
            // center without stretching the background
            .frame(maxWidth: .infinity)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

enum Haptics { static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() } }
