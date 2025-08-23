import SwiftUI

struct PatientDetailView: View {
    let patient: Patient
    @ObservedObject var langManager = LocalizationManager.shared

    private var formattedDOB: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue) // "en" / "sk"
        return df.string(from: patient.dateOfBirth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Patient Info Header
            VStack(spacing: 4) {
                Text(patient.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(LocalizedStrings.dateOfBirth): \(formattedDOB)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)

            // Section: Patient Info
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.patientOverview)
                    .font(.headline)
                    .foregroundColor(.gray)

                NavigationLink(destination: PatientInfoView(patient: patient)) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                        Text(LocalizedStrings.viewPatientInfo)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }

            Divider()

            // Section: Wound Management
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.woundManagement)
                    .font(.headline)
                    .foregroundColor(.gray)

                NavigationLink(destination: WoundImageSourceView(selectedPatient: patient)) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text(LocalizedStrings.newWoundEntry)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                NavigationLink(destination: WoundListView(patient: patient)) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle.portrait")
                        Text(LocalizedStrings.viewWoundHistory)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle(LocalizedStrings.patientDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
