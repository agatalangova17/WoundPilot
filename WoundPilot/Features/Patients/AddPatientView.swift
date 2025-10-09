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

    // MARK: Comorbidities
    @State private var hasDiabetes: Bool? = nil
    @State private var hasPAD: Bool? = nil
    @State private var hasVenousDisease: Bool? = nil
    @State private var isImmunosuppressed: Bool? = nil
    
    // MARK: Mobility
    @State private var hasMobilityImpairment: Bool? = nil
    @State private var canOffload: Bool? = nil
    
    // MARK: Medications
    @State private var isOnAnticoagulants: Bool? = nil
    
    // MARK: Dressing Allergies
    @State private var allergyToAdhesives: Bool? = nil
    @State private var allergyToIodine: Bool? = nil
    @State private var allergyToSilver: Bool? = nil
    @State private var allergyToLatex: Bool? = nil
    @State private var otherAllergies: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var routePatient: Patient?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: Basic Info Card
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

                        // MARK: Medical History Card
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
                        
                        // MARK: Medications Card
                        VStack(spacing: 16) {
                            SectionHeader(icon: "pills.fill", title: "Medications", color: .orange)
                            
                            ThreeStateToggle(title: "On Blood Thinners", state: $isOnAnticoagulants)
                        }
                        .cardStyle()

                        // MARK: Mobility Card
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

                        // MARK: Allergies Card
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
                            savePatient()
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Patient")
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                        .padding(.top, 8)

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

    // MARK: Save
    private func savePatient() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }

        isSaving = true
        errorMessage = nil

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
        if let val = hasMobilityImpairment { data["hasMobilityImpairment"] = val }
        if let val = canOffload { data["canOffload"] = val }
        if let val = allergyToAdhesives { data["allergyToAdhesives"] = val }
        if let val = allergyToIodine { data["allergyToIodine"] = val }
        if let val = allergyToSilver { data["allergyToSilver"] = val }
        if let val = allergyToLatex { data["allergyToLatex"] = val }
        
        let trimmedOtherAllergies = otherAllergies.trimmingCharacters(in: .whitespaces)
        if !trimmedOtherAllergies.isEmpty { data["otherAllergies"] = trimmedOtherAllergies }

        patientRef.setData(data) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                return
            }

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
                hasMobilityImpairment: hasMobilityImpairment,
                canOffload: canOffload,
                isOnAnticoagulants: isOnAnticoagulants,
                allergyToAdhesives: allergyToAdhesives,
                allergyToIodine: allergyToIodine,
                allergyToSilver: allergyToSilver,
                allergyToLatex: allergyToLatex,
                otherAllergies: trimmedOtherAllergies.isEmpty ? nil : trimmedOtherAllergies
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
        hasMobilityImpairment = nil
        canOffload = nil
        isOnAnticoagulants = nil
        allergyToAdhesives = nil
        allergyToIodine = nil
        allergyToSilver = nil
        allergyToLatex = nil
        otherAllergies = ""
    }
}

// MARK: - Custom Components

struct SectionHeader: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct ThreeStateToggle: View {
    let title: String
    @Binding var state: Bool?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Picker("", selection: $state) {
                Text("?").tag(nil as Bool?)
                Text("No").tag(false as Bool?)
                Text("Yes").tag(true as Bool?)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
