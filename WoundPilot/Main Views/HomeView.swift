import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var langManager = LocalizationManager.shared

    // Navigation flags
    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var showProfile = false
    @State private var showClinicalTips = false

    // Sharing / reviews
    @State private var pendingReviewCount: Int = 0

    // Tip section
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
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    // Palette
    private let WPPrimaryBlue = Color(red: 0.20, green: 0.45, blue: 0.95)
    private let WPAccentBlue  = Color(red: 0.25, green: 0.80, blue: 0.85)

    // Global corner radius for cards
    private let cardCorner: CGFloat = 22

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: Header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate())
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            Text(LocalizedStrings.dashboard) // “Prehľad”
                                .font(.title.weight(.bold))
                        }
                        Spacer()
                        Button {
                            lightHaptic()
                            showProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(8)
                                .background(Color(.systemGray6), in: Circle())
                        }
                        .buttonStyle(HomeScaleButtonStyle())
                        .accessibilityLabel(LocalizedStrings.profile)
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)

                    // MARK: Pending Reviews
                    if pendingReviewCount > 0 {
                        Button {
                            lightHaptic()
                            showClinicalTips = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "tray.full.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.orange)
                                Text(LocalizedStrings.pendingReviewsCount(pendingReviewCount))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.orange)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.orange.opacity(0.08))
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                    }

                    // ===== ORDER =====
                    // 1) TIP OF THE DAY
                    VStack(spacing: 8) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) { showTip.toggle() }
                            lightHaptic()
                        } label: {
                            TipDisclosureRowContent(
                                title: LocalizedStrings.tipOfTheDay,
                                isExpanded: showTip,
                                tint: WPAccentBlue
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())
                        .padding(.horizontal)

                        if showTip {
                            Button {
                                lightHaptic()
                                showClinicalTips = true
                            } label: {
                                TipContentCard(tip: todaysTip, cardCorner: cardCorner)
                            }
                            .buttonStyle(HomeScaleButtonStyle())
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, 8)     // reduced padding so it feels anchored
                    .padding(.bottom, 28) // keep separation before the grid

                    // 2) ACTIONS GRID
                    LazyVGrid(columns: columns, spacing: 18) {

                        Button {
                            lightHaptic()
                            showQuickScan()
                        } label: {
                            ActionCard(
                                title: LocalizedStrings.quickScanTitle,
                                subtitle: nil,
                                systemImage: "bolt.fill",
                                gradient: [WPPrimaryBlue.opacity(0.18), WPAccentBlue.opacity(0.10)],
                                iconTint: WPPrimaryBlue,
                                height: 140,
                                corner: cardCorner
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())

                        Button {
                            lightHaptic()
                            showAddPatient = true
                        } label: {
                            ActionCard(
                                title: LocalizedStrings.addPatient,
                                subtitle: nil,
                                systemImage: "person.crop.circle.badge.plus",
                                gradient: [Color.indigo.opacity(0.16), Color.blue.opacity(0.08)],
                                iconTint: .indigo,
                                height: 140,
                                corner: cardCorner
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())

                        Button {
                            lightHaptic()
                            showPatientList = true
                        } label: {
                            ActionCard(
                                title: LocalizedStrings.viewPatients,
                                subtitle: nil,
                                systemImage: "folder.fill",
                                gradient: [Color.gray.opacity(0.16), Color.gray.opacity(0.08)],
                                iconTint: .gray,
                                height: 140,
                                corner: cardCorner
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())

                        Button {
                            lightHaptic()
                            showClinicalTips = true
                        } label: {
                            ActionCard(
                                title: LocalizedStrings.clinicalTipsTitle,
                                subtitle: nil,
                                systemImage: "lightbulb.fill",
                                gradient: [Color.green.opacity(0.16), Color.mint.opacity(0.10)],
                                iconTint: .green,
                                height: 140,
                                corner: cardCorner
                            )
                        }
                        .buttonStyle(HomeScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            // Destinations
            .navigationDestination(isPresented: $showAddPatient) { AddPatientView() }
            .navigationDestination(isPresented: $showPatientList) { PatientListView() }
            .navigationDestination(isPresented: $showProfile) { ProfileView(isUserLoggedIn: $isUserLoggedIn) }
            .navigationDestination(isPresented: $showClinicalTips) { ClinicalTipsView() }
            .onAppear {
                loadPendingReviews()
            }
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

    func loadPendingReviews() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        Firestore.firestore()
            .collection("sharedCases")
            .whereField("recipientEmail", isEqualTo: userEmail)
            .whereField("status", isEqualTo: "new")
            .getDocuments { snapshot, _ in
                pendingReviewCount = snapshot?.documents.count ?? 0
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

private struct TipDisclosureRowContent: View {
    let title: String
    let isExpanded: Bool
    let tint: Color

    @ScaledMetric(relativeTo: .title3) private var height: CGFloat = 44

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .frame(height: height)
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
    }
}

private struct TipContentCard: View {
    let tip: String
    var cardCorner: CGFloat

    @ScaledMetric(relativeTo: .title3) private var vpad: CGFloat = 14

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cardCorner, style: .continuous)

        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(tip)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, vpad)
        .padding(.horizontal, 16)
        .background(shape.fill(Color(.secondarySystemBackground)))
        .overlay(shape.stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
        .contentShape(shape)
    }
}

private struct ActionCard: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let gradient: [Color]
    let iconTint: Color
    var height: CGFloat = 140
    var corner: CGFloat = 22

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        ZStack {
            shape
                .fill(LinearGradient(colors: gradient,
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .overlay(shape.stroke(Color.black.opacity(0.04), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 10) {
                // Top row
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(iconTint.opacity(0.14))
                            .frame(width: 36, height: 36)
                        Image(systemName: systemImage)
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(iconTint)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                // Text content
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)
            }
            .padding(16)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .shadow(
                color: configuration.isPressed ? Color.accentColor.opacity(0.22) : Color.clear,
                radius: configuration.isPressed ? 8 : 0, x: 0, y: 0
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

extension Color {
    func darken(by amount: CGFloat) -> Color {
        Color(UIColor(self).withAlphaComponent(1 - min(max(amount, 0), 1)))
    }
}
