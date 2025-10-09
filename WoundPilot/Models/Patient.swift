import Foundation

struct Patient: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let name: String
    let dateOfBirth: Date
    let sex: String?
    
    // Comorbidities (drive recommendations)
    let hasDiabetes: Bool?
    let hasPAD: Bool?
    let hasVenousDisease: Bool?
    let isImmunosuppressed: Bool?
    
    // Mobility (for offloading decisions)
    let hasMobilityImpairment: Bool?
    let canOffload: Bool?
    
    // Medications (affects bleeding/healing)
    let isOnAnticoagulants: Bool?
    
    // Dressing allergies (product selection)
    let allergyToAdhesives: Bool?
    let allergyToIodine: Bool?
    let allergyToSilver: Bool?
    let allergyToLatex: Bool?
    let otherAllergies: String?
}
