import SwiftUI
import FirebaseFirestore

struct QuestionnaireView: View {
    let woundGroupId: String
    let patientId: String

    @State private var isDiabetic = false
    @State private var isInfected = false
    @State private var hasExudate = false
    @State private var woundAgeInDays = ""
    @State private var painLevel = 0
    @State private var isSaving = false
    @State private var showNextView = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(header: Text("Clinical Information")) {
                Toggle("Patient has diabetes", isOn: $isDiabetic)
                Toggle("Wound shows signs of infection", isOn: $isInfected)
                Toggle("Wound has exudate (fluid)", isOn: $hasExudate)
                
                TextField("Wound age (in days)", text: $woundAgeInDays)
                    .keyboardType(.numberPad)

                Picker("Pain level (0–10)", selection: $painLevel) {
                    ForEach(0..<11) { level in
                        Text("\(level)").tag(level)
                    }
                }
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button(action: saveAnswers) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Continue to AI Analysis")
                    }
                }
                .disabled(isSaving || woundAgeInDays.isEmpty)
            }
        }
        .navigationTitle("Clinical Questionnaire")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNextView) {
            Text("AI Analysis")
        }
    }

    private func saveAnswers() {
        guard let woundAge = Int(woundAgeInDays) else {
            errorMessage = "Please enter a valid number of days"
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
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                } else {
                    showNextView = true
                }
            }
        }
    }
}
