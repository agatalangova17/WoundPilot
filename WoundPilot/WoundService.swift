import FirebaseFirestore

class WoundService {
    private let db = Firestore.firestore()

    func saveWoundMetadata(userID: String, woundID: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userID).collection("wounds").document(woundID).setData(data, completion: completion)
    }
}
