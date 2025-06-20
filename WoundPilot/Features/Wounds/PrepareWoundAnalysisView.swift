import SwiftUI
import FirebaseFirestore

struct PrepareWoundAnalysisView: View {
    let image: UIImage
    let patient: Patient?

    @State private var proceedToLocation = false
    @State private var existingGroups: [WoundGroup] = []
    @State private var selectedGroup: WoundGroup?
    @State private var newGroupName: String = ""
    @State private var showExplanation = false
    @State private var showGroups = false
    @State private var showImage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: - Avatar + Title + Steps
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "stethoscope.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.accentBlue)
                            .padding(.top, 8)

                        Text("You're just 3 steps away from an AI-powered wound evaluation.")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        stepList
                    }
                    .frame(maxWidth: .infinity)

                    // MARK: - Wound Group Section
                    if let patient = patient {
                        groupSection(for: patient)
                    }

                    // MARK: - Continue Button
                    Button {
                        proceedToLocation = true
                    } label: {
                        Text("Continue")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentBlue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(patient != nil && (selectedGroup == nil && newGroupName.trimmingCharacters(in: .whitespaces).isEmpty))
                }
                .padding()
            }
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let patient = patient {
                    fetchExistingGroups(for: patient)
                }
            }
            .navigationDestination(isPresented: $proceedToLocation) {
                let woundGroupId = selectedGroup?.id ?? UUID().uuidString
                let woundGroupName = selectedGroup?.name ?? newGroupName.trimmingCharacters(in: .whitespaces)

                WoundLocationPickerViewWrapper(
                    image: image,
                    patient: patient,
                    woundGroupId: woundGroupId,
                    woundGroupName: woundGroupName
                )
            }
        }
    }

    // MARK: - Step List
    private var stepList: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepRow("mappin.and.ellipse", "Step 1", "Select wound location")
            stepRow("doc.text.magnifyingglass", "Step 2", "Answer clinical questions")
            stepRow("brain.head.profile", "Step 3", "AI analyzes wound")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func stepRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentBlue)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.subheadline).foregroundColor(.gray)
            }
        }
    }

    // MARK: - Group Section
    private func groupSection(for patient: Patient) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assign Wound Group")
                .font(.headline)

            if existingGroups.isEmpty {
                Text("No existing wound groups found.")
                    .font(.footnote)
                    .foregroundColor(.gray)

                TextField("Create first group (e.g. Right Leg Surgery)", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Button {
                    withAnimation {
                        showGroups.toggle()
                    }
                } label: {
                    HStack {
                        Text(showGroups ? "Hide Existing Groups" : "View Existing Groups")
                        Spacer()
                        Image(systemName: showGroups ? "chevron.up" : "chevron.down")
                    }
                    .foregroundColor(.accentBlue)
                    .font(.subheadline)
                }

                if showGroups {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(existingGroups, id: \.id) { group in
                            Button {
                                selectedGroup = group
                            } label: {
                                HStack {
                                    Text(group.name)
                                    Spacer()
                                    if selectedGroup?.id == group.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentBlue)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }

                Text("Or create new group:")
                    .font(.footnote)
                    .foregroundColor(.gray)

                TextField("e.g. Right Leg Surgery", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            DisclosureGroup("Why assign a wound group?", isExpanded: $showExplanation) {
                Text("Wound groups help track healing progress over time. Select an existing group if this wound was treated before, or create a new group to start tracking.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Firestore
    private func fetchExistingGroups(for patient: Patient) {
        let db = Firestore.firestore()
        db.collection("woundGroups")
            .whereField("patientId", isEqualTo: patient.id)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    existingGroups = documents.map {
                        WoundGroup(id: $0.documentID, name: $0["name"] as? String ?? "")
                    }
                }
            }
    }
}
