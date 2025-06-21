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

    @State private var searchText = ""

    var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return patients
        } else {
            return patients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Loading patients...")
                        .padding()
                } else if filteredPatients.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No patients found")
                            .font(.title3)
                            .foregroundColor(.primary)

                        Text("Start by adding a patient.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredPatients) { patient in
                            Button {
                                selectedPatient = patient
                                showPatientDetail = true
                            } label: {
                                HStack(spacing: 16) {
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(patient.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text("Date of Birth: \(patient.dateOfBirth.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(.systemGray6))
                                        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
                                )
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    patientToDelete = patient
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete Patient", systemImage: "trash")
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
            .searchable(text: $searchText, prompt: "Search patients by name")
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
                                dateOfBirth: dobTimestamp.dateValue(),
                                sex: data["sex"] as? String,
                                isDiabetic: data["isDiabetic"] as? Bool,
                                isSmoker: data["isSmoker"] as? Bool,
                                hasPAD: data["hasPAD"] as? Bool,
                                hasMobilityIssues: data["hasMobilityIssues"] as? Bool,
                                hasBloodPressureIssues: data["hasBloodPressureIssues"] as? Bool,
                                weight: data["weight"] as? Double,
                                allergies: data["allergies"] as? String,
                                bloodPressure: data["bloodPressure"] as? String,
                                diabetesType: data["diabetesType"] as? String
                            )
                        }
                    }
                }
            }
    }

    private func deletePatientAndAllWounds(patient: Patient) {
        let db = Firestore.firestore()
        let storage = Storage.storage()

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

                db.collection("patients").document(patient.id).delete { err in
                    if let err = err {
                        print("Error deleting patient: \(err)")
                    } else {
                        loadPatients()
                    }
                }
            }
    }
}
