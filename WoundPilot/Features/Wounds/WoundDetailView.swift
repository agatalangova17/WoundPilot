import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import Charts

struct WoundDetailView: View {
    let woundGroupId: String
    let woundGroupName: String
    let patient: Patient?

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var wounds: [Wound] = []
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @State private var woundToDelete: Wound?
    @State private var showGroupDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(woundGroupName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(LocalizedStrings.healingProgress)
                    .font(.headline)

                if isLoading {
                    ProgressView()
                        .padding(.bottom, 8)
                }

                if wounds.count >= 2 {
                    Chart {
                        ForEach(wounds.indices, id: \.self) { index in
                            LineMark(
                                x: .value("Time", wounds[index].timestamp),
                                y: .value("Progress", index + 1) // Placeholder score
                            )
                        }
                    }
                    .frame(height: 200)
                } else {
                    Text(LocalizedStrings.notEnoughDataForGraph)
                        .foregroundColor(.gray)
                }

                ForEach(wounds) { wound in
                    NavigationLink(destination: SingleWoundDetailView(wound: wound)) {
                        HStack {
                            AsyncImage(url: URL(string: wound.imageURL)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(8)
                            } placeholder: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                    ProgressView()
                                }
                                .frame(width: 70, height: 70)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                if let location = wound.location {
                                    Text(location.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .foregroundColor(.blue)
                                }

                                Text(formatTimestamp(wound.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Button(role: .destructive) {
                                    woundToDelete = wound
                                    showDeleteConfirmation = true
                                } label: {
                                    Label(LocalizedStrings.deleteAction, systemImage: "trash")
                                }
                                .font(.caption)
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .navigationTitle(LocalizedStrings.woundDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showGroupDeleteConfirmation = true
                } label: {
                    Label(LocalizedStrings.deleteGroupAction, systemImage: "trash")
                }
            }
        }
        .onAppear(perform: loadWoundGroup)
        .alert(LocalizedStrings.deleteWoundPhotoAlertTitle, isPresented: $showDeleteConfirmation, presenting: woundToDelete) { wound in
            Button(LocalizedStrings.deleteAction, role: .destructive) {
                deleteWound(wound)
            }
            Button(LocalizedStrings.cancel, role: .cancel) {}
        } message: { _ in
            Text(LocalizedStrings.cannotBeUndone)
        }
        .alert(LocalizedStrings.deleteAllInGroupAlertTitle, isPresented: $showGroupDeleteConfirmation) {
            Button(LocalizedStrings.deleteAllAction, role: .destructive) {
                deleteEntireWoundGroup()
            }
            Button(LocalizedStrings.cancel, role: .cancel) {}
        } message: {
            Text(LocalizedStrings.deleteAllInGroupWarning(woundGroupName))
        }
    }

    // MARK: - Helpers
    private func formatTimestamp(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return df.string(from: date)
    }

    // MARK: - Data
    func loadWoundGroup() {
        let db = Firestore.firestore()
        db.collection("wounds")
            .whereField("woundGroupId", isEqualTo: woundGroupId)
            .order(by: "timestamp")
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Error loading group: \(error)")
                    return
                }
                if let docs = snapshot?.documents {
                    wounds = docs.compactMap { doc in
                        let data = doc.data()

                        guard
                            let imageURL = data["imageURL"] as? String,
                            let timestamp = data["timestamp"] as? Timestamp,
                            let patientId = data["patientId"] as? String,
                            let userId = data["userId"] as? String
                        else {
                            return nil
                        }

                        return Wound(
                            id: doc.documentID,
                            imageURL: imageURL,
                            timestamp: timestamp.dateValue(),
                            location: data["location"] as? String,
                            patientId: patientId,
                            userId: userId,
                            woundGroupId: data["woundGroupId"] as? String ?? "",
                            woundGroupName: data["woundGroupName"] as? String
                        )
                    }
                }
            }
    }

    func deleteWound(_ wound: Wound) {
        let db = Firestore.firestore()
        let storage = Storage.storage()

        db.collection("wounds").document(wound.id).delete { error in
            if let error = error {
                print("Error deleting wound document: \(error)")
                return
            }

            let storageRef = storage.reference(forURL: wound.imageURL)
            storageRef.delete { error in
                if let error = error {
                    print("Error deleting image from storage: \(error)")
                } else {
                    print("Image deleted from storage.")
                }
            }

            wounds.removeAll { $0.id == wound.id }
        }
    }

    func deleteEntireWoundGroup() {
        let db = Firestore.firestore()
        let storage = Storage.storage()

        for wound in wounds {
            db.collection("wounds").document(wound.id).delete { error in
                if let error = error {
                    print("Error deleting document: \(error)")
                }
            }

            let ref = storage.reference(forURL: wound.imageURL)
            ref.delete { error in
                if let error = error {
                    print("Error deleting image: \(error)")
                }
            }
        }

        wounds.removeAll()
    }
}
