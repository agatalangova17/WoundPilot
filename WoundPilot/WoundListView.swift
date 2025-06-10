import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct Wound: Identifiable {
    var id: String
    var imageURL: String
    var timestamp: Date
}

struct WoundListView: View {
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
                    List(wounds) { wound in
                        HStack {
                            AsyncImage(url: URL(string: wound.imageURL)) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                                     .frame(width: 60, height: 60)
                                     .clipped()
                                     .cornerRadius(8)
                            } placeholder: {
                                ProgressView()
                            }

                            VStack(alignment: .leading) {
                                Text("Uploaded:")
                                Text(wound.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 6)
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

        db.collection("wounds")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching wounds: \(error)")
                    isLoading = false
                    return
                }

                if let documents = snapshot?.documents {
                    self.wounds = documents.compactMap { doc in
                        let data = doc.data()
                        guard let url = data["imageURL"] as? String,
                              let timestamp = data["timestamp"] as? Timestamp else {
                            return nil
                        }
                        return Wound(id: doc.documentID, imageURL: url, timestamp: timestamp.dateValue())
                    }
                }
                isLoading = false
            }
    }
}
