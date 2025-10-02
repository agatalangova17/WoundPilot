import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var dateJoined: String = ""

    @Environment(\.dismiss) private var dismiss
    @Binding var isUserLoggedIn: Bool

    // Re-render on language changes
    @ObservedObject var langManager = LocalizationManager.shared

    // Avatar editing
    @State private var photoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?

    // Scaled metrics
    @ScaledMetric(relativeTo: .title)  private var avatarSize: CGFloat = 96
    @ScaledMetric(relativeTo: .title3) private var cardRadius: CGFloat = 16
    @ScaledMetric(relativeTo: .title3) private var chipSize: CGFloat = 40
    @ScaledMetric(relativeTo: .title3) private var vPad: CGFloat = 14

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {

                    // MARK: - Header (Avatar only — no title / email here)
                    AvatarEditor(
                        image: $avatarImage,
                        photoItem: $photoItem,
                        size: avatarSize
                    )
                    .padding(.top, 10)

                    // MARK: - Info Cards
                    VStack(spacing: 12) {
                        InfoRowCard(
                            icon: "person.fill",
                            title: LocalizedStrings.fullNameLabel,
                            value: fullName.isEmpty ? LocalizedStrings.unknownName : fullName,
                            radius: cardRadius,
                            chipSize: chipSize
                        )
                        InfoRowCard(
                            icon: "envelope.fill",
                            title: LocalizedStrings.emailLabel,
                            value: email,
                            radius: cardRadius,
                            chipSize: chipSize
                        )
                        InfoRowCard(
                            icon: "calendar",
                            title: LocalizedStrings.joinedLabel,
                            value: dateJoined,
                            radius: cardRadius,
                            chipSize: chipSize
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Actions
                    VStack(spacing: 12) {
                        // Solid dark-blue primary button
                        Button {
                            if let url = URL(string: "mailto:support@woundpilot.com") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(LocalizedStrings.contactSupport)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, vPad)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                                        .fill(Color.primaryBlue) // solid dark blue
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(color: Color.primaryBlue.opacity(0.18), radius: 10, y: 6)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal)

                        Button(role: .destructive) {
                            try? Auth.auth().signOut()
                            isUserLoggedIn = false
                            dismiss()
                        } label: {
                            Text(LocalizedStrings.logOut)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, vPad)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.red)
                                .background(
                                    RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                                        .fill(Color.red.opacity(0.10))
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 8)
                }
            }
            .navigationTitle(LocalizedStrings.profileNavTitle) // “Profil”
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: photoItem) { _, newItem in
                // load selected avatar
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImg = UIImage(data: data) {
                        await MainActor.run { avatarImage = uiImg }
                    }
                }
            }
            .onAppear(perform: loadUserInfo)
        }
    }

    // MARK: - Firebase Fetch
    private func loadUserInfo() {
        guard let user = Auth.auth().currentUser else { return }
        email = user.email ?? ""
        fullName = user.displayName ?? LocalizedStrings.unknownName

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue) // "en"/"sk"
        dateJoined = formatter.string(from: user.metadata.creationDate ?? Date())
    }
}

// MARK: - Components

private struct AvatarEditor: View {
    @Binding var image: UIImage?
    @Binding var photoItem: PhotosPickerItem?
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Ring + photo / placeholder
            ZStack {
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [Color.primaryBlue.opacity(0.35), Color.accentBlue.opacity(0.35)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .frame(width: size + 10, height: size + 10)

                Group {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.accentBlue.opacity(0.15))
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: size * 0.42))
                                .foregroundColor(.primaryBlue)
                        }
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.accentBlue.opacity(0.20), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
            }

            // Camera badge
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack {
                    Circle().fill(Color(.systemBackground))
                        .frame(width: 34, height: 34)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

                    Image(systemName: "camera.fill")
                        .imageScale(.medium)
                        .foregroundColor(.accentBlue)
                }
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: 6)
        }
        .accessibilityLabel("Change profile photo")
    }
}

private struct InfoRowCard: View {
    let icon: String
    let title: String
    let value: String
    let radius: CGFloat
    let chipSize: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        HStack(alignment: .center, spacing: 12) {
            // Icon chip
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentBlue.opacity(0.12))
                Image(systemName: icon)
                    .foregroundColor(.accentBlue)
                    .imageScale(.medium)
            }
            .frame(width: chipSize, height: chipSize)

            // Texts
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value.isEmpty ? "—" : value)
                    .font(.body)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(shape.fill(Color(.secondarySystemBackground)))
        .overlay(shape.stroke(Color.accentBlue.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}
