import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddPatient = false
    @State private var showPatientList = false

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                // Welcome Message
                VStack(spacing: 8) {
                    Text("Welcome to WoundPilot")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Start by adding a patient or view your existing patients.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
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
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
