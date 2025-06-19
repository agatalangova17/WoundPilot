import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import UIKit

struct SizeAnalysisView: View {
    let wound: Wound

    // Simulated AI-estimated values
    let width: Double = 3.5
    let height: Double = 4.0

    @State private var navigateToQuestionnaire = false

    // Manual override
    @State private var manualEntry = false
    @State private var manualWidth = ""
    @State private var manualHeight = ""

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

            // Toggle for manual size entry
            Toggle("Edit Size Manually", isOn: $manualEntry)
                .padding(.top)

            if manualEntry {
                VStack(spacing: 12) {
                    TextField("Width (cm)", text: $manualWidth)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Height (cm)", text: $manualHeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }

            Button("Continue") {
                // Optional: You could validate manual entries here before navigating
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
                // Optionally pass manual size too if needed
            )
        }
    }
}
