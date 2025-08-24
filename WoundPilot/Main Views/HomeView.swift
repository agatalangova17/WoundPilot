import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var showProfile = false
    @State private var showClinicalTips = false
    @State private var userName: String = ""

    // Collapsible state for Tip section
    @State private var showTip = false

    // MARK: - Daily Clinical Tips (localized)
    var clinicalTips: [String] {
        [
            LocalizedStrings.dailyTipMoisture,
            LocalizedStrings.dailyTipEdges,
            LocalizedStrings.dailyTipTIME,
            LocalizedStrings.dailyTipGranulation,
            LocalizedStrings.dailyTipInfection,
            LocalizedStrings.dailyTipMeasure,
            LocalizedStrings.dailyTipEpithelial,
            LocalizedStrings.dailyTipDebridement,
            LocalizedStrings.dailyTipExudate
        ]
    }
    var todaysTip: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return clinicalTips[day % clinicalTips.count]
    }

    // Stable 2×2 grid
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Palette
    private let WPPrimaryBlue = Color(red: 0.20, green: 0.45, blue: 0.95)
    private let WPAccentBlue  = Color(red: 0.25, green: 0.80, blue: 0.85)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate())
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text(LocalizedStrings.dashboard) // “Prehľad”
                                .font(.title2.weight(.bold))
                        }
                        Spacer()
                        Button {
                            lightHaptic()
                            showProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(Color(.systemGray6), in: Circle())
                        }
                        .buttonStyle(HomeScaleButtonStyle())
                        .accessibilityLabel(LocalizedStrings.profile)
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)

                    // MARK: Tip of the Day (collapsed by default)
                    VStack(spacing: 10) {
                        TipDisclosureRow(
                            title: LocalizedStrings.tipOfTheDay,
                            isExpanded: showTip,
                            tint: WPAccentBlue
                        ) {
                            withAnimation(.easeInOut(duration: 0.22)) { showTip.toggle() }
                            lightHaptic()
                        }
                        .padding(.horizontal)

                        if showTip {
                            Button {
                                lightHaptic()
                                showClinicalTips = true
                            } label: {
                                TipContentCard( // only the tip text; no extra “Tip dňa” title
                                    tip: todaysTip
                                )
                            }
                            .buttonStyle(HomeScaleButtonStyle())
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // MARK: Actions grid (uniform cards)
                    LazyVGrid(columns: columns, spacing: 16) {

                        // Quick Scan
                        Button {
                            lightHaptic()
                            showQuickScan()
                        } label: {
                            ActionCard(
                                title: LocalizedStrings.quickScanTitle,
                                subtitle: LocalizedStrings.quickScanSubtitle,
                                systemImage: "bolt.fill",
                                gradient: [WPPrimaryBlue.opacity(0.18), WPAccentBlue.opacity(0.10)],
                                iconTint: WPPrimaryBlue
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())

                        // Add Patient
                        Button {
                            lightHaptic()
                            showAddPatient = true
                        } label: {
                            ActionCard(
                                title: LocalizedStrings.addPatient,
                                subtitle: LocalizedStrings.createProfile,
                                systemImage: "person.crop.circle.badge.plus",
                                gradient: [Color.indigo.opacity(0.16), Color.blue.opacity(0.08)],
                                iconTint: .indigo
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())

                        // Patients List
                        Button {
                            lightHaptic()
                            showPatientList = true
                        } label: {
                            ActionCard(
                                title: LocalizedStrings.viewPatients,
                                subtitle: LocalizedStrings.browseHistories,
                                systemImage: "folder.fill",
                                gradient: [Color.gray.opacity(0.16), Color.gray.opacity(0.08)],
                                iconTint: .gray
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())

                        // Clinical Tips
                        Button {
                            lightHaptic()
                            showClinicalTips = true
                        } label: {
                            ActionCard(
                                title: LocalizedStrings.clinicalTipsTitle,
                                subtitle: LocalizedStrings.evidenceBasedAdvice,
                                systemImage: "lightbulb.fill",
                                gradient: [Color.green.opacity(0.16), Color.mint.opacity(0.10)],
                                iconTint: .green
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 28)
                }
            }
            // Destinations
            .navigationDestination(isPresented: $showAddPatient) { AddPatientView() }
            .navigationDestination(isPresented: $showPatientList) { PatientListView() }
            .navigationDestination(isPresented: $showProfile) { ProfileView(isUserLoggedIn: $isUserLoggedIn) }
            .navigationDestination(isPresented: $showClinicalTips) { ClinicalTipsView() }
            .onAppear { fetchUserName() }
        }
    }

    // MARK: - Actions / Data
    func showQuickScan() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let root = UIHostingController(rootView: WoundImageSourceView(selectedPatient: nil))
            window.rootViewController?.present(root, animated: true)
        }
    }

    func fetchUserName() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(userId).getDocument { doc, _ in
            if let doc, doc.exists { userName = doc.get("name") as? String ?? "" }
        }
    }

    func formattedDate() -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return f.string(from: Date())
    }

    func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

//
// MARK: - Components
//

private struct TipDisclosureRow: View {
    let title: String
    let isExpanded: Bool
    let tint: Color
    var onTap: () -> Void

    @ScaledMetric(relativeTo: .title3) private var height: CGFloat = 44

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(tint)
                    .imageScale(.medium)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    .foregroundColor(.secondary)
                    .imageScale(.small)
            }
            .frame(height: height)
            .padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
        .accessibilityHint(isExpanded ? "Collapse" : "Expand")
    }
}

private struct TipContentCard: View {
    let tip: String

    @ScaledMetric(relativeTo: .title3) private var radius: CGFloat = 14
    @ScaledMetric(relativeTo: .title3) private var vpad: CGFloat = 14

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb")
                .foregroundColor(.secondary)
                .imageScale(.medium)
            Text(tip)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, vpad)
        .padding(.horizontal, 14)
        .background(shape.fill(Color(.secondarySystemBackground)))     // neutral, not blue
        .overlay(shape.stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
        .contentShape(shape)
    }
}

private struct ActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let gradient: [Color]
    let iconTint: Color

    @ScaledMetric(relativeTo: .title3) private var height: CGFloat = 118
    @ScaledMetric(relativeTo: .title3) private var radius: CGFloat = 16

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        ZStack(alignment: .topTrailing) {
            shape
                .fill(LinearGradient(colors: gradient,
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .overlay(shape.stroke(Color.black.opacity(0.04), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconTint.opacity(0.14))
                            .frame(width: 34, height: 34)
                        Image(systemName: systemImage)
                            .foregroundColor(iconTint)
                            .imageScale(.medium)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .imageScale(.small)
                }

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .frame(height: height)
        .contentShape(shape)
    }
}

//
// MARK: - Helpers
//

private struct HomeScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

extension Color {
    func darken(by amount: CGFloat) -> Color {
        Color(UIColor(self).withAlphaComponent(1 - min(max(amount, 0), 1)))
    }
}
