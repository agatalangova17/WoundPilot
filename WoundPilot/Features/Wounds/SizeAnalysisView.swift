import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import UIKit

struct SizeAnalysisView: View {
    let wound: Wound

    // Simulated values for now
    let width: Double = 3.5
    let height: Double = 4.0

    @State private var navigateToQuestionnaire = false

    var body: some View {
        VStack(spacing: 20) {
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

            Text("Estimated Size:")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "ruler")
                    Text("Width: \(width, specifier: "%.1f") cm")
                }

                HStack {
                    Image(systemName: "triangle")
                    Text("Height: \(height, specifier: "%.1f") cm")
                }
            }
            .font(.subheadline)

            Button("Continue") {
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
        .navigationTitle("Size Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToQuestionnaire) {
            QuestionnaireView(
                woundGroupId: wound.woundGroupId,
                patientId: wound.patientId
            )
        }
    }
}
