import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

// Optional: a lightweight model for subcollection items
public struct WoundMeasurement: Identifiable {
    public let id: String
    public let length_cm: Double
    public let width_cm: Double
    public let area_cm2: Double
    public let measured_at: Date
    public let width1_cm: Double?
    public let width2_cm: Double?
    public let userId: String?

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
    }

    init(id: String, length_cm: Double, width_cm: Double, area_cm2: Double, measured_at: Date, width1_cm: Double?, width2_cm: Double?, userId: String?) {
        self.id = id
        self.length_cm = length_cm
        self.width_cm = width_cm
        self.area_cm2 = area_cm2
        self.measured_at = measured_at
        self.width1_cm = width1_cm
        self.width2_cm = width2_cm
        self.userId = userId
    }
}

class WoundService {
    static let shared = WoundService()
    private init() {}

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Create Wound (your original, kept intact)

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

        // (Optional) set content type metadata
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

                    // NOTE: Your Wound model is assumed to exist elsewhere in your project.
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

    // MARK: - Measurements (Option B: history subcollection + mirror latest on parent)

    /// Adds a new measurement under `wounds/{woundId}/measurements/{autoId}`
    /// and mirrors the latest values onto the parent `wounds/{woundId}` for quick access.
    ///
    /// - Parameters (all in CENTIMETERS / CM²):
    ///   - lengthCm: L in cm
    ///   - widthCm: W (avg or chosen) in cm
    ///   - areaCm2: area (ellipse or rect) in cm²
    ///   - width1Cm/width2Cm: optional transparency fields
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
            "userId": user.uid
        ]
        if let w1 = width1Cm { data["width1_cm"] = w1 }
        if let w2 = width2Cm { data["width2_cm"] = w2 }

        let doc = col.document()
        doc.setData(data) { err in
            if let err = err {
                completion(.failure(err))
                return
            }

            // Mirror "latest" fields on parent wound for fast list/detail reads
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
                    // We still succeed overall, since the history entry is written.
                    print("Warning: parent wound mirror update failed: \(updateErr)")
                }

                // Return a minimal model (server timestamp will be accurate on next read)
                let m = WoundMeasurement(
                    id: doc.documentID,
                    length_cm: lengthCm,
                    width_cm: widthCm,
                    area_cm2: areaCm2,
                    measured_at: Date(),
                    width1_cm: width1Cm,
                    width2_cm: width2Cm,
                    userId: user.uid
                )
                completion(.success(m))
            }
        }
    }

    /// Fetch recent measurements for a wound (newest first).
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

    /// Fetch only the latest measurement (if any).
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
}
