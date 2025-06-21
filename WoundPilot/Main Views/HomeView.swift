import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var showProfile = false
    @State private var userName: String = ""

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

                    // MARK: - Quick Wound Scan
                    Button {
                        lightHaptic()
                        showQuickScan()
                    } label: {
                        DashboardCard(
                            title: "Quick Wound Scan",
                            subtitle: "Capture and analyze instantly",
                            systemImage: "bolt.fill",
                            bgColor: Color.accentBlue.opacity(0.3),
                            layout: .large,
                            textColor: .primary,
                            showsChevron: true
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Side-by-Side Cards
                    HStack(spacing: 16) {
                        Button {
                            lightHaptic()
                            showAddPatient = true
                        } label: {
                            DashboardCard(
                                title: "Add Patient",
                                subtitle: "Create profile",
                                systemImage: "person.crop.circle.badge.plus",
                                bgColor: Color.primaryBlue,
                                layout: .square,
                                textColor: .white,
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
                                bgColor: Color.gray.opacity(0.15),
                                layout: .square,
                                textColor: .primary,
                                showsChevron: true
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(isPresented: $showAddPatient) {
                AddPatientView()
            }
            .navigationDestination(isPresented: $showPatientList) {
                PatientListView()
            }
            .navigationDestination(isPresented: $showProfile) {
                ProfileView(isUserLoggedIn: $isUserLoggedIn)
            }
        }
    }

    func showQuickScan() {
        // Use navigation by presenting a hidden NavigationLink dynamically
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let root = UIHostingController(rootView: WoundImageSourceView(selectedPatient: nil))
            window.rootViewController?.present(root, animated: true, completion: nil)
        }
    }

    // MARK: - Helpers
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
