
import Foundation
import UIKit
import simd
// MARK: - Unified result returned by AR or Manual flow

struct WoundMeasurementResult {
    let lengthCm: Float
    let widthCm: Float
    let areaCm2: Float?
    let capturedImage: UIImage?
    let method: MeasurementMethod
    let confidence: MeasurementConfidence?
    let timestamp: Date
    
    enum MeasurementMethod: String, Codable {
        case arLidar = "AR + LiDAR"
        case manual = "Manual Entry"
    }
    
    struct MeasurementConfidence {
        let score: Float          // 0.0 - 1.0
        let label: String         // "Excellent" / "Good" / "Fair" / "Poor"
        let trackingQuality: String
        let distanceFromCamera: Float?  // meters
        let surfacePlanarity: Float?    // how flat (lower = better)
        
        static func calculate(
            trackingState: String,
            trackingIsGood: Bool,
            distance: Float?,
            planarity: Float?
        ) -> MeasurementConfidence {
            var score: Float = 0.5
            var factors: [String] = []
            
            // Factor 1: Tracking quality (40% weight)
            if trackingIsGood {
                score += 0.4
            } else {
                factors.append("tracking limited")
            }
            
            // Factor 2: Distance (30% weight)
            if let dist = distance {
                if dist >= 0.15 && dist <= 0.35 {
                    score += 0.3
                } else if dist >= 0.10 && dist < 0.15 {
                    score += 0.15
                    factors.append("slightly too close")
                } else if dist > 0.35 && dist <= 0.50 {
                    score += 0.15
                    factors.append("slightly too far")
                } else {
                    factors.append(dist < 0.10 ? "too close" : "too far")
                }
            }
            
            // Factor 3: Surface flatness (30% weight)
            if let plan = planarity {
                if plan < 0.01 {
                    score += 0.3
                } else if plan < 0.02 {
                    score += 0.2
                } else if plan < 0.03 {
                    score += 0.1
                    factors.append("surface slightly curved")
                } else {
                    factors.append("surface curved")
                }
            }
            
            // Generate label
            let label: String
            if score >= 0.9 {
                label = "Excellent"
            } else if score >= 0.75 {
                label = "Good"
            } else if score >= 0.55 {
                label = "Fair"
            } else {
                label = "Poor"
            }
            
            let finalLabel = factors.isEmpty ? label : "\(label) (\(factors.joined(separator: ", ")))"
            
            return MeasurementConfidence(
                score: score,
                label: finalLabel,
                trackingQuality: trackingState,
                distanceFromCamera: distance,
                surfacePlanarity: planarity
            )
        }
    }
}

// MARK: - Internal AR state (cleaner than optionals everywhere)

struct ARMeasurementState {
    var points: [SIMD3<Float>] = []
    var stage: Stage = .waitingForFirst
    
    enum Stage {
        case waitingForFirst
        case waitingForSecond
        case waitingForThird
        case waitingForFourth
        case complete
        
        var instruction: String {
            switch self {
            case .waitingForFirst:  return "Tap first edge of the wound (longest axis)"
            case .waitingForSecond: return "Tap opposite edge to set length"
            case .waitingForThird:  return "Tap perpendicular edge to set width"
            case .waitingForFourth: return "Tap opposite edge to refine (optional)"
            case .complete:         return "Measurement complete! Review and save."
            }
        }
        
        var canUndo: Bool { self != .waitingForFirst }
        var canSave: Bool {
            self == .waitingForFourth || self == .complete
        }
    }
    
    // Computed measurements
    var lengthM: Float? {
        guard points.count >= 2 else { return nil }
        return simd_distance(points[0], points[1])
    }
    
    var widthM: Float? {
        guard points.count >= 3,
              let p1 = points[safe: 0],
              let p2 = points[safe: 1],
              let p3 = points[safe: 2] else { return nil }
        
        let mid = (p1 + p2) / 2
        let dir = simd_normalize(p2 - p1)
        let perpDist = perpendicularDistance(from: p3, to: mid, along: dir)
        return perpDist * 2
    }
    
    var averageWidthM: Float? {
        guard let w1 = widthM else { return nil }
        
        if let p4 = points[safe: 3],
           let p1 = points[safe: 0],
           let p2 = points[safe: 1] {
            let mid = (p1 + p2) / 2
            let dir = simd_normalize(p2 - p1)
            let perpDist2 = perpendicularDistance(from: p4, to: mid, along: dir)
            let w2 = perpDist2 * 2
            return (w1 + w2) / 2
        }
        
        return w1
    }
    
    var areaM2: Float? {
        guard let L = lengthM, let W = averageWidthM else { return nil }
        return L * W * 0.785 // Ellipse approximation
    }
    
    // Helper: perpendicular distance from point to line
    private func perpendicularDistance(
        from point: SIMD3<Float>,
        to linePoint: SIMD3<Float>,
        along lineDir: SIMD3<Float>
    ) -> Float {
        let delta = point - linePoint
        let alongComponent = simd_dot(delta, lineDir) * lineDir
        let perpComponent = delta - alongComponent
        return simd_length(perpComponent)
    }
    
    // Surface planarity (how flat are the points?)
    var surfacePlanarity: Float? {
        guard points.count >= 3 else { return nil }
        
        // Simple version: variance in one dimension
        let zValues = points.map { $0.z }
        let avgZ = zValues.reduce(0, +) / Float(zValues.count)
        let variance = zValues.map { pow($0 - avgZ, 2) }.reduce(0, +) / Float(zValues.count)
        return sqrt(variance)
    }
    
    // Distance from camera (average of all points)
    func averageDistanceFromCamera(_ cameraPos: SIMD3<Float>) -> Float? {
        guard !points.isEmpty else { return nil }
        let distances = points.map { simd_distance($0, cameraPos) }
        return distances.reduce(0, +) / Float(distances.count)
    }
    
    mutating func addPoint(_ point: SIMD3<Float>) {
        points.append(point)
        stage = Stage(rawStage: points.count)
    }
    
    mutating func removeLastPoint() {
        guard !points.isEmpty else { return }
        points.removeLast()
        stage = Stage(rawStage: points.count)
    }
    
    mutating func reset() {
        points.removeAll()
        stage = .waitingForFirst
    }
}

extension ARMeasurementState.Stage {
    init(rawStage count: Int) {
        switch count {
        case 0: self = .waitingForFirst
        case 1: self = .waitingForSecond
        case 2: self = .waitingForThird
        case 3: self = .waitingForFourth
        default: self = .complete
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
