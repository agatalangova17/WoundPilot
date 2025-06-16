import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var userName: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // MARK: - Header (Date + Title)
                VStack(alignment: .leading, spacing: 6) {
                    Text(formattedDate())
                        .font(.footnote)
                        .foregroundColor(.gray)

                    Text("Dashboard")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // MARK: - Main Action Buttons
                VStack(spacing: 16) {
                    NavigationLink(destination: WoundImageSourceView(selectedPatient: nil)) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Quick Analysis")
                        }
                        .font(.headline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }

                    Button {
                        showAddPatient = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Patient")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryBlue)
                        .cornerRadius(12)
                    }

                    Button {
                        showPatientList = true
                    } label: {
                        HStack {
                            Image(systemName: "person.3.fill")
                            Text("View Patients")
                        }
                        .font(.headline)
                        .foregroundColor(.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentBlue.opacity(0.12))
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal)

                Spacer()

                // MARK: - Log Out Button
                Button(action: {
                    do {
                        try Auth.auth().signOut()
                        isUserLoggedIn = false
                    } catch {
                        print("Logout failed: \(error)")
                    }
                }) {
                    Text("Log Out")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(8)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(8)
                }
                .padding(.bottom, 20)
            }
            .padding(.top)
            .onAppear(perform: fetchUserName)
            .navigationDestination(isPresented: $showAddPatient) {
                AddPatientView()
            }
            .navigationDestination(isPresented: $showPatientList) {
                PatientListView()
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
