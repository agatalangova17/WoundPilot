import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var langManager = LocalizationManager.shared

    // Navigation flags
    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var showProfile = false
    @State private var showClinicalTips = false
    @State private var showSharedCases = false

    // Quick Scan (SwiftUI modal)
    @State private var showQuickScanModal = false

    // Sharing / reviews
    @State private var pendingReviewCount: Int = 0

    // Recent patients
    @State private var recentPatients: [RecentPatient] = []

    // Layout
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
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate())
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text(LocalizedStrings.dashboard)
                                .font(.title.weight(.bold))
                        }
                        Spacer()
                        Button {
                            lightHaptic()
                            showProfile = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "person.crop.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .padding(8)
                                    .background(Color(.systemGray6), in: Circle())

                                if pendingReviewCount > 0 {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        .buttonStyle(HomeScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)

                    // MARK: Pending Reviews banner
                    if pendingReviewCount > 0 {
                        Button {
                            lightHaptic()
                            showSharedCases = true
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

                    // ===== CONTENT =====

                    // 1) HERO: QUICK SCAN
                    Button {
                        lightHaptic()
                        showQuickScanModal = true
                    } label: {
                        ActionCard(
                            title: LocalizedStrings.quickScanTitle,
                            subtitle: nil,
                            systemImage: "bolt.fill",
                            gradient: [WPPrimaryBlue.opacity(0.20), WPAccentBlue.opacity(0.10)],
                            iconTint: WPPrimaryBlue,
                            height: 164,
                            corner: cardCorner
                        )
                    }
                    .buttonStyle(HomeScaleButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 6)

                    // 2) RECENT PATIENTS
                    if !recentPatients.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recentPatients) { p in
                                    Button {
                                        lightHaptic()
                                        showPatientList = true
                                    } label: {
                                        RecentPatientCard(
                                            name: p.name,
                                            subtitle: p.updatedAt.map { relativeDate($0) } ?? ""
                                        )
                                    }
                                    .buttonStyle(HomeScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 2)
                    }

                    // 3) GRID
                    LazyVGrid(columns: columns, spacing: 20) {
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
                            showSharedCases = true
                        } label: {
                            ActionCard(
                                title: "Zdieľanie", // TODO: localize key
                                subtitle: nil,
                                systemImage: "person.2.circle.fill",
                                gradient: [Color.cyan.opacity(0.16), Color.teal.opacity(0.10)],
                                iconTint: .teal,
                                height: 140,
                                corner: cardCorner
                            )
                            .overlay(alignment: .topTrailing) {
                                if pendingReviewCount > 0 {
                                    Text("\(pendingReviewCount)")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.orange))
                                        .offset(x: -10, y: 10)
                                }
                            }
                            .overlay(alignment: .topLeading) {
                                if pendingReviewCount > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 14, y: 14)
                                }
                            }
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
                    .padding(.bottom, 48)
                }
            }
            // Destinations
            .navigationDestination(isPresented: $showAddPatient) { AddPatientView() }
            .navigationDestination(isPresented: $showPatientList) { PatientListView() }
            .navigationDestination(isPresented: $showProfile) { ProfileView(isUserLoggedIn: $isUserLoggedIn) }
            .navigationDestination(isPresented: $showClinicalTips) { ClinicalTipsView() }
            .navigationDestination(isPresented: $showSharedCases) { SharingView() }
            .onAppear {
                loadPendingReviews()
                loadRecentPatients()
            }
        }
        // Quick Scan presenter (full-screen with Close)
        .fullScreenCover(isPresented: $showQuickScanModal) {
            QuickScanFlowSheet()
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 8) }
    }

    // MARK: - Data
    func loadPendingReviews() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        Firestore.firestore()
            .collection("sharedCases")
            .whereField("recipientEmail", isEqualTo: userEmail)
            .whereField("status", isEqualTo: "new")
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    pendingReviewCount = snapshot?.documents.count ?? 0
                }
            }
    }

    func loadRecentPatients(limit: Int = 10) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let base = Firestore.firestore()
            .collection("users").document(uid)
            .collection("patients")

        base.order(by: "updatedAt", descending: true).limit(to: limit).getDocuments { snap, err in
            if let err = err {
                base.order(by: "createdAt", descending: true).limit(to: limit).getDocuments { snap2, _ in
                    DispatchQueue.main.async { self.recentPatients = self.mapPatients(snap2) }
                }
                print("loadRecentPatients updatedAt error: \(err.localizedDescription)")
                return
            }
            if let snap = snap, !snap.isEmpty {
                DispatchQueue.main.async { self.recentPatients = self.mapPatients(snap) }
            } else {
                base.order(by: "createdAt", descending: true).limit(to: limit).getDocuments { snap2, _ in
                    DispatchQueue.main.async { self.recentPatients = self.mapPatients(snap2) }
                }
            }
        }
    }

    private func mapPatients(_ snapshot: QuerySnapshot?) -> [RecentPatient] {
        guard let docs = snapshot?.documents else { return [] }
        return docs.compactMap { doc in
            let data = doc.data()
            let name = (data["fullName"] as? String)
                ?? (data["name"] as? String)
                ?? (data["displayName"] as? String)
                ?? "—"
            let updatedTs = (data["updatedAt"] as? Timestamp) ?? (data["lastUpdated"] as? Timestamp)
            let createdTs = (data["createdAt"] as? Timestamp)
            let date = updatedTs?.dateValue() ?? createdTs?.dateValue()
            return RecentPatient(id: doc.documentID, name: name, updatedAt: date)
        }
    }

    func formattedDate() -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return f.string(from: Date())
    }

    func relativeDate(_ date: Date) -> String {
        let r = RelativeDateTimeFormatter()
        r.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        r.unitsStyle = .short
        return r.localizedString(for: date, relativeTo: Date())
    }

    func lightHaptic() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

// MARK: - Lightweight model
struct RecentPatient: Identifiable {
    let id: String
    let name: String
    let updatedAt: Date?
}

//
// MARK: - Components
//

private struct ActionCard: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let gradient: [Color]
    let iconTint: Color
    var height: CGFloat = 140
    var corner: CGFloat = 22

    // Typography / spacing
    var titleFont: Font = .headline.weight(.semibold) 
    var contentInset: CGFloat = 16

    // Outline
    var showOutline: Bool = true
    var outlineOpacity: Double = 0.35
    var outlineWidth: CGFloat = 0.5

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        ZStack {
            shape
                .fill(LinearGradient(colors: gradient,
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .overlay {
                    if showOutline {
                        shape.strokeBorder(
                            Color(UIColor.separator).opacity(outlineOpacity),
                            lineWidth: outlineWidth
                        )
                    }
                }
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 10) {
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

                Spacer(minLength: 6)

                Text(title)
                    .font(titleFont)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)
            }
            .padding(contentInset)
        }
        .frame(height: height)
        .contentShape(shape)
    }
}

private struct RecentPatientCard: View {
    let name: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "person.crop.square")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

            Text(name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 0.5))
    }
}

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

// MARK: - Wrapper so Quick Scan can be dismissed any time
private struct QuickScanFlowSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WoundImageSourceView(selectedPatient: nil)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStrings.t("Close", "Zavrieť")) { dismiss() }
                    }
                }
        }
        .interactiveDismissDisabled(false)
    }
}
