import SwiftUI

struct ShareCaseView: View {
    @ObservedObject var langManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var recipientEmail: String = ""
    @State private var notes: String = ""
    @State private var isSharing = false
    @State private var emailError: String = ""
    @State private var showSuccess = false

    @FocusState private var focusedField: Field?
    private enum Field { case email, message }

    // tiny translator so we don’t add new keys
    private func tr(_ en: String, _ sk: String) -> String {
        LocalizationManager.shared.currentLanguage == .sk ? sk : en
    }

    private var isEmailValid: Bool {
        recipientEmail.contains("@") && recipientEmail.contains(".")
    }

    @ScaledMetric(relativeTo: .title3) private var cardRadius: CGFloat = 12
    @ScaledMetric(relativeTo: .title3) private var vPad: CGFloat = 14

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                // Subtle subtitle ONLY (title is in nav bar)
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.and.paperplane")
                        .foregroundColor(.accentBlue)
                        .imageScale(.medium)
                    Text(tr("Securely share case details with a colleague.",
                            "Bezpečne odošlite údaje prípadu kolegovi."))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.horizontal)

                // Email card
                InputCard(icon: "envelope.fill",
                          title: LocalizedStrings.recipientSection) {
                    TextField(LocalizedStrings.doctorEmailPlaceholder, text: $recipientEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .message }
                        .onChange(of: recipientEmail) { _, new in
                            emailError = new.isEmpty ? "" : (isEmailValid ? "" : LocalizedStrings.invalidEmail)
                        }
                }
                .padding(.horizontal)

                if !emailError.isEmpty {
                    Text(emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                // Message card (now grey like the email card)
                TextEditorCard(
                    title: LocalizedStrings.messageSection,
                    placeholder: LocalizedStrings.messagePlaceholder,
                    text: $notes,
                    minHeight: 120
                )
                .focused($focusedField, equals: .message)
                .padding(.horizontal)

                // Security hint
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").imageScale(.small)
                    Text(tr("Encrypted & GDPR-compliant", "Šifrované a v súlade s GDPR"))
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

                // Primary action (narrower & centered)
                HStack {
                    Spacer()
                    Button {
                        if isEmailValid { shareNow() }
                        else {
                            emailError = LocalizedStrings.invalidEmail
                            focusedField = .email
                        }
                    } label: {
                        HStack {
                            if isSharing {
                                ProgressView(LocalizedStrings.sharingInProgress)
                                    .tint(.white)
                            } else {
                                Text(LocalizedStrings.shareCaseButton)
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: 360) // narrower than full width
                        .padding(.vertical, vPad)
                        .background(
                            LinearGradient(colors: [Color.primaryBlue, Color.accentBlue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.primaryBlue.opacity(0.22), radius: 10, y: 6)
                    }
                    .disabled(isSharing)
                    .buttonStyle(WPScaleButtonStyle2())
                    Spacer()
                }
                .padding(.horizontal)

                // Secondary action
                Button { dismiss() } label: {
                    Text(tr("Cancel", "Zrušiť"))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)

                Spacer(minLength: 8)
            }
            .padding(.top, 8)
        }
        .navigationTitle(LocalizedStrings.shareCaseTitle) // single visible title
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(tr("Done", "Hotovo")) { focusedField = nil }
            }
        }
        .alert(
            tr("Shared", "Zdieľané"),
            isPresented: $showSuccess
        ) {
            Button(tr("OK", "OK")) { dismiss() }
        } message: {
            Text(tr("Your case has been shared successfully.",
                    "Prípad bol úspešne zdieľaný."))
        }
    }

    private func shareNow() {
        isSharing = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // TODO: integrate Firebase sharing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            isSharing = false
            showSuccess = true
        }
    }
}

//
// MARK: - Reusable Cards
//

private struct InputCard<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder var content: Content

    @ScaledMetric(relativeTo: .title3) private var radius: CGFloat = 12

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentBlue)
                    .imageScale(.medium)
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
            content.font(.body)
        }
        .padding(14)
        .background(shape.fill(Color(.secondarySystemBackground)))
        .overlay(shape.stroke(Color.black.opacity(0.05), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
    }
}

private struct TextEditorCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    @ScaledMetric(relativeTo: .title3) private var radius: CGFloat = 12

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.accentBlue)
                    .imageScale(.medium)
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }

            ZStack(alignment: .topLeading) {
                if #available(iOS 16.0, *) {
                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden) // hide white background
                        .frame(minHeight: minHeight)
                        .padding(.horizontal, -4)
                } else {
                    // Fallback: TextEditor uses system background; the card still keeps a neutral look
                    TextEditor(text: $text)
                        .frame(minHeight: minHeight)
                        .padding(.horizontal, -4)
                }

                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .font(.body)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(14)
        .background(shape.fill(Color(.secondarySystemBackground))) // grey, like email card
        .overlay(shape.stroke(Color.black.opacity(0.05), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
    }
}

//
// MARK: - Local button style
//
private struct WPScaleButtonStyle2: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: configuration.isPressed)
    }
}
