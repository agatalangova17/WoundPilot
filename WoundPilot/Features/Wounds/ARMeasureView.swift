//
//  ARMeasureView.swift
//  WoundPilot
//
//  4-Tap Length/Width AR ruler using ARKit + RealityKit (no LiDAR required).
//

import SwiftUI
import UIKit
import ARKit
import RealityKit
import simd

// MARK: - Result type passed back to the presenting view
struct ARMeasurementResult {
    let lengthM: Float
    let width1M: Float?
    let width2M: Float?
    let widthAvgM: Float?
    let areaRectM2: Float?
    let areaEllM2: Float?
}

// MARK: - Public SwiftUI wrapper

struct ARMeasureView: View {
    // Callback to return the final measurement and dismiss
    var onComplete: ((ARMeasurementResult) -> Void)? = nil

    // Results exposed by the coordinator (live HUD state)
    @State private var tapStage: Int = 0           // 0...4
    @State private var lengthM: Float? = nil       // L
    @State private var width1M: Float? = nil       // W1 (after 3rd tap)
    @State private var width2M: Float? = nil       // W2 (after 4th tap)
    @State private var widthAvgM: Float? = nil     // (W1+W2)/2
    @State private var areaRectM2: Float? = nil    // L * Wavg
    @State private var areaEllM2: Float? = nil     // π/4 * L * Wavg

    @State private var canUndo = false
    @State private var canReset = false
    @Environment(\.dismiss) private var dismiss

    // Save is enabled once we have L and at least one width (3rd tap)
    private var canSave: Bool {
        lengthM != nil && (width1M != nil || width2M != nil)
    }

