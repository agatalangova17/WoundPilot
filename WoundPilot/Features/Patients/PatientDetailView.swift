import SwiftUI

struct PatientDetailView: View {
    let patient: Patient
    @ObservedObject var langManager = LocalizationManager.shared

    // Palette
    private let pageBG  = Color(.systemGroupedBackground)
    private let cardBG  = Color(.secondarySystemBackground)
    private let stroke  = Color.black.opacity(0.06)
    private let primA   = Color.blue
    private let primB   = Color.cyan

    // MARK: - Formatting
    private var formattedDOB: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue) // "en"/"sk"
        return df.string(from: patient.dateOfBirth)
    }

    private var age: Int {
        Calendar.current.dateComponents([.year], from: patient.dateOfBirth, to: Date()).year ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Header Card (monogram + badges)
                HeaderCard(
                    name: patient.name,
                    dobLabel: "\(LocalizedStrings.dateOfBirth): \(formattedDOB)",
                    age: age,
                    isDiabetic: patient.isDiabetic ?? false,
                    isSmoker: patient.isSmoker ?? false,
                    hasPAD: patient.hasPAD ?? false
                )
                .cardStyle(bg: cardBG, stroke: stroke)

                // Primary action (uniform width, same radius)
                NavigationLink(destination: WoundImageSourceView(selectedPatient: patient)) {
                    Text(LocalizedStrings.newWoundEntry)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [primA, primB],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                // Info / History as matching cards
                VStack(spacing: 12) {
                    NavigationLink(destination: PatientInfoView(patient: patient)) {
                        RowCard(icon: "person.text.rectangle",
                                iconTint: .blue,
                                title: LocalizedStrings.viewPatientInfo)
                            .cardStyle(bg: cardBG, stroke: stroke)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: WoundListView(patient: patient)) {
                        RowCard(icon: "list.bullet.rectangle.portrait",
                                iconTint: .gray,
                                title: LocalizedStrings.viewWoundHistory)
                            .cardStyle(bg: cardBG, stroke: stroke)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(pageBG.ignoresSafeArea())
        .navigationTitle(LocalizedStrings.patientDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Components

private struct HeaderCard: View {
    let name: String
    let dobLabel: String
    let age: Int
    let isDiabetic: Bool
    let isSmoker: Bool
    let hasPAD: Bool

    @ScaledMetric(relativeTo: .title2) private var avatar: CGFloat = 56

    private var initials: String {
        let letters = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
        return letters.isEmpty ? "•" : letters
    }

    var body: some View {
        HStack(spacing: 14) {

            // Monogram avatar (subtle)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.cyan.opacity(0.22), Color.blue.opacity(0.12)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(initials)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.blue)
            }
            .frame(width: avatar, height: avatar)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(dobLabel)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                // Badges row – short, consistent “pills”
                HStack(spacing: 6) {
                    Tag(icon: "calendar", text: "\(age)")
                    if isDiabetic { Tag(icon: "drop.fill", text: "DM") }
                    if isSmoker   { Tag(icon: "lungs.fill", text: LocalizedStrings.smokerShort) } // you added this key
                    if hasPAD     { Tag(icon: "figure.walk.motion", text: "PAD") }
                }
            }

            Spacer()
        }
        .padding(14)
    }
}

private struct RowCard: View {
    let icon: String
    let iconTint: Color
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconTint.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconTint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .imageScale(.small)
        }
        .padding(14)
    }
}

private struct Tag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).imageScale(.small)
            Text(text).font(.caption2.weight(.semibold))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Reusable Card Style

private extension View {
    func cardStyle(bg: Color, stroke: Color) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(stroke, lineWidth: 0.5)
            )
    }
}
