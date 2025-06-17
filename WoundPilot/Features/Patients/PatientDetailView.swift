import SwiftUI

struct PatientDetailView: View {
    let patient: Patient

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Patient Info Header
            VStack(spacing: 4) {
                Text(patient.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Date of Birth: \(patient.dateOfBirth.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)

            // Section: Patient Info
            VStack(alignment: .leading, spacing: 12) {
                Text("Patient Overview")
                    .font(.headline)
                    .foregroundColor(.gray)

                NavigationLink(destination: PatientInfoView(patient: patient)) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                        Text("View Patient Info")
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
                Text("Wound Management")
                    .font(.headline)
                    .foregroundColor(.gray)

                NavigationLink(destination: WoundImageSourceView(selectedPatient: patient)) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("New Wound Entry")
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
                        Text("View Wound History")
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
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
