import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

class WoundService {
    static let shared = WoundService()

    private init() {}

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

        let storageRef = Storage.storage().reference()
        let path = "wounds/\(user.uid)/\(UUID().uuidString).jpg"
        let imageRef = storageRef.child(path)

        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    completion(.failure(error ?? NSError(domain: "Missing URL", code: 500, userInfo: nil)))
                    return
                }

                let db = Firestore.firestore()
                let woundId = UUID().uuidString
                let woundRef = db.collection("wounds").document(woundId)

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
}
