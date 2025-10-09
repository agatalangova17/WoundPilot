import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditPatientView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var langManager = LocalizationManager.shared

    let patient: Patient

    @State private var name: String
    @State private var dateOfBirth: Date
    @State private var sexCode: String
    private let sexCodes = ["unspecified", "male", "female"]

    // MARK: Comorbidities
    @State private var hasDiabetes: Bool?
    @State private var hasPAD: Bool?
    @State private var hasVenousDisease: Bool?
    @State private var isImmunosuppressed: Bool?
    
    // MARK: Mobility
    @State private var mobilityStatus: MobilityStatus?
    @State private var canOffload: Bool?
    
    // MARK: Medications & Risk
    @State private var isOnAnticoagulants: Bool?
    @State private var isSmoker: Bool?
    
    // MARK: Allergies
    @State private var allergyToAdhesives: Bool?
    @State private var allergyToIodine: Bool?
    @State private var allergyToSilver: Bool?
    @State private var allergyToLatex: Bool?
    
    // MARK: Optional Details
    @State private var weight: String
    @State private var otherAllergies: String
    @State private var notes: String

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(patient: Patient) {
        self.patient = patient
        _name = State(initialValue: patient.name)
        _dateOfBirth = State(initialValue: patient.dateOfBirth)
        _sexCode = State(initialValue: EditPatientView.computeSexCode(from: patient.sex))
        
        _hasDiabetes = State(initialValue: patient.hasDiabetes)
        _hasPAD = State(initialValue: patient.hasPAD)
        _hasVenousDisease = State(initialValue: patient.hasVenousDisease)
        _isImmunosuppressed = State(initialValue: patient.isImmunosuppressed)
        
        _mobilityStatus = State(initialValue: patient.mobilityStatus)
        _canOffload = State(initialValue: patient.canOffload)
        
        _isOnAnticoagulants = State(initialValue: patient.isOnAnticoagulants)
        _isSmoker = State(initialValue: patient.isSmoker)
        
        _allergyToAdhesives = State(initialValue: patient.allergyToAdhesives)
        _allergyToIodine = State(initialValue: patient.allergyToIodine)
        _allergyToSilver = State(initialValue: patient.allergyToSilver)
        _allergyToLatex = State(initialValue: patient.allergyToLatex)
        
        _weight = State(initialValue: patient.weight != nil ? String(format: "%.1f", patient.weight!) : "")
        _otherAllergies = State(initialValue: patient.otherAllergies ?? "")
        _notes = State(initialValue: patient.notes ?? "")
    }

    var body: some View {
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

            // MARK: Medical History
            Section(header: Text("Medical History")) {
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
                
                if let mobility = mobilityStatus, mobility != .independent {
                    ThreeStateToggle(title: "Can Patient Offload Weight?", state: $canOffload)
                }
            }

            // MARK: Dressing Allergies
            Section(header: Text("Known Dressing Allergies")) {
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
                    Button("Save Changes") { saveChanges() }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Edit Patient")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func computeSexCode(from raw: String?) -> String {
        let v = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["male", "m", "muž"].contains(v) { return "male" }
        if ["female", "f", "žena"].contains(v) { return "female" }
        if ["unspecified", "unknown", "neurčené"].contains(v) { return "unspecified" }
        return "unspecified"
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
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }

        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let docRef = db.collection("patients").document(patient.id)

        var data: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "sex": sexCode,
            "ownerId": userId
        ]

        // Add or delete optional clinical fields
        if let val = hasDiabetes {
            data["hasDiabetes"] = val
        } else {
            data["hasDiabetes"] = FieldValue.delete()
        }
        
        if let val = hasPAD {
            data["hasPAD"] = val
        } else {
            data["hasPAD"] = FieldValue.delete()
        }
        
        if let val = hasVenousDisease {
            data["hasVenousDisease"] = val
        } else {
            data["hasVenousDisease"] = FieldValue.delete()
        }
        
        if let val = isImmunosuppressed {
            data["isImmunosuppressed"] = val
        } else {
            data["isImmunosuppressed"] = FieldValue.delete()
        }
        
        if let val = isOnAnticoagulants {
            data["isOnAnticoagulants"] = val
        } else {
            data["isOnAnticoagulants"] = FieldValue.delete()
        }
        
        if let val = isSmoker {
            data["isSmoker"] = val
        } else {
            data["isSmoker"] = FieldValue.delete()
        }
        
        if let mobility = mobilityStatus {
            data["mobilityStatus"] = mobility.rawValue
        } else {
            data["mobilityStatus"] = FieldValue.delete()
        }
        
        if let val = canOffload {
            data["canOffload"] = val
        } else {
            data["canOffload"] = FieldValue.delete()
        }
        
        if let val = allergyToAdhesives {
            data["allergyToAdhesives"] = val
        } else {
            data["allergyToAdhesives"] = FieldValue.delete()
        }
        
        if let val = allergyToIodine {
            data["allergyToIodine"] = val
        } else {
            data["allergyToIodine"] = FieldValue.delete()
        }
        
        if let val = allergyToSilver {
            data["allergyToSilver"] = val
        } else {
            data["allergyToSilver"] = FieldValue.delete()
        }
        
        if let val = allergyToLatex {
            data["allergyToLatex"] = val
        } else {
            data["allergyToLatex"] = FieldValue.delete()
        }

        if let weightValue = parseLocalizedDouble(weight) {
            data["weight"] = weightValue
        } else {
            data["weight"] = FieldValue.delete()
        }

        let trimmedOtherAllergies = otherAllergies.trimmingCharacters(in: .whitespaces)
        if !trimmedOtherAllergies.isEmpty {
            data["otherAllergies"] = trimmedOtherAllergies
        } else {
            data["otherAllergies"] = FieldValue.delete()
        }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        if !trimmedNotes.isEmpty {
            data["notes"] = trimmedNotes
        } else {
            data["notes"] = FieldValue.delete()
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
