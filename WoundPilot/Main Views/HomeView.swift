import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var showProfile = false
    @State private var userName: String = ""
    @State private var showContent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Header with Date & Profile
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

                    // MARK: - Large Quick Analysis Card
                    NavigationLink(destination: WoundImageSourceView(selectedPatient: nil)) {
                        DashboardCard(
                            icon: "bolt.fill",
                            title: "Quick Analysis",
                            subtitle: "Snap a wound photo instantly",
                            iconColor: .accentBlue,
                            bgColor: Color.accentBlue.opacity(0.25),
                            layout: .large,
                            textColor: .primary,
                            showsChevron: true
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    }

                    // MARK: - Two Side-by-Side Square Cards
                    HStack(spacing: 16) {
                        Button {
                            showAddPatient = true
                        } label: {
                            DashboardCard(
                                icon: "person.crop.circle.badge.plus",
                                title: "Add Patient",
                                subtitle: "New record",
                                iconColor: .white,
                                bgColor: Color.primaryBlue,
                                layout: .square,
                                textColor: .white,
                                showsChevron: true
                            )
                        }

                        Button {
                            showPatientList = true
                        } label: {
                            DashboardCard(
                                icon: "person.3.fill",
                                title: "View Patients",
                                subtitle: "Saved list",
                                iconColor: .gray,
                                bgColor: Color.gray.opacity(0.1),
                                layout: .square,
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
            .onAppear {
                fetchUserName()
                withAnimation {
                    showContent = true
                }
            }
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
}
