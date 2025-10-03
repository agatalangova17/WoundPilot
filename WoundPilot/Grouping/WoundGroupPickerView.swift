import SwiftUI
import FirebaseFirestore

struct WoundGroupPickerView: View {
    let patient: Patient?
    var onGroupSelected: ((String, String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var existingGroups: [WoundGroup] = []
    @State private var newGroupName: String = ""
    @State private var isLoading = true

    // Needs Hashable for navigationDestination(item:)
    private struct ChosenGroup: Identifiable, Hashable {
        let id: String
        let name: String
    }
    @State private var chosenGroup: ChosenGroup?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Hero
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            VStack(alignment: .leading) {
                                Text(LocalizedStrings.groupWoundImagesTitle)
                                    .font(.title3).bold().foregroundColor(.white)
                                Text(LocalizedStrings.groupWoundImagesSubtitle)
                                    .font(.subheadline).foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color.blue]),
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)

                    // Existing groups
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStrings.existingWoundGroups).font(.headline)

                        if isLoading {
                            ProgressView()
                        } else if existingGroups.isEmpty {
                            Text(LocalizedStrings.noGroupsYetForPatient)
                                .foregroundColor(.gray)
                                .padding(.vertical, 6)
                        } else {
                            ForEach(existingGroups) { group in
                                Button {
                                    onGroupSelected?(group.id, group.name)
                                    chosenGroup = ChosenGroup(id: group.id, name: group.name)
                                } label: {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.accentColor)
                                        VStack(alignment: .leading) {
                                            Text(group.name).fontWeight(.semibold)
                                            Text(LocalizedStrings.tapToContinue)
                                                .font(.caption).foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(14)
                                }
                            }
                        }
                    }

                    // Create new group
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStrings.createNewWoundGroup).font(.headline)

                        VStack(spacing: 14) {
                            TextField(LocalizedStrings.exampleLeftFootUlcerPlaceholder, text: $newGroupName)
                                .textFieldStyle(.roundedBorder)

                            Button {
                                createGroup()
                            } label: {
                                Text(LocalizedStrings.createAndContinue)
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
            .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
            .navigationTitle(LocalizedStrings.selectWoundGroupTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { fetchExistingGroups() }

            // Navigation ➜ Body Localization
            .navigationDestination(item: $chosenGroup) { choice in
                if let patient {
                    BodyLocalizationView(
                        patient: patient,
                        woundGroupId: choice.id,
                        woundGroupName: choice.name
                    )
                } else {
                    Text("Missing patient context.")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: Data
    private func fetchExistingGroups() {
        guard let patient else { isLoading = false; return }
        let db = Firestore.firestore()
        db.collection("woundGroups")
            .whereField("patientId", isEqualTo: patient.id)
            .getDocuments { snapshot, _ in
                isLoading = false
                existingGroups = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    if let pid = data["patientId"] as? String,
                       let name = data["name"] as? String {
                        // Pass the new optional fields explicitly (nil is fine)
                        return WoundGroup(
                            id: doc.documentID,
                            name: name,
                            patientId: pid,
                            bodyRegionCode: data["bodyRegionCode"] as? String,
                            side: data["side"] as? String,
                            subsite: data["subsite"] as? String
                        )
                    } else {
                        return nil
                    }
                } ?? []
            }
    }

    private func createGroup() {
        guard let patient else { return }
        let db = Firestore.firestore()
        let newDoc = db.collection("woundGroups").document()
        let groupData: [String: Any] = [
            "name": newGroupName.trimmingCharacters(in: .whitespacesAndNewlines),
            "patientId": patient.id
            // You can also persist bodyRegionCode/side/subsite later when chosen
        ]
        newDoc.setData(groupData) { error in
            guard error == nil else { return }
            onGroupSelected?(newDoc.documentID, newGroupName)
            chosenGroup = ChosenGroup(id: newDoc.documentID, name: newGroupName)
            newGroupName = ""
        }
    }
}
