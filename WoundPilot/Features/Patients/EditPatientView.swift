import SwiftUI
import Firebase
import FirebaseAuth

struct EditPatientView: View {
    @Environment(\.dismiss) var dismiss
    let patient: Patient

    @State private var name: String
    @State private var dateOfBirth: Date
    @State private var sex: String
    @State private var isDiabetic: Bool
    @State private var isSmoker: Bool
    @State private var hasPAD: Bool
    @State private var hasMobilityIssues: Bool
    @State private var hasBloodPressureIssues: Bool
    @State private var weight: String
    @State private var allergies: String

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(patient: Patient) {
        self.patient = patient
        _name = State(initialValue: patient.name)
        _dateOfBirth = State(initialValue: patient.dateOfBirth)
        _sex = State(initialValue: patient.sex ?? "")
        _isDiabetic = State(initialValue: patient.isDiabetic ?? false)
        _isSmoker = State(initialValue: patient.isSmoker ?? false)
        _hasPAD = State(initialValue: patient.hasPAD ?? false)
        _hasMobilityIssues = State(initialValue: patient.hasMobilityIssues ?? false)
        _hasBloodPressureIssues = State(initialValue: patient.hasBloodPressureIssues ?? false)
        _weight = State(initialValue: patient.weight != nil ? String(format: "%.1f", patient.weight!) : "")
        _allergies = State(initialValue: patient.allergies ?? "")
    }

    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Full Name", text: $name)
                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                TextField("Sex", text: $sex)
            }

            Section(header: Text("Clinical Details")) {
                Toggle("Diabetic", isOn: $isDiabetic)
                Toggle("Smoker", isOn: $isSmoker)
                Toggle("Peripheral Artery Disease", isOn: $hasPAD)
                Toggle("Mobility Issues", isOn: $hasMobilityIssues)
                Toggle("Blood Pressure Issues", isOn: $hasBloodPressureIssues)
                TextField("Weight (kg)", text: $weight)
                    .keyboardType(.decimalPad)
                TextField("Allergies", text: $allergies)
            }

            Section {
                if isSaving {
                    ProgressView("Saving...")
                } else {
                    Button("Save Changes") {
                        saveChanges()
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Edit Patient")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }

        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let docRef = db.collection("patients").document(patient.id)

        var data: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "sex": sex.trimmingCharacters(in: .whitespaces),
            "isDiabetic": isDiabetic,
            "isSmoker": isSmoker,
            "hasPAD": hasPAD,
            "hasMobilityIssues": hasMobilityIssues,
            "hasBloodPressureIssues": hasBloodPressureIssues,
            "ownerId": userId
        ]

        if let weightValue = Double(weight.trimmingCharacters(in: .whitespaces)) {
            data["weight"] = weightValue
        }

        if !allergies.trimmingCharacters(in: .whitespaces).isEmpty {
            data["allergies"] = allergies.trimmingCharacters(in: .whitespaces)
        }

        docRef.updateData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to update: \(error.localizedDescription)"
            } else {
                dismiss()
            }
        }
    }
}

