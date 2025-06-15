import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct PatientListView: View {
    @State private var patients: [Patient] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var patientToDelete: Patient?
    @State private var showDeleteConfirmation = false

    @State private var selectedPatient: Patient?
    @State private var showPatientDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Loading patients...")
                        .padding()
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
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(patients) { patient in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(patient.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("Date of Birth: \(patient.dateOfBirth.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    patientToDelete = patient
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .onTapGesture {
                                selectedPatient = patient
                                showPatientDetail = true
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Your Patients")
            .onAppear(perform: loadPatients)
            .alert("Delete this patient and all their wound photos?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let patient = patientToDelete {
                        deletePatientAndAllWounds(patient: patient)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .navigationDestination(isPresented: $showPatientDetail) {
                if let patient = selectedPatient {
                    PatientDetailView(patient: patient)
                }
            }
        }
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

    private func deletePatientAndAllWounds(patient: Patient) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // 1. Delete all wounds
        db.collection("wounds")
            .whereField("patientId", isEqualTo: patient.id)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    for doc in documents {
                        if let url = doc.data()["imageURL"] as? String {
                            let storageRef = storage.reference(forURL: url)
                            storageRef.delete(completion: nil)
                        }
                        doc.reference.delete()
                    }
                }

                // 2. Delete patient
                db.collection("patients").document(patient.id).delete { err in
                    if let err = err {
                        print("Error deleting patient: \(err)")
                    } else {
                        // 3. Refresh list
                        loadPatients()
                    }
                }
            }
    }
}
