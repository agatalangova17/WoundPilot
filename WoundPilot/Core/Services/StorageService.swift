import FirebaseStorage
import UIKit

class StorageService {
    private let storage = Storage.storage()

    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: -1)))
            return
        }

        let storageRef = storage.reference().child(path)
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                storageRef.downloadURL(completion: { url, error in
                    if let url = url {
                        completion(.success(url))
                    } else {
                        completion(.failure(error!))
                    }
                })
            }
        }
    }
}

