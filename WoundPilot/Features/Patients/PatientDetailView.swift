import SwiftUI

struct PatientDetailView: View {
    let patient: Patient

    var body: some View {
        VStack(spacing: 24) {
            // Patient Info
            VStack(spacing: 4) {
                Text(patient.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("DOB: \(patient.dateOfBirth.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Action Buttons
            NavigationLink(destination:
                WoundImageSourceView(patient: patient)
            ) {
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

            Spacer()
        }
        .padding()
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
