import Foundation

struct WoundGroup: Identifiable, Decodable, Encodable {
    let id: String
    let name: String
    let patientId: String
}
