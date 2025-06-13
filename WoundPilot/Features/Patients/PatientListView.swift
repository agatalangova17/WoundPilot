import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PatientListView: View {
    @State private var patients: [Patient] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading patients...")
            } else if patients.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No patients found")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    Text("Start by adding a patient.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(patients) { patient in
                    NavigationLink(destination: PatientDetailView(patient: patient)) {
                        VStack(alignment: .leading) {
                            Text(patient.name)
                                .font(.headline)
                            Text("DOB: \(patient.dateOfBirth.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Your Patients")
        .onAppear(perform: loadPatients)
    }
    
    private func loadPatients() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not logged in"
            self.isLoading = false
            return
        }

        isLoading = true
        let db = Firestore.firestore()

        db.collection("patients")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "Failed to load patients: \(error.localizedDescription)"
                        return
                    }

                    if let documents = snapshot?.documents {
                        self.patients = documents.compactMap { doc in
                            let data = doc.data()
                            guard let name = data["name"] as? String,
                                  let dobTimestamp = data["dateOfBirth"] as? Timestamp else {
                                return nil
                            }

                            return Patient(
                                id: doc.documentID,
                                name: name,
                                dateOfBirth: dobTimestamp.dateValue()
                            )
                        }
                    }
                }
            }
    }
}
