import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct WoundGroupPickerView: View {
    let patientId: String
    let onGroupSelected: (String, String) -> Void

    @State private var existingGroups: [WoundGroup] = []
    @State private var newGroupName: String = ""
    @State private var isLoading = true

    var body: some View {
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
                            onGroupSelected(group.id, group.name)
                        }) {
                            HStack {
                                Text(group.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                }
            }

            Section(header: Text("Or Create New Group")) {
                TextField("Group Name", text: $newGroupName)

                Button("Create and Select") {
                    let groupId = UUID().uuidString
                    let groupName = newGroupName.trimmingCharacters(in: .whitespaces)
                    onGroupSelected(groupId, groupName)
                }
                .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Wound Group")
        .onAppear(perform: fetchExistingGroups)
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

                    let unique = Dictionary(grouping: groups, by: { $0.id }).compactMap { $0.value.first }
                    self.existingGroups = unique
                }
                self.isLoading = false
            }
    }
}
