import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var showProfile = false
    @State private var showClinicalTips = false
    @State private var userName: String = ""

    // MARK: - Daily Clinical Tips
    let clinicalTips = [
        "Maintain moisture balance for faster healing.",
        "Assess wound edges for signs of maceration.",
        "Use the TIME framework: Tissue, Infection, Moisture, Edge.",
        "Granulation tissue is a sign of healing progress.",
        "Check for signs of infection: redness, swelling, odor.",
        "Regularly measure wound size to monitor healing trends.",
        "Epithelialization signals wound closure is near.",
        "Sharp debridement can accelerate healing when indicated.",
        "Excess exudate may indicate infection or delayed healing."
    ]
    
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

                            Text("Dashboard")
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
                                title: "Quick Wound Scan",
                                subtitle: "Start fast analysis",
                                systemImage: "bolt.fill",
                                bgColor: Color(red: 0.84, green: 0.92, blue: 1.0), // Softer, brighter blue
                                layout: .square,
                                textColor: Color(red: 0.00, green: 0.30, blue: 0.75), // Stronger, vibrant deep blue
                                showsChevron: true
                            )
                        }

                        Button {
                            lightHaptic()
                            showAddPatient = true
                        } label: {
                            DashboardCard(
                                title: "Add Patient",
                                subtitle: "Create profile",
                                systemImage: "person.crop.circle.badge.plus",
                                bgColor: Color(red: 0.88, green: 0.90, blue: 0.98), // Soft Indigo Tint
                                layout: .square,
                                textColor: Color(red: 0.22, green: 0.24, blue: 0.60), // Deep Indigo-Blue
                                showsChevron: true
                            )
                        }

                        Button {
                            lightHaptic()
                            showPatientList = true
                        } label: {
                            DashboardCard(
                                title: "View Patients",
                                subtitle: "Browse histories",
                                systemImage: "folder.fill",
                                bgColor: Color(red: 0.90, green: 0.91, blue: 0.92), // Deeper soft gray with neutral tone
                                layout: .square,
                                textColor: Color(red: 0.14, green: 0.15, blue: 0.17), // Cooler charcoal gray
                                showsChevron: true
                            )
                        }

                        Button {
                            lightHaptic()
                            showClinicalTips = true
                        } label: {
                            DashboardCard(
                                title: "Clinical Tips",
                                subtitle: "Evidence-based advice",
                                systemImage: "lightbulb.fill",
                                bgColor: Color(red: 0.85, green: 0.96, blue: 0.92), // Brighter mint aqua
                                layout: .square,
                                textColor: Color(red: 0.00, green: 0.38, blue: 0.30), // Confident green-blue
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
