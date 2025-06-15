import Foundation

struct Patient: Identifiable, Codable {
    let id: String
    let name: String
    let dateOfBirth: Date

    // Optional fields
    let sex: String?
    let isDiabetic: Bool?
    let isSmoker: Bool?
    let hasPAD: Bool?
    let hasMobilityIssues: Bool?
    let hasBloodPressureIssues: Bool?
    let weight: Double?
    let allergies: String?
    let bloodPressure: String?
    let diabetesType: String?
}
