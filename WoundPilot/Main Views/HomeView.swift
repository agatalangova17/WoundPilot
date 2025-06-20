import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddPatient = false
    @State private var showPatientList = false
    @State private var userName: String = ""
    @State private var showContent = false

    var body: some View {
        NavigationStack {
            ZStack {
                

                VStack(spacing: 24) {
                    // MARK: - Avatar + Greeting
                    VStack(spacing: 16) {
                        Image("avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: showContent)
                            .padding(.bottom, 9)

                        Text("Welcome back, \(userName)!")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: showContent)

                        VStack(spacing: 4) {
                            Text(formattedDate())
                                .font(.subheadline)
                                .foregroundColor(.black)

                            Divider()
                                .frame(width: 160)
                                .opacity(0.08)
                                .padding(.top, 2)
                                .padding(.bottom, 9)

                    

                           
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeIn(duration: 1.0).delay(0.4), value: showContent)
                    }
                    .padding(.top)

                    // MARK: - Main Actions
                    VStack(spacing: 14) {
                        
                        //Quick analysis
                        NavigationLink(destination: WoundImageSourceView(selectedPatient: nil)) {
                            Label("Quick Analysis", systemImage: "bolt.fill")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.accentBlue)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(Color.accentBlue.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentBlue.opacity(0.4), lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }

                        // Add New Patient
                        Button {
                            showAddPatient = true
                        } label: {
                            Label("Add New Patient", systemImage: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(Color.primaryBlue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primaryBlue.opacity(0.4), lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }

                        // View Patients
                        Button {
                            showPatientList = true
                        } label: {
                            Label("View Patients", systemImage: "person.3.fill")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: showContent)

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
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(6)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
                }
                .padding(.horizontal)
            }
            .onAppear {
                fetchUserName()
                withAnimation {
                    showContent = true
                }
            }
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
