import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct WoundGroupPickerView: View {
    let patientId: String
    @Binding var selectedGroupId: String?
    @Binding var selectedGroupName: String?
    @Environment(\.dismiss) var dismiss

    @State private var existingGroups: [WoundGroup] = []
    @State private var newGroupName: String = ""
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Existing Wound Group")) {
                    if isLoading {
                        ProgressView("Loading groups...")
                    } else if existingGroups.isEmpty {
                        Text("No existing groups")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(existingGroups) { group in
                            Button(action: {
                                selectedGroupId = group.id
                                selectedGroupName = group.name
                                dismiss()
                            }) {
                                HStack {
                                    Text(group.name)
                                    if selectedGroupId == group.id {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Or Create New Group")) {
                    TextField("Group Name", text: $newGroupName)

                    Button("Create and Select") {
                        createNewGroup()
                    }
                    .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Wound Group")
            .onAppear(perform: fetchExistingGroups)
        }
    }

    func fetchExistingGroups() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("wounds")
            .whereField("patientId", isEqualTo: patientId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let groups = documents
                        .compactMap { doc -> WoundGroup? in
                            let data = doc.data()
                            guard let id = data["woundGroupId"] as? String,
                                  let name = data["woundGroupName"] as? String else { return nil }
                            return WoundGroup(id: id, name: name)
                        }

                    // Deduplicate by ID
                    let unique = Dictionary(grouping: groups, by: { $0.id }).compactMap { $0.value.first }
                    self.existingGroups = unique
                }
                self.isLoading = false
            }
    }

    func createNewGroup() {
        let groupId = UUID().uuidString
        let trimmedName = newGroupName.trimmingCharacters(in: .whitespaces)
        selectedGroupId = groupId
        selectedGroupName = trimmedName
        dismiss()
    }
}

