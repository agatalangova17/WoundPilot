import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct PatientListView: View {
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var patients: [Patient] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var patientToDelete: Patient?
    @State private var showDeleteConfirmation = false

    @State private var selectedPatient: Patient?
    @State private var showPatientDetail = false

    @State private var searchText = ""

    var filteredPatients: [Patient] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return patients
        } else {
            return patients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView(LocalizedStrings.loadingPatients)
                        .padding()
                } else if filteredPatients.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text(LocalizedStrings.noPatientsFound)
                            .font(.title3)
                            .foregroundColor(.primary)

                        Text(LocalizedStrings.startByAddingPatient)
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

                                        Text("\(LocalizedStrings.dateOfBirth): \(formatDOB(patient.dateOfBirth))")
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
                                    Label(LocalizedStrings.deletePatientAction, systemImage: "trash")
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
            .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue)) // formatting & search prompt
            .searchable(text: $searchText, prompt: LocalizedStrings.searchPatientsPrompt)
            .navigationTitle(LocalizedStrings.yourPatientsTitle)
            .onAppear(perform: loadPatients)
            .alert(LocalizedStrings.deletePatientAlertTitle, isPresented: $showDeleteConfirmation) {
                Button(LocalizedStrings.deleteAction, role: .destructive) {
                    if let patient = patientToDelete {
                        deletePatientAndAllWounds(patient: patient)
                    }
                }
                Button(LocalizedStrings.cancel, role: .cancel) {}
            }
            .navigationDestination(isPresented: $showPatientDetail) {
                if let patient = selectedPatient {
                    PatientDetailView(patient: patient)
                }
            }
            // Optional inline error (kept minimal)
            .overlay {
                if let errorMessage, !errorMessage.isEmpty {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.footnote)
                            .padding(10)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                            .padding(.bottom, 12)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func formatDOB(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return df.string(from: date)
    }

    private func loadPatients() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = LocalizedStrings.userNotLoggedIn
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
                        self.errorMessage = LocalizedStrings.failedToLoadPatients(error.localizedDescription)
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
            .getDocuments { snapshot, _ in
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
                        self.errorMessage = LocalizedStrings.failedToDeletePatient(err.localizedDescription)
                    } else {
                        loadPatients()
                    }
                }
            }
    }
}
