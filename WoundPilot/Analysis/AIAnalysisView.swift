import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Data Models

struct QuestionnairePayload {
    let woundBedTypes: Set<String>
    let exudate: String
    let hasDeepSpaces: Bool
    let deepSpaceType: Set<String>
    let periwoundSkin: String
    
    let hasWarmth: Bool
    let hasPurulentDischarge: Bool
    let hasOdor: Bool
    let hasSpreadingRedness: Bool
    let hasErythemaGt2cm: Bool
    let hasFever: Bool
    let hasCrepitus: Bool
    
    let hasExposedBone: Bool
    let probeToBonePositive: Bool
    
    let pedalPulsesPalpable: Bool?
    let coldPaleFoot: Bool
    let restPainRelievedByHanging: Bool
    let abi: String

    static func from(_ dict: [String: Any]) -> QuestionnairePayload {
        func s(_ key: String) -> String {
            (dict[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
        }
        func b(_ key: String) -> Bool { dict[key] as? Bool ?? false }
        func set(_ key: String) -> Set<String> {
            Set(dict[key] as? [String] ?? [])
        }
        
        var warmth = false, purulent = false, odor = false, spreading = false
        var erythemaGt2 = false, fever = false, crepitus = false
        
        if let infectionSigns = dict["infectionSigns"] as? [String: Any] {
            warmth = infectionSigns["warmth"] as? Bool ?? false
            purulent = infectionSigns["purulentDischarge"] as? Bool ?? false
            odor = infectionSigns["odor"] as? Bool ?? false
            spreading = infectionSigns["spreadingRedness"] as? Bool ?? false
            erythemaGt2 = infectionSigns["erythemaGt2cm"] as? Bool ?? false
            fever = infectionSigns["fever"] as? Bool ?? false
            crepitus = infectionSigns["crepitus"] as? Bool ?? false
        }

        return QuestionnairePayload(
            woundBedTypes: set("woundBedTypes"),
            exudate: s("exudate"),
            hasDeepSpaces: b("hasDeepSpaces"),
            deepSpaceType: set("deepSpaceType"),
            periwoundSkin: s("periwoundSkin"),
            hasWarmth: warmth,
            hasPurulentDischarge: purulent,
            hasOdor: odor,
            hasSpreadingRedness: spreading,
            hasErythemaGt2cm: erythemaGt2,
            hasFever: fever,
            hasCrepitus: crepitus,
            hasExposedBone: b("hasExposedBone"),
            probeToBonePositive: b("probeToBonePositive"),
            pedalPulsesPalpable: dict["pedalPulsesPalpable"] as? Bool,
            coldPaleFoot: b("coldPaleFoot"),
            restPainRelievedByHanging: b("restPainRelievedByHanging"),
            abi: s("abi")
        )
    }
    
    var infectionSeverity: InfectionSeverity {
        if hasFever || hasCrepitus || hasSpreadingRedness { return .systemic }
        if hasWarmth || hasPurulentDischarge || hasOdor || hasErythemaGt2cm { return .local }
        return .none
    }
    
    var dominantTissueType: String {
        if woundBedTypes.contains("necrosis") { return "necrosis" }
        if woundBedTypes.contains("slough") { return "slough" }
        if woundBedTypes.contains("granulation") { return "granulation" }
        if woundBedTypes.contains("epithelializing") { return "epithelializing" }
        return "unknown"
    }
}

enum InfectionSeverity { case none, local, systemic }

// MARK: - Enhanced Report Models

struct AIReport {
    let diagnosis: String
    let etiology: String
    let healingPhase: String
    
    let woundBedAssessment: WoundBedAssessment
    let exudateLevel: ExudateAssessment
    let infectionStatus: InfectionAssessment
    let periwoundStatus: PeriwoundAssessment
    let deepSpacesPresent: Bool
    let deepSpaceTypes: [String]
    
    let perfusionStatus: PerfusionStatus?
    let boneInvolvement: BoneStatus?
    
    let treatmentGoals: [TreatmentGoal]
    let clinicalStrategies: [ClinicalStrategy]
    let patientConsiderations: [PatientConsideration]
    let barriersToHealing: [HealingBarrier]
    
    let followUpPlan: FollowUpPlan
    let redFlags: [String]
    let urgentActions: [String]
}

struct WoundBedAssessment {
    let tissueTypes: Set<String>
    let dominantTissue: String
    let summary: String
    let concernLevel: ConcernLevel
}

struct ExudateAssessment {
    let level: String
    let description: String
    let managementStrategy: String
}

struct InfectionAssessment {
    let severity: InfectionSeverity
    let signs: [String]
    let summary: String
    let requiresUrgentAction: Bool
}

struct PeriwoundAssessment {
    let status: String
    let description: String
    let intervention: String?
}

struct PerfusionStatus {
    let abi: String
    let pulses: Bool?
    let clinicalSigns: [String]
    let summary: String
    let compressionSafe: CompressionSafety
}

struct BoneStatus {
    let exposedBone: Bool
    let probeToBone: Bool
    let summary: String
    let requiresImaging: Bool
}

enum CompressionSafety {
    case full, reduced, contraindicated
}

enum ConcernLevel {
    case low, moderate, high, critical
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct TreatmentGoal: Identifiable {
    let id = UUID()
    let priority: Int
    let goal: String
    let rationale: String
}

struct ClinicalStrategy: Identifiable {
    let id = UUID()
    let category: StrategyCategory
    let strategy: String
    let rationale: String
    let priority: Priority
}

enum StrategyCategory {
    case debridement, moistureBalance, infectionControl, perfusion, offloading, compression, woundProtection, patientEducation
    
    var icon: String {
        switch self {
        case .debridement: return "scissors"
        case .moistureBalance: return "drop.fill"
        case .infectionControl: return "bandage.fill"
        case .perfusion: return "heart.text.square.fill"
        case .offloading: return "figure.walk.circle"
        case .compression: return "arrow.up.and.down.circle.fill"
        case .woundProtection: return "shield.lefthalf.fill"
        case .patientEducation: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .debridement: return .orange
        case .moistureBalance: return .blue
        case .infectionControl: return .red
        case .perfusion: return .purple
        case .offloading: return .green
        case .compression: return .indigo
        case .woundProtection: return .teal
        case .patientEducation: return .cyan
        }
    }
}

enum Priority {
    case critical, high, standard
    
    var badge: String {
        switch self {
        case .critical: return "🔴"
        case .high: return "🟡"
        case .standard: return ""
        }
    }
}

struct PatientConsideration: Identifiable {
    let id = UUID()
    let factor: String
    let impact: String
    let action: String
}

struct HealingBarrier: Identifiable {
    let id = UUID()
    let barrier: String
    let severity: BarrierSeverity
    let mitigation: String
}

enum BarrierSeverity {
    case minor, moderate, major, critical
    
    var color: Color {
        switch self {
        case .minor: return .yellow
        case .moderate: return .orange
        case .major: return .red
        case .critical: return .purple
        }
    }
}

struct FollowUpPlan {
    let initialReview: String
    let ongoingFrequency: String
    let progressIndicators: [String]
    let escalationCriteria: [String]
}

// MARK: - Rules Engine

struct RulesEngine {
    static func analyze(_ q: QuestionnairePayload, context: QuestionnaireContext) -> AIReport {
        let etiology = context.suggestedEtiology ?? inferEtiology(q, context)
        
        let woundBedAssessment = assessWoundBed(q)
        let exudateAssessment = assessExudate(q)
        let infectionAssessment = assessInfection(q)
        let periwoundAssessment = assessPeriwound(q)
        let perfusionStatus = context.isLowerLimb ? assessPerfusion(q) : nil
        let boneStatus = (context.hasDiabetes == true && context.isFootLocation) || q.woundBedTypes.contains("necrosis") ? assessBone(q) : nil
        
        let treatmentGoals = buildTreatmentGoals(q, context, etiology)
        let clinicalStrategies = buildClinicalStrategies(q, context, etiology, woundBedAssessment, infectionAssessment, perfusionStatus)
        let patientConsiderations = buildPatientConsiderations(context, q)
        let barriersToHealing = identifyBarriers(q, context, etiology)
        
        let followUpPlan = buildFollowUpPlan(q, context, etiology, infectionAssessment)
        let (redFlags, urgentActions) = identifyUrgentIssues(q, context, infectionAssessment, perfusionStatus, boneStatus)
        
        let diagnosis = generateDiagnosis(etiology, infectionAssessment, perfusionStatus, woundBedAssessment)
        let healingPhase = mapHealingPhase(woundBedAssessment.dominantTissue)
        
        return AIReport(
            diagnosis: diagnosis,
            etiology: etiology,
            healingPhase: healingPhase,
            woundBedAssessment: woundBedAssessment,
            exudateLevel: exudateAssessment,
            infectionStatus: infectionAssessment,
            periwoundStatus: periwoundAssessment,
            deepSpacesPresent: q.hasDeepSpaces,
            deepSpaceTypes: Array(q.deepSpaceType),
            perfusionStatus: perfusionStatus,
            boneInvolvement: boneStatus,
            treatmentGoals: treatmentGoals,
            clinicalStrategies: clinicalStrategies,
            patientConsiderations: patientConsiderations,
            barriersToHealing: barriersToHealing,
            followUpPlan: followUpPlan,
            redFlags: redFlags,
            urgentActions: urgentActions
        )
    }
    
    // MARK: - Assessment Functions
    
    private static func assessWoundBed(_ q: QuestionnairePayload) -> WoundBedAssessment {
        let dominant = q.dominantTissueType
        let types = q.woundBedTypes
        
        let summary: String
        let concern: ConcernLevel
        
        if types.contains("necrosis") {
            summary = "Wound bed contains necrotic tissue requiring debridement. Non-viable tissue prevents healing and increases infection risk."
            concern = .high
        } else if types.contains("slough") {
            summary = "Sloughy wound bed indicates devitalized tissue. Autolytic or sharp debridement needed to progress healing."
            concern = .moderate
        } else if types.contains("granulation") {
            if types.count == 1 {
                summary = "Healthy granulation tissue present - wound is in active healing phase."
                concern = .low
            } else {
                summary = "Mixed wound bed with granulation tissue. Address barriers to optimize healing environment."
                concern = .moderate
            }
        } else if types.contains("epithelializing") {
            summary = "Epithelialization occurring - wound in final healing stage. Protect new tissue."
            concern = .low
        } else {
            summary = "Wound bed assessment incomplete."
            concern = .moderate
        }
        
        return WoundBedAssessment(
            tissueTypes: types,
            dominantTissue: dominant,
            summary: summary,
            concernLevel: concern
        )
    }
    
    private static func assessExudate(_ q: QuestionnairePayload) -> ExudateAssessment {
        let level = q.exudate
        
        let description: String
        let strategy: String
        
        switch level {
        case "dry":
            description = "Dry wound bed - insufficient moisture for optimal healing"
            strategy = "Rehydrate wound bed and maintain moist healing environment"
        case "low":
            description = "Minimal exudate - wound environment adequate"
            strategy = "Maintain moisture balance with appropriate dressing absorbency"
        case "moderate":
            description = "Moderate exudate levels - requires balanced moisture management"
            strategy = "Balance moisture - absorb excess while maintaining moist interface"
        case "high":
            description = "High exudate burden - risk of maceration and delayed healing"
            strategy = "High absorbency management essential to protect periwound skin"
        default:
            description = "Exudate level not assessed"
            strategy = "Assess and manage moisture balance"
        }
        
        return ExudateAssessment(
            level: level,
            description: description,
            managementStrategy: strategy
        )
    }
    
    private static func assessInfection(_ q: QuestionnairePayload) -> InfectionAssessment {
        let severity = q.infectionSeverity
        var signs: [String] = []
        
        if q.hasWarmth { signs.append("Local warmth") }
        if q.hasPurulentDischarge { signs.append("Purulent discharge") }
        if q.hasOdor { signs.append("Foul odor") }
        if q.hasSpreadingRedness { signs.append("Spreading erythema") }
        if q.hasErythemaGt2cm { signs.append("Erythema >2cm from wound edge") }
        if q.hasFever { signs.append("Systemic fever") }
        if q.hasCrepitus { signs.append("Crepitus (gas formation)") }
        
        let summary: String
        let urgent: Bool
        
        switch severity {
        case .none:
            summary = "No signs of wound infection - maintain vigilance"
            urgent = false
        case .local:
            summary = "Local infection present. Requires antimicrobial management and close monitoring for progression."
            urgent = false
        case .systemic:
            summary = "SYSTEMIC INFECTION - spreading infection with systemic involvement. Requires urgent medical intervention."
            urgent = true
        }
        
        return InfectionAssessment(
            severity: severity,
            signs: signs,
            summary: summary,
            requiresUrgentAction: urgent
        )
    }
    
    private static func assessPeriwound(_ q: QuestionnairePayload) -> PeriwoundAssessment {
        let status = q.periwoundSkin
        
        let description: String
        let intervention: String?
        
        switch status {
        case "normal":
            description = "Periwound skin intact and healthy"
            intervention = nil
        case "macerated":
            description = "Periwound maceration - excessive moisture damage to surrounding skin"
            intervention = "Apply barrier protection and optimize exudate management"
        case "fragile":
            description = "Fragile periwound skin - increased risk of extension and trauma"
            intervention = "Gentle handling, atraumatic dressing removal, protective barrier"
        default:
            description = "Periwound status requires assessment"
            intervention = "Assess and protect surrounding skin"
        }
        
        return PeriwoundAssessment(
            status: status,
            description: description,
            intervention: intervention
        )
    }
    
    private static func assessPerfusion(_ q: QuestionnairePayload) -> PerfusionStatus {
        let abi = q.abi
        let pulses = q.pedalPulsesPalpable
        var clinicalSigns: [String] = []
        
        if q.coldPaleFoot { clinicalSigns.append("Cold, pale foot") }
        if q.restPainRelievedByHanging { clinicalSigns.append("Rest pain (relieved by dependency)") }
        if pulses == false { clinicalSigns.append("Absent pedal pulses") }
        
        let summary: String
        let compressionSafe: CompressionSafety
        
        if abi == "lt0_5" || pulses == false || !clinicalSigns.isEmpty {
            summary = "CRITICAL LIMB ISCHEMIA - severely impaired arterial perfusion. Urgent vascular assessment required."
            compressionSafe = .contraindicated
        } else if abi == "p0_5to0_79" {
            summary = "Reduced arterial perfusion (ABI 0.5-0.79). Vascular assessment recommended. Compression only with caution."
            compressionSafe = .reduced
        } else if abi == "ge0_8" {
            summary = "Adequate arterial perfusion (ABI ≥0.8). Compression therapy safe if indicated."
            compressionSafe = .full
        } else {
            summary = "Perfusion status unknown - ABI measurement recommended before compression therapy."
            compressionSafe = .contraindicated
        }
        
        return PerfusionStatus(
            abi: abi,
            pulses: pulses,
            clinicalSigns: clinicalSigns,
            summary: summary,
            compressionSafe: compressionSafe
        )
    }
    
    private static func assessBone(_ q: QuestionnairePayload) -> BoneStatus {
        let exposed = q.hasExposedBone
        let probe = q.probeToBonePositive
        
        let summary: String
        let imaging: Bool
        
        if exposed || probe {
            summary = "BONE INVOLVEMENT DETECTED - high risk of osteomyelitis. Requires imaging (X-ray/MRI) and possible bone biopsy."
            imaging = true
        } else {
            summary = "No evidence of bone involvement on clinical examination."
            imaging = false
        }
        
        return BoneStatus(
            exposedBone: exposed,
            probeToBone: probe,
            summary: summary,
            requiresImaging: imaging
        )
    }
    
    // MARK: - Strategic Planning
    
    private static func buildTreatmentGoals(_ q: QuestionnairePayload, _ context: QuestionnaireContext, _ etiology: String) -> [TreatmentGoal] {
        var goals: [TreatmentGoal] = []
        var priority = 1
        
        if q.infectionSeverity == .systemic {
            goals.append(TreatmentGoal(
                priority: priority,
                goal: "Control systemic infection",
                rationale: "Life-threatening infection requires immediate systemic antibiotics and urgent medical review"
            ))
            priority += 1
        }
        
        if q.hasExposedBone || q.probeToBonePositive {
            goals.append(TreatmentGoal(
                priority: priority,
                goal: "Rule out osteomyelitis",
                rationale: "Bone involvement significantly impacts treatment approach and healing timeline"
            ))
            priority += 1
        }
        
        if q.woundBedTypes.contains("necrosis") || q.woundBedTypes.contains("slough") {
            goals.append(TreatmentGoal(
                priority: priority,
                goal: "Achieve clean, vascularized wound bed",
                rationale: "Remove devitalized tissue to enable granulation and reduce infection risk"
            ))
            priority += 1
        }
        
        switch etiology {
        case "venous":
            goals.append(TreatmentGoal(
                priority: priority,
                goal: "Restore venous return and reduce edema",
                rationale: "Venous hypertension is primary cause - compression essential for healing"
            ))
        case "arterial":
            goals.append(TreatmentGoal(
                priority: priority,
                goal: "Optimize tissue perfusion",
                rationale: "Inadequate blood supply prevents healing - revascularization may be needed"
            ))
        case "diabeticFoot":
            goals.append(TreatmentGoal(
                priority: priority,
                goal: "Achieve complete offloading and glycemic control",
                rationale: "Pressure and hyperglycemia are major barriers to diabetic foot ulcer healing"
            ))
        case "pressure":
            goals.append(TreatmentGoal(
                priority: priority,
                goal: "Eliminate pressure and shear forces",
                rationale: "Sustained pressure caused the wound - must be completely relieved for healing"
            ))
        default:
            break
        }
        priority += 1
        
        goals.append(TreatmentGoal(
            priority: priority,
            goal: "Maintain optimal wound healing environment",
            rationale: "Balance moisture, control bioburden, protect periwound skin to enable healing"
        ))
        
        return goals
    }
    
    private static func buildClinicalStrategies(_ q: QuestionnairePayload, _ context: QuestionnaireContext, _ etiology: String, _ woundBed: WoundBedAssessment, _ infection: InfectionAssessment, _ perfusion: PerfusionStatus?) -> [ClinicalStrategy] {
        
        var strategies: [ClinicalStrategy] = []
        
        if q.woundBedTypes.contains("necrosis") {
            strategies.append(ClinicalStrategy(
                category: .debridement,
                strategy: "Surgical/sharp debridement of necrotic tissue",
                rationale: "Eschar and necrotic tissue must be removed to expose viable tissue and enable healing",
                priority: .high
            ))
        } else if q.woundBedTypes.contains("slough") {
            strategies.append(ClinicalStrategy(
                category: .debridement,
                strategy: "Promote autolytic debridement",
                rationale: "Devitalized tissue can be softened and removed by body's natural enzymes in moist environment",
                priority: .standard
            ))
        }
        
        strategies.append(ClinicalStrategy(
            category: .moistureBalance,
            strategy: q.exudate == "dry" ? "Rehydrate and maintain moist wound environment" :
                     q.exudate == "high" ? "High absorbency exudate management" :
                     "Balance moisture levels",
            rationale: q.exudate == "dry" ? "Dry wounds heal slowly - moisture promotes cell migration" :
                      q.exudate == "high" ? "Excess exudate causes maceration and prolongs inflammation" :
                      "Maintain optimal moisture for cellular activity",
            priority: .standard
        ))
        
        if infection.severity != .none {
            strategies.append(ClinicalStrategy(
                category: .infectionControl,
                strategy: infection.severity == .systemic ?
                    "Urgent systemic antibiotic therapy" :
                    "Topical antimicrobial therapy and bioburden reduction",
                rationale: infection.severity == .systemic ?
                    "Systemic infection requires IV antibiotics per local guidelines" :
                    "Reduce bacterial load to enable healing progression",
                priority: infection.severity == .systemic ? .critical : .high
            ))
        }
        
        switch etiology {
        case "venous":
            if let perf = perfusion {
                switch perf.compressionSafe {
                case .full:
                    strategies.append(ClinicalStrategy(
                        category: .compression,
                        strategy: "Full compression therapy (30-40mmHg)",
                        rationale: "Compression reverses venous hypertension - essential for venous ulcer healing",
                        priority: .critical
                    ))
                case .reduced:
                    strategies.append(ClinicalStrategy(
                        category: .compression,
                        strategy: "Modified compression (20-30mmHg) with close monitoring",
                        rationale: "Reduced perfusion allows only lower compression - balance venous return with arterial supply",
                        priority: .high
                    ))
                case .contraindicated:
                    strategies.append(ClinicalStrategy(
                        category: .compression,
                        strategy: "NO COMPRESSION - perfusion inadequate",
                        rationale: "Compression would further compromise arterial blood flow - address perfusion first",
                        priority: .critical
                    ))
                }
            }
            
            strategies.append(ClinicalStrategy(
                category: .patientEducation,
                strategy: "Leg elevation and ankle exercises",
                rationale: "Reduces venous pooling and edema between dressing changes",
                priority: .standard
            ))
            
        case "arterial":
            strategies.append(ClinicalStrategy(
                category: .perfusion,
                strategy: "URGENT vascular surgery referral",
                rationale: "Arterial ulcers will not heal without restoring blood flow",
                priority: .critical
            ))
            
            strategies.append(ClinicalStrategy(
                category: .debridement,
                strategy: "Avoid aggressive debridement until perfusion optimized",
                rationale: "Ischemic tissue cannot heal - debridement without blood flow causes extension",
                priority: .critical
            ))
            
        case "diabeticFoot":
            strategies.append(ClinicalStrategy(
                category: .offloading,
                strategy: "Complete offloading with total contact cast or equivalent",
                rationale: "Pressure at wound site prevents healing - must be eliminated entirely",
                priority: .critical
            ))
            
            strategies.append(ClinicalStrategy(
                category: .patientEducation,
                strategy: "Optimize glycemic control (target HbA1c <7%)",
                rationale: "Hyperglycemia impairs immune function and wound healing",
                priority: .high
            ))
            
            if q.probeToBonePositive || q.hasExposedBone {
                strategies.append(ClinicalStrategy(
                    category: .infectionControl,
                    strategy: "Imaging (X-ray/MRI) to confirm osteomyelitis",
                    rationale: "Bone infection requires prolonged antibiotics or surgical resection",
                    priority: .critical
                ))
            }
            
        case "pressure":
            strategies.append(ClinicalStrategy(
                category: .offloading,
                strategy: "Complete pressure redistribution",
                rationale: "Sustained pressure caused wound - must be eliminated for healing",
                priority: .critical
            ))
            
            strategies.append(ClinicalStrategy(
                category: .patientEducation,
                strategy: "Reposition every 2 hours and use pressure-redistributing surfaces",
                rationale: "Prevention of extension and new ulcer formation",
                priority: .high
            ))
            
        default:
            break
        }
        
        if q.hasDeepSpaces {
            strategies.append(ClinicalStrategy(
                category: .woundProtection,
                strategy: "Loosely pack cavities and undermined areas",
                rationale: "Dead space allows abscess formation - must be obliterated while allowing drainage",
                priority: .high
            ))
        }
        
        if q.periwoundSkin == "macerated" || q.exudate == "high" {
            strategies.append(ClinicalStrategy(
                category: .woundProtection,
                strategy: "Protect periwound skin with barrier products",
                rationale: "Maceration extends wound size and delays healing",
                priority: .standard
            ))
        }
        
        return strategies
    }
    
    private static func buildPatientConsiderations(_ context: QuestionnaireContext, _ q: QuestionnairePayload) -> [PatientConsideration] {
        var considerations: [PatientConsideration] = []
        
        if context.hasDiabetes == true {
            considerations.append(PatientConsideration(
                factor: "Diabetes mellitus",
                impact: "Impaired immune function, neuropathy, delayed healing",
                action: "Optimize glucose control (HbA1c <7%), daily foot inspection, appropriate footwear"
            ))
        }
        
        if context.hasPAD == true {
            considerations.append(PatientConsideration(
                factor: "Peripheral arterial disease",
                impact: "Reduced tissue perfusion limits healing potential",
                action: "Vascular assessment, consider revascularization, avoid vasoconstrictors"
            ))
        }
        
        if context.hasVenousDisease == true {
            considerations.append(PatientConsideration(
                factor: "Chronic venous insufficiency",
                impact: "Venous hypertension drives ulcer formation and recurrence",
                action: "Compression therapy essential, leg elevation, calf muscle pump exercises"
            ))
        }
        
        if context.isImmunosuppressed == true {
            considerations.append(PatientConsideration(
                factor: "Immunosuppression",
                impact: "Increased infection risk, slower healing response",
                action: "Lower threshold for antimicrobial therapy, closer monitoring"
            ))
        }
        
        if context.hasMobilityImpairment == true {
            considerations.append(PatientConsideration(
                factor: "Mobility impairment",
                impact: "Difficulty with offloading and pressure relief",
                action: "Assistive devices, pressure-redistributing surfaces, caregiver education"
            ))
        }
        
        if context.isOnAnticoagulants == true {
            considerations.append(PatientConsideration(
                factor: "Anticoagulation therapy",
                impact: "Increased bleeding risk during debridement",
                action: "Gentle debridement technique, hemostatic dressings if needed"
            ))
        }
        
        return considerations
    }
    
    private static func identifyBarriers(_ q: QuestionnairePayload, _ context: QuestionnaireContext, _ etiology: String) -> [HealingBarrier] {
        var barriers: [HealingBarrier] = []
        
        if q.infectionSeverity == .systemic {
            barriers.append(HealingBarrier(
                barrier: "Systemic wound infection",
                severity: .critical,
                mitigation: "IV antibiotics per protocol, source control, urgent medical review"
            ))
        } else if q.infectionSeverity == .local {
            barriers.append(HealingBarrier(
                barrier: "Local wound infection",
                severity: .major,
                mitigation: "Antimicrobial therapy, bioburden reduction, monitor for progression"
            ))
        }
        
        if q.woundBedTypes.contains("necrosis") {
            barriers.append(HealingBarrier(
                barrier: "Necrotic tissue",
                severity: .major,
                mitigation: "Debridement required before healing can progress"
            ))
        }
        
        if q.abi == "lt0_5" || q.pedalPulsesPalpable == false {
            barriers.append(HealingBarrier(
                barrier: "Critical limb ischemia",
                severity: .critical,
                mitigation: "Vascular surgery consultation for revascularization"
            ))
        }
        
        if q.hasExposedBone || q.probeToBonePositive {
            barriers.append(HealingBarrier(
                barrier: "Possible osteomyelitis",
                severity: .critical,
                mitigation: "Imaging, bone biopsy, prolonged antibiotics or surgical debridement"
            ))
        }
        
        if context.hasVenousDisease == true && etiology == "venous" {
            barriers.append(HealingBarrier(
                barrier: "Venous hypertension",
                severity: .major,
                mitigation: "Compression therapy (if arterial supply adequate) is mandatory"
            ))
        }
        
        if q.exudate == "high" {
            barriers.append(HealingBarrier(
                barrier: "High exudate burden",
                severity: .moderate,
                mitigation: "High absorbency management, frequent changes, periwound protection"
            ))
        }
        
        if q.hasDeepSpaces {
            barriers.append(HealingBarrier(
                barrier: "Dead space (cavities/undermining)",
                severity: .moderate,
                mitigation: "Loose packing to obliterate dead space and prevent abscess"
            ))
        }
        
        return barriers
    }
    
    private static func buildFollowUpPlan(_ q: QuestionnairePayload, _ context: QuestionnaireContext, _ etiology: String, _ infection: InfectionAssessment) -> FollowUpPlan {
        let initialReview: String
        let ongoingFrequency: String
        
        if infection.requiresUrgentAction || q.hasExposedBone || q.abi == "lt0_5" {
            initialReview = "24-48 hours (URGENT)"
            ongoingFrequency = "Every 2-3 days until stabilized, then weekly"
        } else if infection.severity == .local || etiology == "arterial" {
            initialReview = "3-5 days"
            ongoingFrequency = "Weekly until healing trajectory established"
        } else {
            initialReview = "7 days"
            ongoingFrequency = "Every 1-2 weeks depending on progress"
        }
        
        let progressIndicators = [
            "Wound bed improving (increasing granulation, decreasing slough/necrosis)",
            "Reducing wound dimensions (length, width, depth)",
            "Decreasing exudate levels",
            "Improving periwound skin integrity",
            "Resolution of infection signs",
            "Pain reduction (if initially present)"
        ]
        
        let escalationCriteria = [
            "Wound enlargement or deepening",
            "New or worsening infection signs",
            "Exposed bone or tendon",
            "Sudden increase in pain",
            "Loss of perfusion (cold, pale limb)",
            "Crepitus or gas formation",
            "No progress after 2-4 weeks"
        ]
        
        return FollowUpPlan(
            initialReview: initialReview,
            ongoingFrequency: ongoingFrequency,
            progressIndicators: progressIndicators,
            escalationCriteria: escalationCriteria
        )
    }
    
    private static func identifyUrgentIssues(_ q: QuestionnairePayload, _ context: QuestionnaireContext, _ infection: InfectionAssessment, _ perfusion: PerfusionStatus?, _ bone: BoneStatus?) -> ([String], [String]) {
        var redFlags: [String] = []
        var urgentActions: [String] = []
        
        if infection.requiresUrgentAction {
            redFlags.append("🔴 Systemic infection with \(infection.signs.joined(separator: ", "))")
            urgentActions.append("Immediate medical evaluation for IV antibiotics")
        }
        
        if bone?.requiresImaging == true {
            redFlags.append("🔴 Suspected osteomyelitis")
            urgentActions.append("Urgent imaging (X-ray/MRI) and specialist referral")
        }
        
        if perfusion?.compressionSafe == .contraindicated && (perfusion?.abi == "lt0_5" || perfusion?.pulses == false) {
            redFlags.append("🔴 Critical limb ischemia")
            urgentActions.append("Emergency vascular surgery referral within 24 hours")
        }
        
        if q.hasCrepitus {
            redFlags.append("🔴 Crepitus - possible necrotizing infection")
            urgentActions.append("IMMEDIATE surgical evaluation")
        }
        
        return (redFlags, urgentActions)
    }
    
    // MARK: - Helpers
    
    private static func inferEtiology(_ q: QuestionnairePayload, _ context: QuestionnaireContext) -> String {
        if context.hasDiabetes == true && context.isFootLocation {
            return "diabeticFoot"
        }
        if context.hasPAD == true {
            return "arterial"
        }
        if context.hasVenousDisease == true {
            return "venous"
        }
        if context.hasMobilityImpairment == true {
            return "pressure"
        }
        return "mixed"
    }
    
    private static func generateDiagnosis(_ etiology: String, _ infection: InfectionAssessment, _ perfusion: PerfusionStatus?, _ woundBed: WoundBedAssessment) -> String {
        var diagnosis = ""
        
        if infection.severity == .systemic {
            diagnosis = "Infected "
        } else if infection.severity == .local {
            diagnosis = "Locally infected "
        }
        
        switch etiology {
        case "venous":
            diagnosis += "chronic venous leg ulcer"
        case "arterial":
            if perfusion?.abi == "lt0_5" {
                diagnosis += "arterial ulcer with critical limb ischemia"
            } else {
                diagnosis += "arterial insufficiency ulcer"
            }
        case "diabeticFoot":
            diagnosis += "diabetic foot ulcer"
        case "pressure":
            diagnosis += "pressure ulcer"
        case "mixed":
            diagnosis += "mixed etiology chronic wound"
        default:
            diagnosis += "chronic wound"
        }
        
        diagnosis += " in \(mapHealingPhase(woundBed.dominantTissue).lowercased()) phase"
        
        return diagnosis
    }
    
    private static func mapHealingPhase(_ tissue: String) -> String {
        switch tissue {
        case "necrosis": return "Necrotic (non-healing)"
        case "slough": return "Inflammatory"
        case "granulation": return "Proliferative (healing)"
        case "epithelializing": return "Maturation (final healing)"
        default: return "Undetermined"
        }
    }
}

// MARK: - Report View

struct ReportView: View {
    let woundGroupId: String
    let patientId: String
    let context: QuestionnaireContext
    let questionnaireData: [String: Any]
    let measurementResult: WoundMeasurementResult?
    let isQuickScan: Bool

    @State private var loading = true
    @State private var report: AIReport?
    @State private var payload: QuestionnairePayload?
    @State private var animate = false
    @State private var goToDressing = false
    @State private var expandedSections: Set<String> = []

    var body: some View {
        Group {
            if loading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Analyzing wound...")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())

            } else if let report {
                ScrollView {
                    VStack(spacing: 20) {
                        // Quick scan banner
                        if isQuickScan {
                            quickScanBanner
                        }

                        // Urgent alerts
                        if !report.urgentActions.isEmpty {
                            urgentAlerts(report)
                        }

                        // Diagnosis header
                        diagnosisHeader(report)

                        // Clinical assessment
                        clinicalAssessmentSection(report)

                        // Treatment goals
                        treatmentGoalsSection(report)

                        // Clinical strategies
                        clinicalStrategiesSection(report)

                        // Patient considerations
                        if !report.patientConsiderations.isEmpty {
                            patientConsiderationsSection(report)
                        }

                        // Barriers to healing
                        if !report.barriersToHealing.isEmpty {
                            barriersToHealingSection(report)
                        }

                        // Follow-up plan
                        followUpPlanSection(report)

                        // Dressing button
                        Button {
                            goToDressing = true
                        } label: {
                            Label("View Dressing Recommendations",
                                  systemImage: "bandage.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.green)
                                )
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationDestination(isPresented: $goToDressing) {
                    if let payload = payload, let measurements = measurementResult {
                        DressingRecommendationView(
                            measurements: measurements,
                            assessment: payload,
                            context: context
                        )
                    }
                }
                .onAppear { animate = true }

            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Failed to load analysis")
                        .foregroundColor(.secondary)
                    Button("Retry") { loadReport() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadReport() }
    }

    // MARK: - Sections

    private var quickScanBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .foregroundColor(.blue)
            Text("Quick Scan – Not saved to patient records")
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func urgentAlerts(_ report: AIReport) -> some View {
        VStack(spacing: 12) {
            ForEach(report.urgentActions, id: \.self) { action in
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("URGENT ACTION REQUIRED")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.red)
                        Text(action)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : -10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animate)
    }

    private func diagnosisHeader(_ report: AIReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "stethoscope")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.blue))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("DIAGNOSIS")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                    Text(report.diagnosis)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                diagnosisChip(icon: "bandage.fill", label: "Etiology", value: mapEtiologyLabel(report.etiology))
                diagnosisChip(icon: "waveform.path.ecg", label: "Phase", value: report.healingPhase)
            }

            if let measurements = measurementResult {
                HStack(spacing: 12) {
                    diagnosisChip(icon: "ruler", label: "Size", value: "\(String(format: "%.1f", measurements.lengthCm)) × \(String(format: "%.1f", measurements.widthCm)) cm")
                    if let location = context.bodyLocation {
                        diagnosisChip(icon: "cross.case", label: "Location", value: location.replacingOccurrences(of: "|", with: " · "))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)
    }

    private func diagnosisChip(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func clinicalAssessmentSection(_ report: AIReport) -> some View {
        SectionCard(title: "Clinical Assessment", icon: "doc.text.magnifyingglass") {
            VStack(spacing: 16) {
                // Wound bed
                AssessmentRow(
                    title: "Wound Bed",
                    value: report.woundBedAssessment.dominantTissue.capitalized,
                    detail: report.woundBedAssessment.summary,
                    concernLevel: report.woundBedAssessment.concernLevel
                )

                Divider()

                // Exudate
                AssessmentRow(
                    title: "Exudate",
                    value: report.exudateLevel.level.capitalized,
                    detail: report.exudateLevel.description,
                    concernLevel: .low
                )

                Divider()

                // Infection
                AssessmentRow(
                    title: "Infection Status",
                    value: report.infectionStatus.severity == .none ? "None" :
                           report.infectionStatus.severity == .local ? "Local" : "Systemic",
                    detail: report.infectionStatus.summary,
                    concernLevel: report.infectionStatus.severity == .systemic ? .critical :
                                  report.infectionStatus.severity == .local ? .high : .low,
                    badges: report.infectionStatus.signs.isEmpty ? nil : report.infectionStatus.signs
                )

                if !report.infectionStatus.signs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Clinical Signs:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(report.infectionStatus.signs, id: \.self) { sign in
                                Text(sign)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.red.opacity(0.15)))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Divider()

                // Periwound
                AssessmentRow(
                    title: "Periwound Skin",
                    value: report.periwoundStatus.status.capitalized,
                    detail: report.periwoundStatus.description,
                    concernLevel: report.periwoundStatus.status == "macerated" ? .moderate : .low
                )

                if report.deepSpacesPresent {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Deep Spaces Detected")
                                .font(.subheadline.weight(.semibold))
                        }
                        if !report.deepSpaceTypes.isEmpty {
                            Text("Types: \(report.deepSpaceTypes.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Perfusion (if assessed)
                if let perfusion = report.perfusionStatus {
                    Divider()
                    AssessmentRow(
                        title: "Perfusion",
                        value: perfusion.abi == "ge0_8" ? "Adequate" :
                               perfusion.abi == "lt0_5" ? "Critical" : "Reduced",
                        detail: perfusion.summary,
                        concernLevel: perfusion.abi == "lt0_5" ? .critical :
                                     perfusion.abi == "p0_5to0_79" ? .high : .low
                    )
                }

                // Bone involvement
                if let bone = report.boneInvolvement {
                    Divider()
                    AssessmentRow(
                        title: "Bone Involvement",
                        value: bone.requiresImaging ? "Suspected" : "None",
                        detail: bone.summary,
                        concernLevel: bone.requiresImaging ? .critical : .low
                    )
                }
            }
        }
    }

    private func treatmentGoalsSection(_ report: AIReport) -> some View {
        SectionCard(title: "Treatment Goals", icon: "target") {
            VStack(spacing: 12) {
                ForEach(report.treatmentGoals) { goal in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Text("\(goal.priority)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.goal)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text(goal.rationale)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
    }

    private func clinicalStrategiesSection(_ report: AIReport) -> some View {
        SectionCard(title: "Clinical Strategies", icon: "list.clipboard") {
            VStack(spacing: 12) {
                ForEach(report.clinicalStrategies) { strategy in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: strategy.category.icon)
                            .font(.title3)
                            .foregroundColor(strategy.category.color)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(strategy.strategy)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                if !strategy.priority.badge.isEmpty {
                                    Text(strategy.priority.badge)
                                        .font(.caption)
                                }
                            }

                            Text(strategy.rationale)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
    }

    private func patientConsiderationsSection(_ report: AIReport) -> some View {
        SectionCard(title: "Patient-Specific Considerations", icon: "person.fill") {
            VStack(spacing: 12) {
                ForEach(report.patientConsiderations) { consideration in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(consideration.factor)
                                .font(.subheadline.weight(.semibold))
                        }

                        Text("Impact: \(consideration.impact)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Action: \(consideration.action)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.08))
                    )
                }
            }
        }
    }

    private func barriersToHealingSection(_ report: AIReport) -> some View {
        SectionCard(title: "Barriers to Healing", icon: "exclamationmark.shield") {
            VStack(spacing: 12) {
                ForEach(report.barriersToHealing) { barrier in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(barrier.severity.color)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(barrier.barrier)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)

                            Text("Mitigation: \(barrier.mitigation)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(barrier.severity.color.opacity(0.1))
                    )
                }
            }
        }
    }

    private func followUpPlanSection(_ report: AIReport) -> some View {
        SectionCard(title: "Monitoring & Follow-Up", icon: "calendar.badge.clock") {
            VStack(alignment: .leading, spacing: 16) {
                // Review schedule
                VStack(alignment: .leading, spacing: 8) {
                    Label("Review Schedule", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)

                    InfoRow(label: "Initial Review", value: report.followUpPlan.initialReview)
                    InfoRow(label: "Ongoing", value: report.followUpPlan.ongoingFrequency)
                }

                Divider()

                // Progress indicators
                VStack(alignment: .leading, spacing: 8) {
                    Label("Signs of Progress", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)

                    ForEach(report.followUpPlan.progressIndicators, id: \.self) { indicator in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.green)
                            Text(indicator)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // Escalation criteria
                VStack(alignment: .leading, spacing: 8) {
                    Label("Escalate If", systemImage: "exclamationmark.triangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.red)

                    ForEach(report.followUpPlan.escalationCriteria, id: \.self) { criterion in
                        HStack(alignment: .top, spacing: 8) {
                            Text("⚠️")
                            Text(criterion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadReport() {
        loading = true
        let payload = QuestionnairePayload.from(questionnaireData)
        self.payload = payload
        self.report = RulesEngine.analyze(payload, context: context)
        self.loading = false
    }

    private func mapEtiologyLabel(_ etiology: String) -> String {
        switch etiology {
        case "venous": return "Venous"
        case "arterial": return "Arterial"
        case "diabeticFoot": return "Diabetic Foot"
        case "pressure": return "Pressure"
        case "mixed": return "Mixed"
        default: return "Unknown"
        }
    }
}

// MARK: - UI Components

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.primary)

            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
    }
}

private struct AssessmentRow: View {
    let title: String
    let value: String
    let detail: String
    let concernLevel: ConcernLevel
    var badges: [String]? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(concernLevel.color)
                        .frame(width: 8, height: 8)
                    Text(value)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(concernLevel.color)
                }
            }

            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}

// Simple flow layout for tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
                size.width = max(size.width, currentX)
                size.height = currentY + lineHeight
            }

            self.size = size
            self.positions = positions
        }
    }
}
