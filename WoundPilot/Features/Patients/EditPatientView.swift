import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditPatientView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var langManager = LocalizationManager.shared

    let patient: Patient

    @State private var name: String
    @State private var dateOfBirth: Date

    // Store a stable code; UI shows localized label
    @State private var sexCode: String
    private let sexCodes = ["unspecified", "male", "female"]

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
        _sexCode = State(initialValue: EditPatientView.computeSexCode(from: patient.sex))
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
            // MARK: - Basic Info
            Section(header: Text(LocalizedStrings.basicInfoSection)) {
                TextField(LocalizedStrings.fullNameLabel, text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)

                DatePicker(LocalizedStrings.dateOfBirth, selection: $dateOfBirth, displayedComponents: .date)

                Picker(LocalizedStrings.sexLabel, selection: $sexCode) {
                    ForEach(sexCodes, id: \.self) { code in
                        Text(localizedSexTitle(code)).tag(code)
                    }
                }
            }

            // MARK: - Clinical Details
            Section(header: Text(LocalizedStrings.clinicalDetailsSection)) {
                Toggle(LocalizedStrings.diabetic, isOn: $isDiabetic)
                Toggle(LocalizedStrings.smoker, isOn: $isSmoker)
                Toggle(LocalizedStrings.peripheralArteryDisease, isOn: $hasPAD)
                Toggle(LocalizedStrings.mobilityIssues, isOn: $hasMobilityIssues)
                Toggle(LocalizedStrings.bloodPressureIssues, isOn: $hasBloodPressureIssues)

                TextField(LocalizedStrings.weightKgPlaceholder, text: $weight)
                    .keyboardType(.decimalPad)

                TextField(LocalizedStrings.knownAllergiesPlaceholder, text: $allergies)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
            }

            // MARK: - Actions
            Section {
                if isSaving {
                    ProgressView(LocalizedStrings.saving)
                } else {
                    Button(LocalizedStrings.saveChangesButton) {
                        saveChanges()
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue)) // date/format localization
        .navigationTitle(LocalizedStrings.editPatientTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // Map stored/legacy values (possibly localized) to stable codes
    private static func computeSexCode(from raw: String?) -> String {
        let v = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["male", "m", "muž"].contains(v) { return "male" }
        if ["female", "f", "žena"].contains(v) { return "female" }
        if ["unspecified", "unknown", "neurčené"].contains(v) { return "unspecified" }
        return "unspecified"
    }

    private func localizedSexTitle(_ code: String) -> String {
        switch code {
        case "male": return LocalizedStrings.sexMale
        case "female": return LocalizedStrings.sexFemale
        default: return LocalizedStrings.sexUnspecified
        }
    }

    // MARK: - Save
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedStrings.userNotLoggedIn
            return
        }

        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let docRef = db.collection("patients").document(patient.id)

        var data: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "sex": sexCode, // store stable code
            "isDiabetic": isDiabetic,
            "isSmoker": isSmoker,
            "hasPAD": hasPAD,
            "hasMobilityIssues": hasMobilityIssues,
            "hasBloodPressureIssues": hasBloodPressureIssues,
            "ownerId": userId
        ]

        if let weightValue = Double(weight.trimmingCharacters(in: .whitespaces)) {
            data["weight"] = weightValue
        } else {
            data["weight"] = FieldValue.delete()
        }

        if !allergies.trimmingCharacters(in: .whitespaces).isEmpty {
            data["allergies"] = allergies.trimmingCharacters(in: .whitespaces)
        } else {
            data["allergies"] = FieldValue.delete()
        }

        docRef.updateData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = LocalizedStrings.failedToUpdate(error.localizedDescription)
            } else {
                dismiss()
            }
        }
    }
}
