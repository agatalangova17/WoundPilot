import Foundation

/// Context passed from patient profile + body location + measurements to questionnaire
struct QuestionnaireContext {
    // From Patient
    let patientId: String
    let hasDiabetes: Bool?
    let hasPAD: Bool?
    let hasVenousDisease: Bool?
    let isImmunosuppressed: Bool?
    let hasMobilityImpairment: Bool?
    let canOffload: Bool?
    let isOnAnticoagulants: Bool?
    let allergyToAdhesives: Bool?
    let allergyToIodine: Bool?
    let allergyToSilver: Bool?
    let allergyToLatex: Bool?
    let otherAllergies: String?
    
    // From body location
    let bodyLocation: String? // e.g., "Right heel - plantar"
    let bodyRegionCode: String? // e.g., "heel", "ankle", "sacrum"
    let isLowerLimb: Bool // Determines if we ask perfusion questions
    
    // From measurements
    let lengthCm: Double?
    let widthCm: Double?
    let areaCm2: Double?
    
    // Computed properties for pre-filling
    var suggestedEtiology: String? {
        // Diabetic + foot location = likely diabetic foot
        if hasDiabetes == true && isFootLocation {
            return "diabeticFoot"
        }
        
        // Sacrum/heel/elbow + mobility impairment = likely pressure
        if hasMobilityImpairment == true && isPressureProneLocation {
            return "pressure"
        }
        
        // Venous disease + lower leg = likely venous
        if hasVenousDisease == true && (bodyRegionCode == "lower_leg" || bodyRegionCode == "ankle") {
            return "venous"
        }
        
        // PAD + foot = likely arterial
        if hasPAD == true && isFootLocation {
            return "arterial"
        }
        
        return nil
    }
    
    var shouldAskPerfusion: Bool {
        // Only ask for lower limb wounds where compression might be considered
        return isLowerLimb
    }
    
    var shouldAskBoneQuestions: Bool {
        // Only for diabetic foot or if we suspect deep infection
        return hasDiabetes == true && isFootLocation
    }
    
    // Helper computed properties
    var isFootLocation: Bool {
            guard let r = bodyRegionCode?.lowercased() else { return false }
            return r.contains("foot") || r.contains("heel") || r.contains("toe")
        }
    
    private var isPressureProneLocation: Bool {
        guard let region = bodyRegionCode else { return false }
        return region.contains("sacrum") || region.contains("heel") ||
               region.contains("elbow") || region.contains("hip")
    }
}
