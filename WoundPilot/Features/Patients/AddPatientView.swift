import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddPatientView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var dateOfBirth = Date()

    // Optional clinical fields
    @State private var sex = "Unspecified"
    @State private var isDiabetic = false
    @State private var isSmoker = false
    @State private var hasPAD = false
    @State private var hasMobilityIssues = false
    @State private var hasBloodPressureIssues = false
    @State private var weight: String = ""
    @State private var allergies: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    let sexOptions = ["Unspecified", "Male", "Female"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Full Name", text: $name)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    Picker("Sex", selection: $sex) {
                        ForEach(sexOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("Optional Clinical Info")) {
                    Toggle("Diabetic", isOn: $isDiabetic)
                    Toggle("Smoker", isOn: $isSmoker)
                    Toggle("Peripheral Artery Disease", isOn: $hasPAD)
                    Toggle("Mobility Issues", isOn: $hasMobilityIssues)
                    Toggle("Blood Pressure Issues", isOn: $hasBloodPressureIssues)
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Known Allergies", text: $allergies)
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

        var data: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "ownerId": userId,
            "createdAt": Timestamp(date: Date()),
            "sex": sex,
            "isDiabetic": isDiabetic,
            "isSmoker": isSmoker,
            "hasPAD": hasPAD,
            "hasMobilityIssues": hasMobilityIssues,
            "hasBloodPressureIssues": hasBloodPressureIssues,
            "weight": Double(weight) ?? NSNull(),
            "allergies": allergies.trimmingCharacters(in: .whitespaces)
        ]

        // Remove empty strings or null fields
        data = data.filter { !("\($0.value)" == "" || $0.value is NSNull) }

        patientRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            } else {
                successMessage = "Patient saved successfully!"
                resetForm()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            }
        }
    }

    private func resetForm() {
        name = ""
        dateOfBirth = Date()
        sex = "Unspecified"
        isDiabetic = false
        isSmoker = false
        hasPAD = false
        hasMobilityIssues = false
        hasBloodPressureIssues = false
        weight = ""
        allergies = ""
    }
}
