import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import Charts

struct WoundDetailView: View {
    let woundGroupId: String
    let woundGroupName: String
    let patient: Patient?

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

                Text("Healing Progress")
                    .font(.headline)

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
                    Text("Not enough data for graph.")
                        .foregroundColor(.gray)
                }

                ForEach(wounds) { wound in
                    HStack {
                        AsyncImage(url: URL(string: wound.imageURL)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .cornerRadius(8)
                        } placeholder: {
                            ProgressView()
                        }

                        VStack(alignment: .leading) {
                            if let location = wound.location {
                                Text(location.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .foregroundColor(.blue)
                            }
                            Text(wound.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)

                            Button(role: .destructive) {
                                woundToDelete = wound
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Wound Details")
        .navigationBarItems(trailing:
            Button(role: .destructive) {
                showGroupDeleteConfirmation = true
            } label: {
                Label("Delete Group", systemImage: "trash")
            }
        )
        .onAppear(perform: loadWoundGroup)
        .alert("Delete this wound photo?", isPresented: $showDeleteConfirmation, presenting: woundToDelete) { wound in
            Button("Delete", role: .destructive) {
                deleteWound(wound)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This cannot be undone.")
        }
        .alert("Delete ALL photos in this group?", isPresented: $showGroupDeleteConfirmation) {
            Button("Delete All", role: .destructive) {
                deleteEntireWoundGroup()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all wound entries in '\(woundGroupName)'.")
        }
    }

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
