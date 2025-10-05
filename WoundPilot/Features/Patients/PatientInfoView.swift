import SwiftUI

struct PatientInfoView: View {
    let patient: Patient
    @ObservedObject var langManager = LocalizationManager.shared
    @State private var showEdit = false

    
    private var formattedDOB: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue) // "en" / "sk"
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

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Info
                Section(header: Text(LocalizedStrings.basicInfoSection)) {
                    Text("\(LocalizedStrings.fullNameLabel): \(patient.name)")
                    Text("\(LocalizedStrings.dateOfBirth): \(formattedDOB)")
                    Text("\(LocalizedStrings.sexLabel): \(sexDisplay)")
                }

                // MARK: - Clinical Details
                Section(header: Text(LocalizedStrings.clinicalDetailsSection)) {
                    Toggle(LocalizedStrings.diabetic, isOn: .constant(patient.isDiabetic ?? false))
                        .disabled(true)
                    Toggle(LocalizedStrings.smoker, isOn: .constant(patient.isSmoker ?? false))
                        .disabled(true)
                    Toggle(LocalizedStrings.peripheralArteryDisease, isOn: .constant(patient.hasPAD ?? false))
                        .disabled(true)
                    Toggle(LocalizedStrings.mobilityIssues, isOn: .constant(patient.hasMobilityIssues ?? false))
                        .disabled(true)
                    Toggle(LocalizedStrings.bloodPressureIssues, isOn: .constant(patient.hasBloodPressureIssues ?? false))
                        .disabled(true)

                    if let weight = patient.weight {
                        Text("\(LocalizedStrings.weightLabel): \(formatWeight(weight)) \(LocalizedStrings.kgUnit)")
                    }
                    if let allergies = patient.allergies, !allergies.isEmpty {
                        Text("\(LocalizedStrings.allergiesLabel): \(allergies)")
                    }
                }

                // MARK: - Actions
                Section {
                    Button {
                        showEdit = true
                    } label: {
                        Label(LocalizedStrings.editPatientInfo, systemImage: "square.and.pencil")
                    }
                }
            }
            .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
            .navigationTitle(LocalizedStrings.patientInfoTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showEdit) {
                EditPatientView(patient: patient)
            }
        }
    }
}
