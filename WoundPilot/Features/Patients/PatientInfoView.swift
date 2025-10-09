import SwiftUI

struct PatientInfoView: View {
    let patient: Patient
    @ObservedObject var langManager = LocalizationManager.shared
    @State private var showEdit = false

    private var formattedDOB: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return df.string(from: patient.dateOfBirth)
    }

    private var sexDisplay: String {
        let raw = (patient.sex ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch raw {
        case "male", "m", "muž": return LocalizedStrings.sexMale
        case "female", "f", "žena": return LocalizedStrings.sexFemale
        case "unspecified", "unknown", "neurčené", "": fallthrough
        default: return LocalizedStrings.sexUnspecified
        }
    }

    private func formatWeight(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 1
        nf.maximumFractionDigits = 1
        nf.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return nf.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }
    
    // Helper to display three-state Bool
    private func threeStateDisplay(_ value: Bool?) -> String {
        guard let value = value else { return "Unknown" }
        return value ? "Yes" : "No"
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Basic Info
                Section(header: Text("Patient Information")) {
                    InfoRow(label: "Name", value: patient.name)
                    InfoRow(label: "Date of Birth", value: formattedDOB)
                    InfoRow(label: "Sex", value: sexDisplay)
                }

                // MARK: Medical History
                Section(header: Text("Medical History")) {
                    InfoRow(label: "Diabetes", value: threeStateDisplay(patient.hasDiabetes))
                    InfoRow(label: "Peripheral Arterial Disease", value: threeStateDisplay(patient.hasPAD))
                    InfoRow(label: "Venous Disease", value: threeStateDisplay(patient.hasVenousDisease))
                    InfoRow(label: "Immunosuppressed", value: threeStateDisplay(patient.isImmunosuppressed))
                }
                
                // MARK: Medications & Risk Factors
                Section(header: Text("Medications & Risk Factors")) {
                    InfoRow(label: "On Anticoagulants", value: threeStateDisplay(patient.isOnAnticoagulants))
                    InfoRow(label: "Smoker", value: threeStateDisplay(patient.isSmoker))
                }

                // MARK: Mobility
                Section(header: Text("Mobility")) {
                    InfoRow(
                        label: "Mobility Status",
                        value: patient.mobilityStatus?.rawValue ?? "Unknown"
                    )
                    
                    if let mobility = patient.mobilityStatus, mobility != .independent {
                        InfoRow(label: "Can Offload Weight", value: threeStateDisplay(patient.canOffload))
                    }
                }

                // MARK: Dressing Allergies
                if hasAnyAllergy {
                    Section(header: Text("Known Dressing Allergies")) {
                        if patient.allergyToAdhesives == true {
                            InfoRow(label: "Adhesives", value: "Allergic", valueColor: .red)
                        }
                        if patient.allergyToIodine == true {
                            InfoRow(label: "Iodine", value: "Allergic", valueColor: .red)
                        }
                        if patient.allergyToSilver == true {
                            InfoRow(label: "Silver", value: "Allergic", valueColor: .red)
                        }
                        if patient.allergyToLatex == true {
                            InfoRow(label: "Latex", value: "Allergic", valueColor: .red)
                        }
                        if let other = patient.otherAllergies, !other.isEmpty {
                            InfoRow(label: "Other Allergies", value: other, valueColor: .red)
                        }
                    }
                }

                // MARK: Additional Information
                if patient.weight != nil || patient.notes != nil {
                    Section(header: Text("Additional Information")) {
                        if let weight = patient.weight {
                            InfoRow(label: "Weight", value: "\(formatWeight(weight)) kg")
                        }
                        if let notes = patient.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Clinical Notes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(notes)
                                    .font(.body)
                            }
                        }
                    }
                }

                // MARK: Actions
                Section {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit Patient Information", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Patient Information")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showEdit) {
                EditPatientView(patient: patient)
            }
        }
    }
    
    private var hasAnyAllergy: Bool {
        patient.allergyToAdhesives == true ||
        patient.allergyToIodine == true ||
        patient.allergyToSilver == true ||
        patient.allergyToLatex == true ||
        (patient.otherAllergies != nil && !patient.otherAllergies!.isEmpty)
    }
}

// MARK: - Helper View
private struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
    }
}
