import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool

    // React to language changes
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var showProfile = false
    @State private var showClinicalTips = false
    @State private var userName: String = ""

    // MARK: - Daily Clinical Tips (localized, recomputed on language change)
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
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return clinicalTips[dayOfYear % clinicalTips.count]
    }

    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 16), count: 2)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate())
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(LocalizedStrings.dashboard)
                                .font(.title2.bold())
                        }

                        Spacer()

                        Button {
                            lightHaptic()
                            showProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                                .padding(6)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // MARK: - Tip of the Day
                    TipOfTheDayView(tip: todaysTip)
                        .padding(.horizontal)

                    // MARK: - Grid Cards (2x2 layout)
                    LazyVGrid(columns: columns, spacing: 16) {
                        Button {
                            lightHaptic()
                            showQuickScan()
                        } label: {
                            DashboardCard(
                                title: LocalizedStrings.quickScanTitle,
                                subtitle: LocalizedStrings.quickScanSubtitle,
                                systemImage: "bolt.fill",
                                bgColor: Color(red: 0.84, green: 0.92, blue: 1.0),
                                layout: .square,
                                textColor: Color(red: 0.00, green: 0.30, blue: 0.75),
                                showsChevron: true
                            )
                        }

                        Button {
                            lightHaptic()
                            showAddPatient = true
                        } label: {
                            DashboardCard(
                                title: LocalizedStrings.addPatient,
                                subtitle: LocalizedStrings.createProfile,
                                systemImage: "person.crop.circle.badge.plus",
                                bgColor: Color(red: 0.88, green: 0.90, blue: 0.98),
                                layout: .square,
                                textColor: Color(red: 0.22, green: 0.24, blue: 0.60),
                                showsChevron: true
                            )
                        }

                        Button {
                            lightHaptic()
                            showPatientList = true
                        } label: {
                            DashboardCard(
                                title: LocalizedStrings.viewPatients,
                                subtitle: LocalizedStrings.browseHistories,
                                systemImage: "folder.fill",
                                bgColor: Color(red: 0.90, green: 0.91, blue: 0.92),
                                layout: .square,
                                textColor: Color(red: 0.14, green: 0.15, blue: 0.17),
                                showsChevron: true
                            )
                        }

                        Button {
                            lightHaptic()
                            showClinicalTips = true
                        } label: {
                            DashboardCard(
                                title: LocalizedStrings.clinicalTipsTitle,
                                subtitle: LocalizedStrings.evidenceBasedAdvice,
                                systemImage: "lightbulb.fill",
                                bgColor: Color(red: 0.85, green: 0.96, blue: 0.92),
                                layout: .square,
                                textColor: Color(red: 0.00, green: 0.38, blue: 0.30),
                                showsChevron: true
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }

            .navigationDestination(isPresented: $showAddPatient) {
                AddPatientView()
            }
            .navigationDestination(isPresented: $showPatientList) {
                PatientListView()
            }
            .navigationDestination(isPresented: $showProfile) {
                ProfileView(isUserLoggedIn: $isUserLoggedIn)
            }
            .navigationDestination(isPresented: $showClinicalTips) {
                ClinicalTipsView()
            }
        }
    }

    func showQuickScan() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let root = UIHostingController(rootView: WoundImageSourceView(selectedPatient: nil))
            window.rootViewController?.present(root, animated: true, completion: nil)
        }
    }

    func fetchUserName() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, _ in
            if let document = document, document.exists {
                userName = document.get("name") as? String ?? ""
            }
        }
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        // Localize by current app language ("en" / "sk")
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.string(from: Date())
    }

    func lightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

extension Color {
    func darken(by amount: CGFloat) -> Color {
        return Color(UIColor(self).withAlphaComponent(1 - min(max(amount, 0), 1)))
    }
}
