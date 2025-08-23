import SwiftUI
import FirebaseFirestore

struct QuestionnaireView: View {
    let woundGroupId: String
    let patientId: String

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var isDiabetic = false
    @State private var isInfected = false
    @State private var hasExudate = false
    @State private var woundAgeInDays = ""
    @State private var painLevel = 0
    @State private var isSaving = false
    @State private var showNextView = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Title
                    Text(LocalizedStrings.clinicalQuestionnaireTitle)
                        .font(.title2.bold())
                        .padding(.top, 8)

                    // Questionnaire Section
                    VStack(spacing: 16) {

                        ToggleRow(title: LocalizedStrings.qPatientHasDiabetes, isOn: $isDiabetic)
                        ToggleRow(title: LocalizedStrings.qWoundShowsInfection, isOn: $isInfected)
                        ToggleRow(title: LocalizedStrings.qWoundHasExudate, isOn: $hasExudate)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStrings.qWoundAgeDays)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            TextField(LocalizedStrings.enterNumberPlaceholder, text: $woundAgeInDays)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStrings.qPainLevelLabel)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Picker(LocalizedStrings.qPainLevelPickerTitle, selection: $painLevel) {
                                ForEach(0..<11) {
                                    Text("\($0)").tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }
                }
            }

            // Continue Button
            Button(action: saveAnswers) {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text(LocalizedStrings.continueToAIAnalysisButton)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(woundAgeInDays.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding()
            .disabled(isSaving || woundAgeInDays.isEmpty)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNextView) {
            AIAnalysisView()
        }
    }

    private func saveAnswers() {
        let trimmed = woundAgeInDays.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let woundAge = Int(trimmed) else {
            errorMessage = LocalizedStrings.enterValidDaysError
            return
        }

        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let ref = db.collection("woundGroups").document(woundGroupId)

        let data: [String: Any] = [
            "questionnaire": [
                "isDiabetic": isDiabetic,
                "isInfected": isInfected,
                "hasExudate": hasExudate,
                "woundAgeInDays": woundAge,
                "painLevel": painLevel,
                "completedAt": FieldValue.serverTimestamp()
            ]
        ]

        ref.setData(data, merge: true) { error in
            DispatchQueue.main.async {
                isSaving = false
                if let error = error {
                    errorMessage = LocalizedStrings.failedToSave(error.localizedDescription)
                } else {
                    showNextView = true
                }
            }
        }
    }
}

// MARK: - ToggleRow
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}
