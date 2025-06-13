import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var userName: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                // Welcome Message
                VStack(spacing: 8) {
                    Text("Hi \(userName.split(separator: " ").first.map(String.init) ?? "there")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Start by adding a patient or view your existing patients.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }

                NavigationLink(
                    destination: WoundImageSourceView(
                        selectedPatient: nil as Patient? // Optional patient
                    )
                ) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Quick Analysis")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
                
                // Add New Patient
                NavigationLink(destination: AddPatientView(), isActive: $showAddPatient) {
                    EmptyView()
                }

                Button(action: {
                    showAddPatient = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Patient")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // View Existing Patients
                NavigationLink(destination: PatientListView(), isActive: $showPatientList) {
                    EmptyView()
                }

                Button(action: {
                    showPatientList = true
                }) {
                    HStack {
                        Image(systemName: "person.3.fill")
                        Text("View Existing Patients")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }

                Spacer()

                // Log Out Button
                Button(action: {
                    do {
                        try Auth.auth().signOut()
                        isUserLoggedIn = false
                    } catch {
                        print("Logout failed: \(error)")
                    }
                }) {
                    Text("Log Out")
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }

            }
            .padding()
            .onAppear {
                fetchUserName()
            }

        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // 🔧 Moved inside the View so it can access @State
    func fetchUserName() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                userName = document.get("name") as? String ?? ""
            }
        }
    }
}
