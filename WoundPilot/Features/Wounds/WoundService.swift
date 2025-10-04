import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

public struct WoundMeasurement: Identifiable, Codable {
    public let id: String
    public let length_cm: Double
    public let width_cm: Double
    public let area_cm2: Double
    public let measured_at: Date
    public let width1_cm: Double?
    public let width2_cm: Double?
    public let userId: String?
    public let woundId: String?

    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]
        guard
            let length = data["length_cm"] as? Double,
            let width  = data["width_cm"]  as? Double,
            let area   = data["area_cm2"]  as? Double
        else { return nil }
        self.id = doc.documentID
        self.length_cm = length
        self.width_cm  = width
        self.area_cm2  = area
        self.measured_at = (data["measured_at"] as? Timestamp)?.dateValue() ?? Date()
        self.width1_cm = data["width1_cm"] as? Double
        self.width2_cm = data["width2_cm"] as? Double
        self.userId    = data["userId"] as? String
        self.woundId   = data["woundId"] as? String
    }

    init(id: String, length_cm: Double, width_cm: Double, area_cm2: Double, measured_at: Date, width1_cm: Double?, width2_cm: Double?, userId: String?, woundId: String? = nil) {
        self.id = id
        self.length_cm = length_cm
        self.width_cm = width_cm
        self.area_cm2 = area_cm2
        self.measured_at = measured_at
        self.width1_cm = width1_cm
        self.width2_cm = width2_cm
        self.userId = userId
        self.woundId = woundId
    }
}

class WoundService {
    static let shared = WoundService()
    private init() {}

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Create Wound

    func saveWound(
        image: UIImage,
        location: String,
        patient: Patient?,
        woundGroupId: String,
        woundGroupName: String,
        completion: @escaping (Result<Wound, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Missing user or image", code: 400, userInfo: nil)))
            return
        }

        let path = "wounds/\(user.uid)/\(UUID().uuidString).jpg"
        let imageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    completion(.failure(error ?? NSError(domain: "Missing URL", code: 500, userInfo: nil)))
                    return
                }

                let woundId = UUID().uuidString
                let woundRef = self.db.collection("wounds").document(woundId)

                var data: [String: Any] = [
                    "imageURL": downloadURL.absoluteString,
                    "timestamp": Timestamp(date: Date()),
                    "location": location,
                    "woundGroupId": woundGroupId,
                    "woundGroupName": woundGroupName,
                    "userId": user.uid
                ]

                if let patient = patient {
                    data["patientId"] = patient.id
                }

                woundRef.setData(data) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    let wound = Wound(
                        id: woundId,
                        imageURL: downloadURL.absoluteString,
                        timestamp: Date(),
                        location: location,
                        patientId: patient?.id ?? "",
                        userId: user.uid,
                        woundGroupId: woundGroupId,
                        woundGroupName: woundGroupName
                    )

                    completion(.success(wound))
                }
            }
        }
    }

    // MARK: - Measurements

    func addMeasurement(
        woundId: String,
        lengthCm: Double,
        widthCm: Double,
        areaCm2: Double,
        width1Cm: Double? = nil,
        width2Cm: Double? = nil,
        completion: @escaping (Result<WoundMeasurement, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "NoAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])))
            return
        }

        let col = db.collection("wounds").document(woundId).collection("measurements")

        var data: [String: Any] = [
            "length_cm": lengthCm,
            "width_cm":  widthCm,
            "area_cm2":  areaCm2,
            "measured_at": FieldValue.serverTimestamp(),
            "userId": user.uid,
            "woundId": woundId
        ]
        if let w1 = width1Cm { data["width1_cm"] = w1 }
        if let w2 = width2Cm { data["width2_cm"] = w2 }

        let doc = col.document()
        doc.setData(data) { err in
            if let err = err {
                completion(.failure(err))
                return
            }

            // Mirror latest on parent
            var latest: [String: Any] = [
                "length_cm": lengthCm,
                "width_cm":  widthCm,
                "area_cm2":  areaCm2,
                "measured_at": FieldValue.serverTimestamp(),
                "latest_measurement_id": doc.documentID
            ]
            if let w1 = width1Cm { latest["width1_cm"] = w1 }
            if let w2 = width2Cm { latest["width2_cm"] = w2 }

            self.db.collection("wounds").document(woundId).updateData(latest) { updateErr in
                if let updateErr = updateErr {
                    print("Warning: parent wound mirror update failed: \(updateErr)")
                }

                let m = WoundMeasurement(
                    id: doc.documentID,
                    length_cm: lengthCm,
                    width_cm: widthCm,
                    area_cm2: areaCm2,
                    measured_at: Date(),
                    width1_cm: width1Cm,
                    width2_cm: width2Cm,
                    userId: user.uid,
                    woundId: woundId
                )
                completion(.success(m))
            }
        }
    }

    func fetchMeasurements(
        woundId: String,
        limit: Int = 50,
        completion: @escaping (Result<[WoundMeasurement], Error>) -> Void
    ) {
        db.collection("wounds").document(woundId)
            .collection("measurements")
            .order(by: "measured_at", descending: true)
            .limit(to: limit)
            .getDocuments { snap, err in
                if let err = err {
                    completion(.failure(err))
                    return
                }
                let items: [WoundMeasurement] = snap?.documents.compactMap { WoundMeasurement(doc: $0) } ?? []
                completion(.success(items))
            }
    }

    func fetchLatestMeasurement(
        woundId: String,
        completion: @escaping (Result<WoundMeasurement?, Error>) -> Void
    ) {
        db.collection("wounds").document(woundId)
            .collection("measurements")
            .order(by: "measured_at", descending: true)
            .limit(to: 1)
            .getDocuments { snap, err in
                if let err = err {
                    completion(.failure(err))
                    return
                }
                guard let doc = snap?.documents.first, let m = WoundMeasurement(doc: doc) else {
                    completion(.success(nil))
                    return
                }
                completion(.success(m))
            }
    }
    
    // MARK: - Fetch all measurements for a wound group (for healing chart)
    
    func fetchMeasurementHistory(
        woundGroupId: String,
        completion: @escaping (Result<[WoundMeasurement], Error>) -> Void
    ) {
        // First, get all wounds in this group
        db.collection("wounds")
            .whereField("woundGroupId", isEqualTo: woundGroupId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    completion(.success([]))
                    return
                }
                
                var allMeasurements: [WoundMeasurement] = []
                let group = DispatchGroup()
                
                // For each wound, fetch its measurements
                for doc in docs {
                    let woundId = doc.documentID
                    group.enter()
                    
                    self.db.collection("wounds").document(woundId)
                        .collection("measurements")
                        .order(by: "measured_at", descending: false)
                        .getDocuments { measureSnap, measureErr in
                            defer { group.leave() }
                            
                            if let measurements = measureSnap?.documents.compactMap({ WoundMeasurement(doc: $0) }) {
                                allMeasurements.append(contentsOf: measurements)
                            }
                        }
                }
                
                group.notify(queue: .main) {
                    // Sort all measurements by date
                    let sorted = allMeasurements.sorted { $0.measured_at < $1.measured_at }
                    completion(.success(sorted))
                }
            }
    }
}
