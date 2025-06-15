import SwiftUI

struct SingleWoundDetailView: View {
    let wound: Wound

    @State private var navigateToQuestionnaire = false

    var body: some View {
        VStack(spacing: 16) {
            // Image
            if let imageURL = URL(string: wound.imageURL) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 250)
            }

            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                if let location = wound.location {
                    Text("Location: \(location.replacingOccurrences(of: "_", with: " ").capitalized)")
                }
                Text("Date: \(wound.timestamp.formatted(date: .abbreviated, time: .shortened))")
                if let name = wound.woundGroupName {
                    Text("Group: \(name)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // Analyze Button
            NavigationLink(
                destination: QuestionnaireView(
                    woundGroupId: wound.woundGroupId,
                    patientId: wound.patientId
                ),
                isActive: $navigateToQuestionnaire
            ) {
                EmptyView()
            }

            Button("Analyze Wound") {
                navigateToQuestionnaire = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            Spacer()
        }
        .padding()
        .navigationTitle("Wound Entry")
        .navigationBarTitleDisplayMode(.inline)
    }
}
