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
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Avatar & Welcome Section
                    VStack(spacing: 12) {
                        Image("avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 4)

                        Text("Welcome back, Dr. \(userName)!")
                            .font(.title3.bold())

                        Text(formattedDate())
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    // MARK: - Main Actions Section
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
                    .padding(.horizontal)

                    Spacer()

                    // MARK: - Log Out
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
                .padding()
            }
            .onAppear(perform: fetchUserName)
            .navigationDestination(isPresented: $showAddPatient) {
                AddPatientView()
            }
            .navigationDestination(isPresented: $showPatientList) {
                PatientListView()
            }
        }
    }

    // MARK: - Fetch User Name
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
