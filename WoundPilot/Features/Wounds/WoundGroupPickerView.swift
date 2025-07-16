import SwiftUI
import FirebaseFirestore

struct WoundGroupPickerView: View {
    let patient: Patient?
    var onGroupSelected: (String, String) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var existingGroups: [WoundGroup] = []
    @State private var newGroupName: String = ""
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // 🌈 Hero Intro Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            VStack(alignment: .leading) {
                                Text("Group Wound Images")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                Text("Track healing by grouping images of the same wound area, like 'Left Heel'.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)

                    // 📁 Existing Group Cards
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Existing Wound Groups")
                            .font(.headline)

                        if isLoading {
                            ProgressView()
                        } else if existingGroups.isEmpty {
                            Text("No groups yet for this patient.")
                                .foregroundColor(.gray)
                                .padding(.vertical, 6)
                        } else {
                            ForEach(existingGroups, id: \.id) { group in
                                Button(action: {
                                    onGroupSelected(group.id, group.name)
                                }) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.accentColor)
                                        VStack(alignment: .leading) {
                                            Text(group.name)
                                                .fontWeight(.semibold)
                                            Text("Tap to continue")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(14)
                                }
                            }
                        }
                    }

                    // ➕ Create New Group Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create New Wound Group")
                            .font(.headline)

                        VStack(spacing: 14) {
                            TextField("e.g. Left Foot Ulcer", text: $newGroupName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button(action: createGroup) {
                                Text("Create and Continue")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(newGroupName.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(newGroupName.isEmpty)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Select Wound Group")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { fetchExistingGroups() }
        }
    }

    private func fetchExistingGroups() {
        guard let patient = patient else { return }
        let db = Firestore.firestore()
        db.collection("woundGroups").getDocuments { snapshot, error in
            self.isLoading = false
            if let documents = snapshot?.documents {
                self.existingGroups = documents.compactMap { doc in
                    let data = doc.data()
                    let groupPatientId = data["patientId"] as? String ?? ""
                    let groupName = data["name"] as? String ?? ""
                    return groupPatientId == patient.id ?
                        WoundGroup(id: doc.documentID, name: groupName, patientId: groupPatientId)
                        : nil
                }
            }
        }
    }

    private func createGroup() {
        guard let patient = patient else { return }
        let db = Firestore.firestore()
        let newDoc = db.collection("woundGroups").document()
        let groupData: [String: Any] = [
            "name": newGroupName,
            "patientId": patient.id
        ]
        newDoc.setData(groupData) { error in
            if error == nil {
                onGroupSelected(newDoc.documentID, newGroupName)
            }
        }
    }
}
