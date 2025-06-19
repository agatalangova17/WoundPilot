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
    @State private var showDropdown = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Main Heading
                    Text("You're just 3 steps away from an AI-powered wound evaluation.")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal)

                    // Step List
                    stepList

                    // Image Preview
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)

                    // Group Selection
                    if let patient = patient {
                        groupSection(for: patient)
                    }

                    // Continue
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
                    .padding(.top, 8)
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentBlue)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.subheadline).foregroundColor(.gray)
            }
        }
    }

    // MARK: - Group Picker Section
    private func groupSection(for patient: Patient) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assign Wound Group")
                .font(.headline)

            if !existingGroups.isEmpty {
                DisclosureGroup(isExpanded: $showDropdown) {
                    VStack(spacing: 6) {
                        ForEach(existingGroups, id: \.id) { group in
                            Button {
                                selectedGroup = group
                                showDropdown = false
                            } label: {
                                HStack {
                                    Text(group.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedGroup?.id == group.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentBlue)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedGroup?.name ?? "Select Existing Group")
                            .foregroundColor(selectedGroup == nil ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showDropdown ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: showDropdown)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }

            TextField("Or create new group (e.g. Right Leg Surgery)", text: $newGroupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            DisclosureGroup("Why assign a wound group?", isExpanded: $showExplanation) {
                Text("Wound groups help track healing progress over time. Select an existing group if this wound was treated before, or create a new group to start tracking.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 4)

                if !existingGroups.isEmpty {
                    Divider()
                    Text("Existing Groups:")
                        .font(.footnote.bold())
                    ForEach(existingGroups) { group in
                        Text("• \(group.name)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Fetch
    private func fetchExistingGroups(for patient: Patient) {
        let db = Firestore.firestore()
        db.collection("woundGroups")
            .whereField("patientId", isEqualTo: patient.id)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    existingGroups = documents.map { doc in
                        WoundGroup(id: doc.documentID, name: doc["name"] as? String ?? "")
                    }
                }
            }
    }
}
