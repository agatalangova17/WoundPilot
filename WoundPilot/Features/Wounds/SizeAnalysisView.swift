import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import UIKit

struct SizeAnalysisView: View {
    let wound: Wound

    // Dummy AI analysis (replace later)
    let width: Double = 3.5
    let height: Double = 4.0

    @State private var navigateToQuestionnaire = false
    @State private var manualEntry = false
    @State private var manualWidth = ""
    @State private var manualHeight = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Wound Image
                if let imageURL = URL(string: wound.imageURL) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                            .shadow(radius: 6)
                    } placeholder: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 220)
                            ProgressView()
                        }
                    }
                    .frame(maxHeight: 250)
                }

                // MARK: - AI Estimated Size
                VStack(alignment: .leading, spacing: 12) {
                    Text("Estimated Wound Size")
                        .font(.headline)

                    HStack(spacing: 20) {
                        measurementCard(title: "Width", value: width, unit: "cm", icon: "ruler")
                        measurementCard(title: "Height", value: height, unit: "cm", icon: "arrow.up.and.down")
                    }
                }

                Divider()

                // MARK: - Manual Toggle
                Toggle(isOn: $manualEntry) {
                    Label("Edit Size Manually", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))

                // MARK: - Manual Inputs
                if manualEntry {
                    VStack(spacing: 16) {
                        TextField("Enter Width (cm)", text: $manualWidth)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)

                        TextField("Enter Height (cm)", text: $manualHeight)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }

                Spacer(minLength: 30)

                // MARK: - Continue Button
                Button(action: {
                    navigateToQuestionnaire = true
                }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            }
            .padding()
        }
        .navigationTitle("Size Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToQuestionnaire) {
            QuestionnaireView(
                woundGroupId: wound.woundGroupId,
                patientId: wound.patientId
            )
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Reusable Measurement Card
    func measurementCard(title: String, value: Double, unit: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("\(value, specifier: "%.1f") \(unit)")
                .font(.title3.bold())

            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

