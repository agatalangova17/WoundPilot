import SwiftUI

struct PatientInfoView: View {
    let patient: Patient
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    Text("Full Name: \(patient.name)")
                    Text("Date of Birth: \(patient.dateOfBirth.formatted(date: .abbreviated, time: .omitted))")
                    Text("Sex: \(patient.sex ?? "Unspecified")")
                }

                Section(header: Text("Clinical Details")) {
                    Toggle("Diabetic", isOn: .constant(patient.isDiabetic ?? false))
                        .disabled(true)
                    Toggle("Smoker", isOn: .constant(patient.isSmoker ?? false))
                        .disabled(true)
                    Toggle("Peripheral Artery Disease", isOn: .constant(patient.hasPAD ?? false))
                        .disabled(true)
                    Toggle("Mobility Issues", isOn: .constant(patient.hasMobilityIssues ?? false))
                        .disabled(true)
                    Toggle("Blood Pressure Issues", isOn: .constant(patient.hasBloodPressureIssues ?? false))
                        .disabled(true)
                    if let weight = patient.weight {
                        Text("Weight: \(weight, specifier: "%.1f") kg")
                    }
                    if let allergies = patient.allergies, !allergies.isEmpty {
                        Text("Allergies: \(allergies)")
                    }
                }

                Section {
                    Button(action: {
                        showEdit = true
                    }) {
                        Label("Edit Patient Info", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Patient Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showEdit) {
                EditPatientView(patient: patient)
            }
        }
    }
}
