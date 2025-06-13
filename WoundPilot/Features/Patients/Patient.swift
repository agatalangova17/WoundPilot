import Foundation

struct Patient: Identifiable, Codable {
    var id: String
    var name: String
    var dateOfBirth: Date
}
