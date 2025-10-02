import Foundation

struct WoundGroup: Identifiable, Decodable, Encodable {
    let id: String
    let name: String
    let patientId: String

    // Prepare for detailed localization (optional for now)
    let bodyRegionCode: String?   // e.g., "ankle", "heel", "knee"
    let side: String?             // "left" | "right" | "midline"
    let subsite: String?          // e.g., "lateral", "medial", "plantar"
}
