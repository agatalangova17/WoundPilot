import Foundation

struct Patient: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let name: String
    let dateOfBirth: Date
    let sex: String?
    
    // Critical comorbidities (drive treatment decisions)
    let hasDiabetes: Bool?              // nil = unknown
    let hasPAD: Bool?                   // Peripheral arterial disease
    let hasVenousDisease: Bool?
    let isImmunosuppressed: Bool?
    
    // Mobility (affects offloading, pressure ulcer risk)
    let mobilityStatus: MobilityStatus?
    let canOffload: Bool?               // Only relevant if mobility impaired
    
    // Medications that affect wound healing/bleeding
    let isOnAnticoagulants: Bool?
    let isSmoker: Bool?                 // Affects healing
    
    // Dressing allergies (prevents specific products)
    let allergyToAdhesives: Bool?
    let allergyToIodine: Bool?
    let allergyToSilver: Bool?
    let allergyToLatex: Bool?
    
    // Optional clinical details
    let weight: Double?                 // For nutrition assessment
    let otherAllergies: String?         // Free text for anything else
    let notes: String?                  // Any other relevant info
}

enum MobilityStatus: String, Codable, CaseIterable {
    case independent = "Independent"
    case usesStick = "Uses stick/cane"
    case usesWalker = "Uses walker"
    case wheelchair = "Wheelchair"
    case bedBound = "Bed-bound"
}
