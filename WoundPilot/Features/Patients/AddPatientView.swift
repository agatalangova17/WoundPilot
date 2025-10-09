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

    // MARK: Comorbidities (three-state: nil=unknown, true=yes, false=no)
    @State private var hasDiabetes: Bool? = nil
    @State private var hasPAD: Bool? = nil
    @State private var hasVenousDisease: Bool? = nil
    @State private var isImmunosuppressed: Bool? = nil
    
    // MARK: Mobility
    @State private var mobilityStatus: MobilityStatus? = nil
    @State private var canOffload: Bool? = nil
    
    // MARK: Medications & Risk Factors
    @State private var isOnAnticoagulants: Bool? = nil
    @State private var isSmoker: Bool? = nil
    
    // MARK: Dressing Allergies
    @State private var allergyToAdhesives: Bool? = nil
    @State private var allergyToIodine: Bool? = nil
    @State private var allergyToSilver: Bool? = nil
    @State private var allergyToLatex: Bool? = nil
    
    // MARK: Optional Details
    @State private var weight: String = ""
    @State private var otherAllergies: String = ""
    @State private var notes: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var routePatient: Patient?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Basic Info
                Section(header: Text("Patient Information")) {
                    TextField("Full Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)

                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)

                    Picker("Sex", selection: $sexCode) {
                        ForEach(sexCodes, id: \.self) { code in
                            Text(localizedSexTitle(code)).tag(code)
                        }
                    }
                }

                // MARK: Critical Comorbidities
                Section(header: Text("Medical History"),
                        footer: Text("These affect treatment recommendations. Select 'Unknown' if unsure.")) {
                    ThreeStateToggle(title: "Diabetes", state: $hasDiabetes)
                    ThreeStateToggle(title: "Peripheral Arterial Disease (PAD)", state: $hasPAD)
                    ThreeStateToggle(title: "Venous Disease", state: $hasVenousDisease)
                    ThreeStateToggle(title: "Immunosuppressed", state: $isImmunosuppressed)
                }
                
                // MARK: Medications & Risk
                Section(header: Text("Medications & Risk Factors")) {
                    ThreeStateToggle(title: "On Anticoagulants/Blood Thinners", state: $isOnAnticoagulants)
                    ThreeStateToggle(title: "Smoker", state: $isSmoker)
                }

                // MARK: Mobility
                Section(header: Text("Mobility")) {
                    Picker("Mobility Status", selection: $mobilityStatus) {
                        Text("Unknown").tag(nil as MobilityStatus?)
                        ForEach(MobilityStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status as MobilityStatus?)
                        }
                    }
                    
                    // Only show if mobility impaired
                    if let mobility = mobilityStatus,
                       mobility != .independent {
                        ThreeStateToggle(title: "Can Patient Offload Weight?", state: $canOffload)
                    }
                }

                // MARK: Dressing Allergies
                Section(header: Text("Known Dressing Allergies"),
                        footer: Text("Select only if patient has confirmed allergies")) {
                    ThreeStateToggle(title: "Adhesives", state: $allergyToAdhesives)
                    ThreeStateToggle(title: "Iodine", state: $allergyToIodine)
                    ThreeStateToggle(title: "Silver", state: $allergyToSilver)
                    ThreeStateToggle(title: "Latex", state: $allergyToLatex)
                    
                    TextField("Other Allergies (optional)", text: $otherAllergies)
                        .textInputAutocapitalization(.sentences)
                }

                // MARK: Optional Details
                Section(header: Text("Additional Information (Optional)")) {
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Clinical Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }

                // MARK: Actions
                Section {
                    if isSaving {
                        ProgressView("Saving...")
                    } else {
                        Button("Save Patient") { savePatient() }
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
            .navigationTitle("Add Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(item: $routePatient) { patient in
                PatientDetailView(patient: patient)
            }
        }
    }

    private func localizedSexTitle(_ code: String) -> String {
        switch code {
        case "male": return "Male"
        case "female": return "Female"
        default: return "Unspecified"
        }
    }

    private func parseLocalizedDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        
        let fmt = NumberFormatter()
        fmt.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        fmt.numberStyle = .decimal
        if let n = fmt.number(from: trimmed) {
            return n.doubleValue
        }
        
        let swapped = trimmed.replacingOccurrences(of: ",", with: ".")
        return Double(swapped)
    }

    // MARK: Save
    private func savePatient() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
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
            "sex": sexCode
        ]

        // Add optional clinical fields (only if not nil)
        if let val = hasDiabetes { data["hasDiabetes"] = val }
        if let val = hasPAD { data["hasPAD"] = val }
        if let val = hasVenousDisease { data["hasVenousDisease"] = val }
        if let val = isImmunosuppressed { data["isImmunosuppressed"] = val }
        if let val = isOnAnticoagulants { data["isOnAnticoagulants"] = val }
        if let val = isSmoker { data["isSmoker"] = val }
        
        if let mobility = mobilityStatus {
            data["mobilityStatus"] = mobility.rawValue
        }
        if let val = canOffload { data["canOffload"] = val }
        
        if let val = allergyToAdhesives { data["allergyToAdhesives"] = val }
        if let val = allergyToIodine { data["allergyToIodine"] = val }
        if let val = allergyToSilver { data["allergyToSilver"] = val }
        if let val = allergyToLatex { data["allergyToLatex"] = val }
        
        if let w = parseLocalizedDouble(weight) { data["weight"] = w }
        
        let trimmedOtherAllergies = otherAllergies.trimmingCharacters(in: .whitespaces)
        if !trimmedOtherAllergies.isEmpty { data["otherAllergies"] = trimmedOtherAllergies }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        if !trimmedNotes.isEmpty { data["notes"] = trimmedNotes }

        patientRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                return
            }

            successMessage = "Patient saved successfully"
            let newId = patientRef.documentID

            let newPatient = Patient(
                id: newId,
                name: name.trimmingCharacters(in: .whitespaces),
                dateOfBirth: dateOfBirth,
                sex: sexCode,
                hasDiabetes: hasDiabetes,
                hasPAD: hasPAD,
                hasVenousDisease: hasVenousDisease,
                isImmunosuppressed: isImmunosuppressed,
                mobilityStatus: mobilityStatus,
                canOffload: canOffload,
                isOnAnticoagulants: isOnAnticoagulants,
                isSmoker: isSmoker,
                allergyToAdhesives: allergyToAdhesives,
                allergyToIodine: allergyToIodine,
                allergyToSilver: allergyToSilver,
                allergyToLatex: allergyToLatex,
                weight: parseLocalizedDouble(weight),
                otherAllergies: trimmedOtherAllergies.isEmpty ? nil : trimmedOtherAllergies,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )

            routePatient = newPatient
            resetForm()
        }
    }

    private func resetForm() {
        name = ""
        dateOfBirth = Date()
        sexCode = "unspecified"
        hasDiabetes = nil
        hasPAD = nil
        hasVenousDisease = nil
        isImmunosuppressed = nil
        mobilityStatus = nil
        canOffload = nil
        isOnAnticoagulants = nil
        isSmoker = nil
        allergyToAdhesives = nil
        allergyToIodine = nil
        allergyToSilver = nil
        allergyToLatex = nil
        weight = ""
        otherAllergies = ""
        notes = ""
    }
}

// MARK: - Three-State Toggle Helper
struct ThreeStateToggle: View {
    let title: String
    @Binding var state: Bool?
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker("", selection: $state) {
                Text("Unknown").tag(nil as Bool?)
                Text("No").tag(false as Bool?)
                Text("Yes").tag(true as Bool?)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
    }
}
