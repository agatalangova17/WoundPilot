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
    @State private var hasMobilityImpairment: Bool?
    @State private var canOffload: Bool?
    
    // MARK: Medications
    @State private var isOnAnticoagulants: Bool?
    
    // MARK: Allergies
    @State private var allergyToAdhesives: Bool?
    @State private var allergyToIodine: Bool?
    @State private var allergyToSilver: Bool?
    @State private var allergyToLatex: Bool?
    @State private var otherAllergies: String

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
        
        _hasMobilityImpairment = State(initialValue: patient.hasMobilityImpairment)
        _canOffload = State(initialValue: patient.canOffload)
        
        _isOnAnticoagulants = State(initialValue: patient.isOnAnticoagulants)
        
        _allergyToAdhesives = State(initialValue: patient.allergyToAdhesives)
        _allergyToIodine = State(initialValue: patient.allergyToIodine)
        _allergyToSilver = State(initialValue: patient.allergyToSilver)
        _allergyToLatex = State(initialValue: patient.allergyToLatex)
        
        _otherAllergies = State(initialValue: patient.otherAllergies ?? "")
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Basic Info
                    VStack(spacing: 16) {
                        SectionHeader(icon: "person.fill", title: "Patient Information", color: .blue)
                        
                        VStack(spacing: 12) {
                            TextField("Full Name", text: $name)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled(true)

                            DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)

                            Picker("Sex", selection: $sexCode) {
                                ForEach(sexCodes, id: \.self) { code in
                                    Text(localizedSexTitle(code)).tag(code)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .cardStyle()

                    // MARK: Medical History
                    VStack(spacing: 16) {
                        SectionHeader(icon: "heart.text.square.fill", title: "Medical History", color: .red)
                        
                        VStack(spacing: 10) {
                            ThreeStateToggle(title: "Diabetes", state: $hasDiabetes)
                            Divider().padding(.horizontal, 12)
                            ThreeStateToggle(title: "Peripheral Arterial Disease", state: $hasPAD)
                            Divider().padding(.horizontal, 12)
                            ThreeStateToggle(title: "Venous Disease", state: $hasVenousDisease)
                            Divider().padding(.horizontal, 12)
                            ThreeStateToggle(title: "Immunosuppressed", state: $isImmunosuppressed)
                        }
                    }
                    .cardStyle()
                    
                    // MARK: Medications
                    VStack(spacing: 16) {
                        SectionHeader(icon: "pills.fill", title: "Medications", color: .orange)
                        
                        ThreeStateToggle(title: "On Blood Thinners", state: $isOnAnticoagulants)
                    }
                    .cardStyle()

                    // MARK: Mobility
                    VStack(spacing: 16) {
                        SectionHeader(icon: "figure.walk", title: "Mobility", color: .purple)
                        
                        VStack(spacing: 10) {
                            ThreeStateToggle(title: "Mobility Impairment", state: $hasMobilityImpairment)
                            
                            if hasMobilityImpairment == true {
                                Divider().padding(.horizontal, 12)
                                ThreeStateToggle(title: "Can Offload Weight?", state: $canOffload)
                            }
                        }
                    }
                    .cardStyle()

                    // MARK: Allergies
                    VStack(spacing: 16) {
                        SectionHeader(icon: "exclamationmark.triangle.fill", title: "Dressing Allergies", color: .pink)
                        
                        VStack(spacing: 10) {
                            ThreeStateToggle(title: "Adhesives", state: $allergyToAdhesives)
                            Divider().padding(.horizontal, 12)
                            ThreeStateToggle(title: "Iodine", state: $allergyToIodine)
                            Divider().padding(.horizontal, 12)
                            ThreeStateToggle(title: "Silver", state: $allergyToSilver)
                            Divider().padding(.horizontal, 12)
                            ThreeStateToggle(title: "Latex", state: $allergyToLatex)
                            
                            if !otherAllergies.isEmpty || allergyToAdhesives == true || allergyToIodine == true || allergyToSilver == true || allergyToLatex == true {
                                Divider().padding(.horizontal, 12)
                                TextField("Other Allergies (optional)", text: $otherAllergies)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .textInputAutocapitalization(.sentences)
                            }
                        }
                    }
                    .cardStyle()

                    // MARK: Save Button
                    Button {
                        saveChanges()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Changes")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .disabled(isSaving)

                    if let message = errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
        
        if let val = hasMobilityImpairment {
            data["hasMobilityImpairment"] = val
        } else {
            data["hasMobilityImpairment"] = FieldValue.delete()
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

        let trimmedOtherAllergies = otherAllergies.trimmingCharacters(in: .whitespaces)
        if !trimmedOtherAllergies.isEmpty {
            data["otherAllergies"] = trimmedOtherAllergies
        } else {
            data["otherAllergies"] = FieldValue.delete()
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
