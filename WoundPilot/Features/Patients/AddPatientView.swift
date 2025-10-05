import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddPatientView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var name: String = ""
    @State private var dateOfBirth = Date()

    
    @State private var sexCode = "unspecified"
    private let sexCodes = ["unspecified", "male", "female"]

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
    @State private var routePatient: Patient?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Patient Info
                Section(header: Text(LocalizedStrings.patientInformationSection)) {
                    TextField(LocalizedStrings.fullNameLabel, text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)

                    DatePicker(LocalizedStrings.dateOfBirth, selection: $dateOfBirth, displayedComponents: .date)

                    Picker(LocalizedStrings.sexLabel, selection: $sexCode) {
                        ForEach(sexCodes, id: \.self) { code in
                            Text(localizedSexTitle(code))
                                .tag(code)
                                .accessibilityLabel(Text(localizedSexTitle(code)))
                        }
                    }
                }

                // MARK: Optional Clinical Info
                Section(header: Text(LocalizedStrings.optionalClinicalInfoSection)) {
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

                // MARK: Actions & Messages
                Section {
                    if isSaving {
                        ProgressView(LocalizedStrings.saving)
                    } else {
                        Button(LocalizedStrings.savePatient) { savePatient() }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if let message = errorMessage {
                        Text(message).foregroundColor(.red)
                    }
                    if let message = successMessage {
                        Text(message).foregroundColor(.green)
                    }
                }
            }
            .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
            .navigationTitle(LocalizedStrings.addPatient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStrings.cancel) { dismiss() }
                }
            }
            .navigationDestination(item: $routePatient) { patient in
                PatientDetailView(patient: patient)
            }
        }
    }

    
    private func localizedSexTitle(_ code: String) -> String {
        switch code {
        case "male": return LocalizedStrings.sexMale
        case "female": return LocalizedStrings.sexFemale
        default: return LocalizedStrings.sexUnspecified
        }
    }

    
    private func parseLocalizedDouble(_ text: String) -> Double? {
        let fmt = NumberFormatter()
        fmt.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        fmt.numberStyle = .decimal
        if let n = fmt.number(from: text.trimmingCharacters(in: .whitespaces)) {
            return n.doubleValue
        }
        
        let swapped = text.replacingOccurrences(of: ",", with: ".")
        return Double(swapped)
    }

    // MARK: Save
    private func savePatient() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedStrings.userNotLoggedIn
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
            "sex": sexCode,
            "isDiabetic": isDiabetic,
            "isSmoker": isSmoker,
            "hasPAD": hasPAD,
            "hasMobilityIssues": hasMobilityIssues,
            "hasBloodPressureIssues": hasBloodPressureIssues,
            "allergies": allergies.trimmingCharacters(in: .whitespaces)
        ]

        if let w = parseLocalizedDouble(weight) { data["weight"] = w } 

        // Remove empty string fields
        data = data.filter { key, value in
            if let s = value as? String { return !s.isEmpty }
            return true
        }

        patientRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = LocalizedStrings.failedToSave(error.localizedDescription)
                return
            }

            successMessage = LocalizedStrings.patientSavedSuccessfully
            let newId = patientRef.documentID

            let newPatient = Patient(
                id: newId,
                name: name.trimmingCharacters(in: .whitespaces),
                dateOfBirth: dateOfBirth,
                sex: sexCode,
                isDiabetic: isDiabetic,
                isSmoker: isSmoker,
                hasPAD: hasPAD,
                hasMobilityIssues: hasMobilityIssues,
                hasBloodPressureIssues: hasBloodPressureIssues,
                weight: parseLocalizedDouble(weight),
                allergies: allergies.trimmingCharacters(in: .whitespaces),
                bloodPressure: nil,
                diabetesType: isDiabetic ? "unspecified" : "none"
            )

            routePatient = newPatient
            resetForm()
        }
    }

    private func resetForm() {
        name = ""
        dateOfBirth = Date()
        sexCode = "unspecified"
        isDiabetic = false
        isSmoker = false
        hasPAD = false
        hasMobilityIssues = false
        hasBloodPressureIssues = false
        weight = ""
        allergies = ""
    }
}
