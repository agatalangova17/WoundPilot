import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddPatientView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var name: String = ""
    @State private var dateOfBirth = Date()

    // Store stable codes; UI shows localized titles
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

    // NEW: navigate by providing a full Patient to the destination
    @State private var routePatient: Patient?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Patient Info
                Section(header: Text(LocalizedStrings.patientInformationSection)) {
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

                // MARK: - Optional Clinical Info
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

                // MARK: - Actions & Messages
                Section {
                    if isSaving {
                        ProgressView(LocalizedStrings.saving)
                    } else {
                        Button(LocalizedStrings.savePatient) {
                            savePatient()
                        }
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
            // 👉 When routePatient is set, push the detail screen
            .navigationDestination(item: $routePatient) { patient in
                PatientDetailView(patient: patient)
            }
        }
    }

    // Localized title for sex codes (stored value remains a stable code)
    private func localizedSexTitle(_ code: String) -> String {
        switch code {
        case "male": return LocalizedStrings.sexMale
        case "female": return LocalizedStrings.sexFemale
        default: return LocalizedStrings.sexUnspecified
        }
    }

    // MARK: - Save
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
            "sex": sexCode,                           // stable code
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
                errorMessage = LocalizedStrings.failedToSave(error.localizedDescription)
                return
            }

            // Success – build a Patient and route
            successMessage = LocalizedStrings.patientSavedSuccessfully
            let newId = patientRef.documentID

            let newPatient = Patient(
                id: newId,
                name: name.trimmingCharacters(in: .whitespaces),
                dateOfBirth: dateOfBirth,
                sex: sexCode,                                // String?
                isDiabetic: isDiabetic,                      // Bool?
                isSmoker: isSmoker,                          // Bool?
                hasPAD: hasPAD,                              // Bool?
                hasMobilityIssues: hasMobilityIssues,        // Bool?
                hasBloodPressureIssues: hasBloodPressureIssues, // Bool?
                weight: Double(weight),                      // Double?
                allergies: allergies.trimmingCharacters(in: .whitespaces),
                bloodPressure: nil,                          // you don't collect a string here
                diabetesType: isDiabetic ? "unspecified" : "none"
            )

            // Push detail view (don’t dismiss)
            routePatient = newPatient

            // Optional: clear the form so coming back is clean
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