    var body: some View {
        ZStack {
            ARViewContainer(
                tapStage: $tapStage,
                lengthM: $lengthM,
                width1M: $width1M,
                width2M: $width2M,
                widthAvgM: $widthAvgM,
                areaRectM2: $areaRectM2,
                areaEllM2: $areaEllM2,
                canUndo: $canUndo,
                canReset: $canReset
            )

            // HUD
            VStack(spacing: 10) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    Spacer()
                }
                .padding([.top, .horizontal])

                // Title + Metrics
                VStack(spacing: 8) {
                    Text("AR L/W Measure (4-tap)")
                        .font(.headline)

                    // Primary metrics
                    if let L = lengthM {
                        let shownW = widthAvgM ?? width1M
                        HStack(spacing: 12) {
                            Text("L: \(prettyCM(L))")
                            if let W = shownW {
                                Text("W: \(prettyCM(W))")
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                    }

                    // Secondary metrics (areas + W1/W2)
                    if lengthM != nil {
                        VStack(spacing: 4) {
                            if let w1 = width1M {
                                if let w2 = width2M, let wavg = widthAvgM {
                                    Text("W₁: \(prettyCM(w1)) • W₂: \(prettyCM(w2)) • W̄: \(prettyCM(wavg))")
                                } else {
                                    Text("W₁: \(prettyCM(w1))")
                                }
                            }
                            if let ar = areaRectM2, let ae = areaEllM2 {
                                Text("Area — Rect: \(prettyCM2(ar)) • Ellipse: \(prettyCM2(ae))")
                            }
                        }
                        .font(.footnote)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                    }

                    // Step instructions
                    Text(instructionText(for: tapStage))
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }

                Spacer()

                // Tip
                Text("Tip: Hold the phone roughly head-on to the wound for best accuracy.")
                    .font(.caption2)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                // Controls
                HStack(spacing: 12) {
                    Button {
                        if let L = lengthM {
                            let result = ARMeasurementResult(
                                lengthM: L,
                                width1M: width1M,
                                width2M: width2M,
                                widthAvgM: widthAvgM,
                                areaRectM2: areaRectM2,
                                areaEllM2: areaEllM2
                            )
                            onComplete?(result)
                            dismiss()
                        }
                    } label: {
                        Label("Save", systemImage: "checkmark.circle").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(!canSave)

                    Button {
                        NotificationCenter.default.post(name: .arMeasureUndo, object: nil)
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(!canUndo)

                    Button {
                        NotificationCenter.default.post(name: .arMeasureReset, object: nil)
                    } label: {
                        Label("Reset", systemImage: "trash").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!canReset)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - HUD helpers

    private func instructionText(for stage: Int) -> String {
        switch stage {
        case 0: return "Tap a wound edge to start (Length)."
        case 1: return "Tap the opposite edge to set the Length."
        case 2: return "Tap one wound edge along the perpendicular guide to set Width 1."
        case 3: return "Tap the opposite edge to refine Width 2 (optional)."
        default: return "Measurement complete. Save, Undo, or Reset."
        }
    }

    private func prettyCM(_ meters: Float) -> String {
        let cm = meters * 100
        return String(format: "%.1f cm", cm)
    }

    private func prettyCM2(_ m2: Float) -> String {
        let cm2 = m2 * 10_000 // m² -> cm²
        return String(format: "%.1f cm²", cm2)
    }
}

// MARK: - UIViewRepresentable bridge

private struct ARViewContainer: UIViewRepresentable {
    @Binding var tapStage: Int
    @Binding var lengthM: Float?
    @Binding var width1M: Float?
    @Binding var width2M: Float?
    @Binding var widthAvgM: Float?
    @Binding var areaRectM2: Float?
    @Binding var areaEllM2: Float?
    @Binding var canUndo: Bool
    @Binding var canReset: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth) // LiDAR/Depth if available
        }
        arView.session.delegate = context.coordinator
        arView.session.run(config, options: [])

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(context.coordinator,
                                               selector: #selector(Coordinator.handleUndo),
                                               name: .arMeasureUndo, object: nil)
        NotificationCenter.default.addObserver(context.coordinator,
                                               selector: #selector(Coordinator.handleReset),
                                               name: .arMeasureReset, object: nil)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.bindings = Coordinator.Bindings(
            tapStage: $tapStage,
            lengthM: $lengthM,
            width1M: $width1M,
            width2M: $width2M,
            widthAvgM: $widthAvgM,
            areaRectM2: $areaRectM2,
            areaEllM2: $areaEllM2,
            canUndo: $canUndo,
            canReset: $canReset
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, ARSessionDelegate {
        struct Bindings {
            var tapStage: Binding<Int>
            var lengthM: Binding<Float?>
            var width1M: Binding<Float?>
            var width2M: Binding<Float?>
            var widthAvgM: Binding<Float?>
            var areaRectM2: Binding<Float?>
            var areaEllM2: Binding<Float?>
            var canUndo: Binding<Bool>
            var canReset: Binding<Bool>
        }

        weak var arView: ARView!
        var bindings: Bindings!

        // State (world points)
        private var p1: SIMD3<Float>? = nil
        private var p2: SIMD3<Float>? = nil
        private var p3: SIMD3<Float>? = nil
        private var p4: SIMD3<Float>? = nil

        // Visual anchors
        private var dotAnchors: [AnchorEntity] = []
        private var lengthAnchor: AnchorEntity? = nil
        private var guideAnchor: AnchorEntity? = nil
        private var width1Anchor: AnchorEntity? = nil
        private var width2Anchor: AnchorEntity? = nil

        // Look
        private let lineThickness: Float = 0.004 // 4 mm
        private let dotRadius: Float = 0.006     // 6 mm

        // MARK: Input

        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            guard gr.state == .ended, let arView else { return }
            if bindings.tapStage.wrappedValue >= 4 { return } // finished; ask to Reset

            let pt = gr.location(in: arView)

            // Prefer real planes; fall back gracefully
            var result: ARRaycastResult?
            if let q = arView.makeRaycastQuery(from: pt, allowing: .existingPlaneGeometry, alignment: .any),
               let r = arView.session.raycast(q).first { result = r }
            else if let q = arView.makeRaycastQuery(from: pt, allowing: .existingPlaneInfinite, alignment: .any),
                    let r = arView.session.raycast(q).first { result = r }
            else if let q = arView.makeRaycastQuery(from: pt, allowing: .estimatedPlane, alignment: .any),
                    let r = arView.session.raycast(q).first { result = r }

            guard let hit = result else { return }

            let worldPos = SIMD3<Float>(hit.worldTransform.columns.3.x,
                                        hit.worldTransform.columns.3.y,
                                        hit.worldTransform.columns.3.z)
            placeDot(at: worldPos)

            switch bindings.tapStage.wrappedValue {
            case 0:
                p1 = worldPos
                bindings.tapStage.wrappedValue = 1

            case 1:
                p2 = worldPos
                drawLengthAndGuide()
                computeAfterTwo()
                bindings.tapStage.wrappedValue = 2

            case 2:
                p3 = worldPos
                drawWidth1()
                computeAfterThree()
                bindings.tapStage.wrappedValue = 3

            case 3:
                p4 = worldPos
                drawWidth2()
                computeAfterFour()
                bindings.tapStage.wrappedValue = 4

            default:
                break
            }

            updateButtons()
        }

        // MARK: Undo/Reset

        @objc func handleUndo() {
            guard let arView else { return }
            switch bindings.tapStage.wrappedValue {
            case 0:
                return

            case 1:
                // Remove p1 dot
                if let last = dotAnchors.popLast() { arView.scene.removeAnchor(last) }
                p1 = nil
                bindings.tapStage.wrappedValue = 0

            case 2:
                // Remove p2 dot, length + guide
                if let last = dotAnchors.popLast() { arView.scene.removeAnchor(last) }
                p2 = nil
                removeAnchor(&lengthAnchor)
                removeAnchor(&guideAnchor)
                clearAfterTwo()
                bindings.tapStage.wrappedValue = 1

            case 3:
                // Remove p3 dot, width1
                if let last = dotAnchors.popLast() { arView.scene.removeAnchor(last) }
                p3 = nil
                removeAnchor(&width1Anchor)
                computeAfterTwo()                 // back to "after two" state
                bindings.tapStage.wrappedValue = 2

            case 4:
                // Remove p4 dot, width2
                if let last = dotAnchors.popLast() { arView.scene.removeAnchor(last) }
                p4 = nil
                removeAnchor(&width2Anchor)
                bindings.width2M.wrappedValue = nil
                recomputeAvgAndAreas()
                bindings.tapStage.wrappedValue = 3

            default:
                break
            }
            updateButtons()
        }

        @objc func handleReset() {
            guard let arView else { return }
            dotAnchors.forEach { arView.scene.removeAnchor($0) }
            dotAnchors.removeAll()
            removeAnchor(&lengthAnchor)
            removeAnchor(&guideAnchor)
            removeAnchor(&width1Anchor)
            removeAnchor(&width2Anchor)

            p1 = nil; p2 = nil; p3 = nil; p4 = nil

            // Clear bindings
            bindings.tapStage.wrappedValue = 0
            bindings.lengthM.wrappedValue = nil
            bindings.width1M.wrappedValue = nil
            bindings.width2M.wrappedValue = nil
            bindings.widthAvgM.wrappedValue = nil
            bindings.areaRectM2.wrappedValue = nil
            bindings.areaEllM2.wrappedValue = nil

            updateButtons()
        }

        private func updateButtons() {
            let stage = bindings.tapStage.wrappedValue
            bindings.canUndo.wrappedValue = stage > 0
            bindings.canReset.wrappedValue = stage > 0
        }

        // MARK: Rendering helpers

        private func simpleColor(_ ui: UIColor, alpha: CGFloat = 1.0) -> UIColor {
            ui.withAlphaComponent(alpha)
        }

        private func placeDot(at world: SIMD3<Float>) {
            guard let arView else { return }
            let mesh = MeshResource.generateSphere(radius: dotRadius)
            let material = SimpleMaterial(color: simpleColor(.systemTeal), isMetallic: false)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            let anchor = AnchorEntity(world: world)
            entity.position = SIMD3<Float>(repeating: 0)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            dotAnchors.append(anchor)
        }

        private func removeAnchor(_ anchorRef: inout AnchorEntity?) {
            guard let arView, let a = anchorRef else { anchorRef = nil; return }
            arView.scene.removeAnchor(a)
            anchorRef = nil
        }

        /// Generate a slim 3D box (line) from `a` to `b`
        private func makeLine(from a: SIMD3<Float>,
                              to b: SIMD3<Float>,
                              color: UIColor,
                              alpha: CGFloat) -> ModelEntity {
            let v = b - a
            let length = simd_length(v)
            let dir = simd_normalize(v)

            let box = MeshResource.generateBox(size: SIMD3<Float>(lineThickness, lineThickness, length),
                                               cornerRadius: lineThickness / 2)
            let material = SimpleMaterial(color: simpleColor(color, alpha: alpha), isMetallic: false)
            let entity = ModelEntity(mesh: box, materials: [material])

            // Mesh initially along +Z -> rotate to dir
            let zAxis = SIMD3<Float>(0, 0, 1)
            let rot = simd_quatf(from: zAxis, to: dir)
            entity.transform.rotation = rot
            return entity
        }

        // MARK: Computation utilities

        private func dist(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
            simd_length(b - a)
        }

        private func computeAfterTwo() {
            guard let p1, let p2 else { return }
            let L = dist(p1, p2)
            bindings.lengthM.wrappedValue = L
            // clear downstream
            bindings.width1M.wrappedValue = nil
            bindings.width2M.wrappedValue = nil
            bindings.widthAvgM.wrappedValue = nil
            bindings.areaRectM2.wrappedValue = nil
            bindings.areaEllM2.wrappedValue = nil
        }

        private func clearAfterTwo() {
            bindings.lengthM.wrappedValue = nil
            bindings.width1M.wrappedValue = nil
            bindings.width2M.wrappedValue = nil
            bindings.widthAvgM.wrappedValue = nil
            bindings.areaRectM2.wrappedValue = nil
            bindings.areaEllM2.wrappedValue = nil
        }

        private func computeAfterThree() {
            guard let p1, let p2, let p3 else { return }
            let v = p2 - p1
            let L = simd_length(v)
            let dir = simd_normalize(v)
            let mid = (p1 + p2) / 2

            let d = p3 - mid
            let along = simd_dot(d, dir) * dir
            let perp = d - along
            let W1 = 2 * simd_length(perp)

            bindings.lengthM.wrappedValue = L
            bindings.width1M.wrappedValue = W1
            bindings.width2M.wrappedValue = nil
            bindings.widthAvgM.wrappedValue = W1
            // Areas using current best width
            bindings.areaRectM2.wrappedValue = L * W1
            bindings.areaEllM2.wrappedValue = 0.25 * .pi * L * W1
        }

        private func computeAfterFour() {
            guard let p1, let p2, let p3, let p4 else { return }
            let v = p2 - p1
            let L = simd_length(v)
            let dir = simd_normalize(v)
            let mid = (p1 + p2) / 2

            // W1 at midpoint using p3
            let d1 = p3 - mid
            let perp1 = d1 - simd_dot(d1, dir) * dir
            let W1 = 2 * simd_length(perp1)

            // W2 at midpoint using p4
            let d2 = p4 - mid
            let perp2 = d2 - simd_dot(d2, dir) * dir
            let W2 = 2 * simd_length(perp2)

            let Wavg = 0.5 * (W1 + W2)

            bindings.lengthM.wrappedValue = L
            bindings.width1M.wrappedValue = W1
            bindings.width2M.wrappedValue = W2
            bindings.widthAvgM.wrappedValue = Wavg
            bindings.areaRectM2.wrappedValue = L * Wavg
            bindings.areaEllM2.wrappedValue = 0.25 * .pi * L * Wavg
        }

        private func recomputeAvgAndAreas() {
            guard let L = bindings.lengthM.wrappedValue else {
                bindings.widthAvgM.wrappedValue = bindings.width1M.wrappedValue
                bindings.areaRectM2.wrappedValue = nil
                bindings.areaEllM2.wrappedValue = nil
                return
            }
            let W: Float
            if let w2 = bindings.width2M.wrappedValue, let w1 = bindings.width1M.wrappedValue {
                W = 0.5 * (w1 + w2)
            } else if let w1 = bindings.width1M.wrappedValue {
                W = w1
            } else {
                bindings.widthAvgM.wrappedValue = nil
                bindings.areaRectM2.wrappedValue = nil
                bindings.areaEllM2.wrappedValue = nil
                return
            }
            bindings.widthAvgM.wrappedValue = W
            bindings.areaRectM2.wrappedValue = L * W
            bindings.areaEllM2.wrappedValue = 0.25 * .pi * L * W
        }

        // MARK: Drawing helpers (length, guide, widths)

        private func drawLengthAndGuide() {
            guard let arView, let p1, let p2 else { return }

            // Remove old if any
            removeAnchor(&lengthAnchor)
            removeAnchor(&guideAnchor)

            // Length line
            let mid = (p1 + p2) / 2
            let lengthEntity = makeLine(from: p1, to: p2, color: .systemBlue, alpha: 0.95)
            let lengthA = AnchorEntity(world: mid)
            lengthEntity.position = SIMD3<Float>(repeating: 0)
            lengthA.addChild(lengthEntity)
            arView.scene.addAnchor(lengthA)
            lengthAnchor = lengthA

            // Perpendicular guide at midpoint (visual aid)
            let dir = simd_normalize(p2 - p1)
            let up = SIMD3<Float>(0, 1, 0)
            var ref = up
            if abs(simd_dot(dir, up)) > 0.95 { ref = SIMD3<Float>(1, 0, 0) } // fallback if nearly parallel
            var perpDir = simd_normalize(simd_cross(dir, ref))
            if simd_length(perpDir) < 1e-4 { perpDir = SIMD3<Float>(0, 0, 1) } // last resort

            // Guide length: ~60% of L (clamped)
            let L = simd_length(p2 - p1)
            let guideHalf: Float = max(0.01, 0.3 * L) // each side
            let g1 = mid - perpDir * guideHalf
            let g2 = mid + perpDir * guideHalf

            let guideEntity = makeLine(from: g1, to: g2, color: .systemGray, alpha: 0.6)
            let guideA = AnchorEntity(world: mid)
            guideEntity.position = SIMD3<Float>(repeating: 0)
            guideA.addChild(guideEntity)
            arView.scene.addAnchor(guideA)
            guideAnchor = guideA
        }

        private func drawWidth1() {
            guard let arView, let p1, let p2, let p3 else { return }
            removeAnchor(&width1Anchor)

            // Mirror p3 across the long axis through midpoint to draw a symmetric width segment
            let mid = (p1 + p2) / 2
            let dir = simd_normalize(p2 - p1)
            let mirrored = mirror(point: p3, axisPoint: mid, axisDir: dir)

            let widthEntity = makeLine(from: p3, to: mirrored, color: .systemGreen, alpha: 0.95)
            let wA = AnchorEntity(world: (p3 + mirrored) / 2)
            widthEntity.position = SIMD3<Float>(repeating: 0)
            wA.addChild(widthEntity)
            arView.scene.addAnchor(wA)
            width1Anchor = wA
        }

        private func drawWidth2() {
            guard let arView, let p1, let p2, let p4 else { return }
            removeAnchor(&width2Anchor)

            let mid = (p1 + p2) / 2
            let dir = simd_normalize(p2 - p1)
            let mirrored = mirror(point: p4, axisPoint: mid, axisDir: dir)

            let widthEntity = makeLine(from: p4, to: mirrored, color: .systemGreen, alpha: 0.95)
            let wA = AnchorEntity(world: (p4 + mirrored) / 2)
            widthEntity.position = SIMD3<Float>(repeating: 0)
            wA.addChild(widthEntity)
            arView.scene.addAnchor(wA)
            width2Anchor = wA
        }

        /// Mirror a 3D point across a line (axis through `axisPoint` with direction `axisDir`)
        private func mirror(point r: SIMD3<Float>, axisPoint o: SIMD3<Float>, axisDir d: SIMD3<Float>) -> SIMD3<Float> {
            let dir = simd_normalize(d)
            let delta = r - o
            let along = simd_dot(delta, dir) * dir
            let perp  = delta - along
            let mirrored = o + along - perp
            return mirrored
        }
    }
}

// MARK: - Notification helpers

private extension Notification.Name {
    static let arMeasureUndo  = Notification.Name("ARMeasureUndo")
    static let arMeasureReset = Notification.Name("ARMeasureReset")
}
