import SwiftUI
import FirebaseFirestore
import Charts

struct WoundDetailView: View {
    let woundGroupId: String
    let woundGroupName: String
    let patient: Patient

    @State private var wounds: [Wound] = []
    @State private var isLoading = true

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
                                y: .value("Progress", index + 1) // fake score for now
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
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Wound Details")
        .onAppear(perform: loadWoundGroup)
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
}
