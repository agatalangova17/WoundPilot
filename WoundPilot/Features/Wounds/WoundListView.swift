import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct Wound: Identifiable {
    var id: String
    var imageURL: String
    var timestamp: Date
    var location: String?
    var patientId: String
    var userId: String
    var woundGroupId: String
    var woundGroupName: String?
}

struct WoundListView: View {
    let patient: Patient?  // ✅ Now optional
    @State private var wounds: [Wound] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading wounds...")
                } else if wounds.isEmpty {
                    Text("No wounds uploaded yet.")
                        .foregroundColor(.gray)
                } else {
                    let grouped = Dictionary(grouping: wounds, by: { $0.woundGroupId })

                    List {
                        ForEach(grouped.keys.sorted(), id: \.self) { groupId in
                            if let groupWounds = grouped[groupId],
                               let latest = groupWounds.sorted(by: { $0.timestamp > $1.timestamp }).first {

                                NavigationLink(
                                    destination: WoundDetailView(
                                        woundGroupId: groupId,
                                        woundGroupName: latest.woundGroupName ?? "Unnamed Wound",
                                        patient: patient  // ✅ now optional
                                    )
                                ) {
                                    HStack {
                                        AsyncImage(url: URL(string: latest.imageURL)) { image in
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipped()
                                                .cornerRadius(8)
                                        } placeholder: {
                                            ProgressView()
                                        }

                                        VStack(alignment: .leading) {
                                            Text(latest.woundGroupName ?? "Unnamed Wound")
                                                .font(.headline)
                                                .foregroundColor(.blue)

                                            Text("Last update:")
                                            Text(latest.timestamp.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Wounds")
        }
        .onAppear(perform: loadWounds)
    }

    func loadWounds() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        var query: Query = db.collection("wounds").whereField("userId", isEqualTo: userId)

        if let patient = patient {
            query = query.whereField("patientId", isEqualTo: patient.id)  // ✅ Only filter by patient if provided
        }

        query.order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            isLoading = false

            if let error = error {
                print("Error fetching wounds: \(error)")
                return
            }

            if let documents = snapshot?.documents {
                self.wounds = documents.compactMap { doc in
                    let data = doc.data()
                    guard let url = data["imageURL"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp,
                          let userId = data["userId"] as? String,
                          let groupId = data["woundGroupId"] as? String else {
                        return nil
                    }

                    // patientId is optional now
                    let patientId = data["patientId"] as? String ?? ""

                    return Wound(
                        id: doc.documentID,
                        imageURL: url,
                        timestamp: timestamp.dateValue(),
                        location: data["location"] as? String,
                        patientId: patientId,
                        userId: userId,
                        woundGroupId: groupId,
                        woundGroupName: data["woundGroupName"] as? String
                    )
                }
            }
        }
    }
}
