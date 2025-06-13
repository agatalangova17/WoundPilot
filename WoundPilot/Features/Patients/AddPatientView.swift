import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddPatientView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var dateOfBirth = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Full Name", text: $name)

                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                }

                Section {
                    if isSaving {
                        ProgressView("Saving...")
                    } else {
                        Button("Save Patient") {
                            savePatient()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if let message = errorMessage {
                        Text(message)
                            .foregroundColor(.red)
                    }

                    if let message = successMessage {
                        Text(message)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Add Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func savePatient() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        let db = Firestore.firestore()
        let patientRef = db.collection("patients").document()

        let data: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "ownerId": userId,
            "createdAt": Timestamp(date: Date())
        ]

        patientRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            } else {
                successMessage = "Patient saved successfully!"
                name = ""
                dateOfBirth = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            }
        }
    }
}
