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

    private struct ChosenGroup: Identifiable, Hashable {
        let id: String
        let name: String
    }
    @State private var chosenGroup: ChosenGroup?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Hero (micro-onboarding with guidance)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizedStrings.groupWoundImagesTitleBetter)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text(LocalizedStrings.groupWoundImagesSubtitleBetter)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HeroBullet(text: LocalizedStrings.groupWhyTrend)
                            HeroBullet(text: LocalizedStrings.groupWhyCompare)
                            HeroBullet(text: LocalizedStrings.groupWhyFindFast)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStrings.groupExamplesTitle)
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.white.opacity(0.95))

                            FlexibleChips(chips: [
                                "Left Heel Ulcer",
                                "Right Lateral Malleolus",
                                "Sacrum – Pressure Injury",
                                "Plantar Hallux – Diabetic Foot"
                            ]) { example in
                                newGroupName = example
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)

                    // MARK: - Existing groups
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStrings.existingWoundGroups)
                            .font(.headline)

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
                                            Text(group.name)
                                                .fontWeight(.semibold)
                                            Text(LocalizedStrings.tapToContinue)
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

                    // MARK: - Create new group
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStrings.createNewWoundGroup)
                            .font(.headline)

                        VStack(spacing: 14) {
                            TextField(LocalizedStrings.groupNamePlaceholder, text: $newGroupName)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled(true)

                            Text(LocalizedStrings.groupNameHint)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

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

            // MARK: - Navigation ➜ Body Localization
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

    // MARK: - Data
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
        ]
        newDoc.setData(groupData) { error in
            guard error == nil else { return }
            onGroupSelected?(newDoc.documentID, newGroupName)
            chosenGroup = ChosenGroup(id: newDoc.documentID, name: newGroupName)
            newGroupName = ""
        }
    }
}

// MARK: - Helpers (local)

private struct HeroBullet: View {
    let text: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.white)
                .imageScale(.small)
            Text(text)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.95))
        }
    }
}

/// Simple flexible chip row (wraps as needed)
private struct FlexibleChips: View {
    let chips: [String]
    let onPick: (String) -> Void

    var body: some View {
        let cols = [GridItem(.adaptive(minimum: 160), spacing: 8)]
        LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
            ForEach(chips, id: \.self) { label in
                Button {
                    onPick(label)
                } label: {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.18))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
