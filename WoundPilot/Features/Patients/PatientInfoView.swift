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
        case "male", "m", "muž": return "Male"
        case "female", "f", "žena": return "Female"
        case "unspecified", "unknown", "neurčené", "": fallthrough
        default: return "Unspecified"
        }
    }
    
    private func threeStateDisplay(_ value: Bool?) -> String {
        guard let value = value else { return "Unknown" }
        return value ? "Yes" : "No"
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
                            InfoRow(label: "Name", value: patient.name)
                            InfoRow(label: "Date of Birth", value: formattedDOB)
                            InfoRow(label: "Sex", value: sexDisplay)
                        }
                    }
                    .cardStyle()

                    // MARK: Medical History
                    VStack(spacing: 16) {
                        SectionHeader(icon: "heart.text.square.fill", title: "Medical History", color: .red)
                        
                        VStack(spacing: 12) {
                            InfoRow(label: "Diabetes", value: threeStateDisplay(patient.hasDiabetes))
                            InfoRow(label: "Peripheral Arterial Disease", value: threeStateDisplay(patient.hasPAD))
                            InfoRow(label: "Venous Disease", value: threeStateDisplay(patient.hasVenousDisease))
                            InfoRow(label: "Immunosuppressed", value: threeStateDisplay(patient.isImmunosuppressed))
                        }
                    }
                    .cardStyle()
                    
                    // MARK: Medications
                    VStack(spacing: 16) {
                        SectionHeader(icon: "pills.fill", title: "Medications", color: .orange)
                        
                        InfoRow(label: "On Blood Thinners", value: threeStateDisplay(patient.isOnAnticoagulants))
                    }
                    .cardStyle()

                    // MARK: Mobility
                    VStack(spacing: 16) {
                        SectionHeader(icon: "figure.walk", title: "Mobility", color: .purple)
                        
                        VStack(spacing: 12) {
                            InfoRow(label: "Mobility Impairment", value: threeStateDisplay(patient.hasMobilityImpairment))
                            
                            if patient.hasMobilityImpairment == true {
                                InfoRow(label: "Can Offload Weight", value: threeStateDisplay(patient.canOffload))
                            }
                        }
                    }
                    .cardStyle()

                    // MARK: Allergies
                    if hasAnyAllergy {
                        VStack(spacing: 16) {
                            SectionHeader(icon: "exclamationmark.triangle.fill", title: "Dressing Allergies", color: .pink)
                            
                            VStack(spacing: 12) {
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
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Other Allergies")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(other)
                                            .font(.body)
                                            .foregroundColor(.red)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // MARK: Edit Button
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit Patient Information", systemImage: "square.and.pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Patient Information")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showEdit) {
            EditPatientView(patient: patient)
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

private struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
    }
}
