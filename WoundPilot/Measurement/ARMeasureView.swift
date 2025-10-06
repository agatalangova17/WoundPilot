//  ARMeasureView.swift
//  WoundPilot
//
//  Enhanced AR measurement with:
//  • Photo capture on save
//  • Confidence scoring
//  • Distance feedback
//  • Manual fallback option

import SwiftUI
import UIKit
import ARKit
import RealityKit

struct ARMeasureView: View {
    var onComplete: ((WoundMeasurementResult) -> Void)?
    var onSwitchToManual: (() -> Void)?
    
    @State private var measurementState = ARMeasurementState()
    @State private var trackingLabel = LocalizedStrings.arInitializing
    @State private var trackingIsGood = false
    @State private var distanceLabel = ""
    @State private var confidenceScore: WoundMeasurementResult.MeasurementConfidence?
    @State private var capturedPhoto: UIImage?
    @State private var showInstructions = true
    
    @Environment(\.dismiss) private var dismiss
    
    private var lengthCm: Float? {
        measurementState.lengthM.map { $0 * 100 }
    }
    
    private var widthCm: Float? {
        measurementState.averageWidthM.map { $0 * 100 }
    }
    
    private var areaCm2: Float? {
        measurementState.areaM2.map { $0 * 10_000 }
    }
    
    var body: some View {
        ZStack {
            // AR measurement view
            ZStack {
                ARViewContainer(
                    measurementState: $measurementState,
                    trackingLabel: $trackingLabel,
                    trackingIsGood: $trackingIsGood,
                    distanceLabel: $distanceLabel,
                    confidenceScore: $confidenceScore,
                    capturedPhoto: $capturedPhoto
                )
                
                VStack(spacing: 0) {
                    topBar
                        .padding()
                        .padding(.top, 40)
                        .background(.ultraThinMaterial)
                    
                    if let length = lengthCm {
                        measurementsDisplay(length: length)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    instructionsBanner
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    controlButtons
                        .padding()
                        .background(.ultraThinMaterial)
                }
            }
            
            // Initial instructions overlay
            if showInstructions {
                initialInstructionsOverlay
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
    }
    
    // MARK: - Initial Instructions Overlay
    
    private var initialInstructionsOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("AR Measurement Tips")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 16) {
                    instructionRow(icon: "ruler", text: "Hold phone 20-30cm from wound surface")
                    instructionRow(icon: "hand.raised.fill", text: "Keep phone steady while tapping")
                    instructionRow(icon: "light.max", text: "Ensure good lighting on the wound")
                    instructionRow(icon: "hand.point.up.left.fill", text: "Tap the longest edges first, then width")
                }
                .padding(.horizontal, 24)
                
                Button {
                    showInstructions = false
                } label: {
                    Text("Start Measurement")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding()
        }
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    // MARK: - UI Components
    
    private var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: trackingIsGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .imageScale(.small)
                    .foregroundColor(trackingIsGood ? .green : .orange)
                Text(trackingLabel)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                (trackingIsGood ? Color.green : Color.orange).opacity(0.15),
                in: Capsule()
            )
            
            Spacer()
            
            if !distanceLabel.isEmpty {
                Text(distanceLabel)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15), in: Capsule())
            }
        }
    }
    
    private func measurementsDisplay(length: Float) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                measurementChip(label: LocalizedStrings.measureAbbrL, value: length, unit: LocalizedStrings.cmUnit)
                if let width = widthCm {
                    measurementChip(label: LocalizedStrings.measureAbbrW, value: width, unit: LocalizedStrings.cmUnit)
                }
                if let area = areaCm2 {
                    measurementChip(label: LocalizedStrings.measureLabelArea, value: area, unit: LocalizedStrings.cm2Unit)
                }
            }
            
            if let conf = confidenceScore {
                HStack(spacing: 6) {
                    Image(systemName: confidenceIcon(conf.score))
                        .foregroundColor(confidenceColor(conf.score))
                    Text("\(LocalizedStrings.qualityLabel) \(conf.label)")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(confidenceColor(conf.score).opacity(0.15), in: Capsule())
            }
        }
    }
    
    private func measurementChip(label: String, value: Float, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(String(format: "%.1f", value)) \(unit)")
                .font(.callout.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    private var instructionsBanner: some View {
        VStack(spacing: 8) {
            if !distanceLabel.isEmpty {
                let isGood = distanceLabel.contains(LocalizedStrings.distanceSuffixOK)
                
                HStack(spacing: 8) {
                    Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title3)
                    Text(distanceLabel)
                        .font(.headline.weight(.bold))
                }
                .foregroundColor(isGood ? .green : .orange)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((isGood ? Color.green : Color.orange).opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isGood ? Color.green : Color.orange, lineWidth: 2)
                )
            }
            
            Text(measurementState.stage.instruction)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 12) {
            Button {
                onSwitchToManual?()
            } label: {
                Label(LocalizedStrings.manualActionTitle, systemImage: "pencil")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            
            Button {
                NotificationCenter.default.post(name: .arMeasureUndo, object: nil)
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.footnote.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .disabled(!measurementState.stage.canUndo)
            
            Button {
                NotificationCenter.default.post(name: .arMeasureReset, object: nil)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.footnote.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(!measurementState.stage.canUndo)
            
            Button {
                saveAndComplete()
            } label: {
                Label(LocalizedStrings.saveAction, systemImage: "checkmark")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!measurementState.stage.canSave)
        }
    }
    
    // MARK: - Actions
    
    private func saveAndComplete() {
        guard let length = lengthCm,
              let width = widthCm else { return }
        
        NotificationCenter.default.post(name: .arCapturePhoto, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let result = WoundMeasurementResult(
                lengthCm: length,
                widthCm: width,
                areaCm2: areaCm2,
                capturedImage: capturedPhoto,
                method: .arLidar,
                confidence: confidenceScore,
                timestamp: Date()
            )
            onComplete?(result)
        }
    }
    
    private func confidenceIcon(_ score: Float) -> String {
        if score >= 0.9 { return "star.fill" }
        if score >= 0.75 { return "checkmark.circle.fill" }
        if score >= 0.55 { return "exclamationmark.circle.fill" }
        return "xmark.circle.fill"
    }
    
    private func confidenceColor(_ score: Float) -> Color {
        if score >= 0.9 { return .green }
        if score >= 0.75 { return .blue }
        if score >= 0.55 { return .orange }
        return .red
    }
}

// MARK: - ARViewContainer (UIKit Bridge)

private struct ARViewContainer: UIViewRepresentable {
    @Binding var measurementState: ARMeasurementState
    @Binding var trackingLabel: String
    @Binding var trackingIsGood: Bool
    @Binding var distanceLabel: String
    @Binding var confidenceScore: WoundMeasurementResult.MeasurementConfidence?
    @Binding var capturedPhoto: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        context.coordinator.setupBindings(
            measurementState: $measurementState,
            trackingLabel: $trackingLabel,
            trackingIsGood: $trackingIsGood,
            distanceLabel: $distanceLabel,
            confidenceScore: $confidenceScore,
            capturedPhoto: $capturedPhoto
        )
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleUndo),
            name: .arMeasureUndo,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleReset),
            name: .arMeasureReset,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.capturePhoto),
            name: .arCapturePhoto,
            object: nil
        )
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        NotificationCenter.default.removeObserver(coordinator)
        coordinator.cleanup()
    }
    
    final class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        
        private var measurementState: Binding<ARMeasurementState>!
        private var trackingLabel: Binding<String>!
        private var trackingIsGood: Binding<Bool>!
        private var distanceLabel: Binding<String>!
        private var confidenceScore: Binding<WoundMeasurementResult.MeasurementConfidence?>!
        private var capturedPhoto: Binding<UIImage?>!
        
        private var visualAnchors: [AnchorEntity] = []
        private var currentCameraPosition: SIMD3<Float>?
        
        func setupBindings(
            measurementState: Binding<ARMeasurementState>,
            trackingLabel: Binding<String>,
            trackingIsGood: Binding<Bool>,
            distanceLabel: Binding<String>,
            confidenceScore: Binding<WoundMeasurementResult.MeasurementConfidence?>,
            capturedPhoto: Binding<UIImage?>
        ) {
            self.measurementState = measurementState
            self.trackingLabel = trackingLabel
            self.trackingIsGood = trackingIsGood
            self.distanceLabel = distanceLabel
            self.confidenceScore = confidenceScore
            self.capturedPhoto = capturedPhoto
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let arView = arView,
                  measurementState.wrappedValue.stage != .complete else { return }
            
            let point = gesture.location(in: arView)
            
            guard let raycastResult = performRaycast(arView: arView, point: point),
                  let worldPos = extractWorldPosition(raycastResult) else {
                return
            }
            
            measurementState.wrappedValue.addPoint(worldPos)
            placeDot(at: worldPos)
            updateVisuals()
            updateConfidence()
        }
        
        private func performRaycast(arView: ARView, point: CGPoint) -> ARRaycastResult? {
            if let query = arView.makeRaycastQuery(
                from: point,
                allowing: .existingPlaneGeometry,
                alignment: .any
            ), let result = arView.session.raycast(query).first {
                return result
            }
            
            if let query = arView.makeRaycastQuery(
                from: point,
                allowing: .estimatedPlane,
                alignment: .any
            ), let result = arView.session.raycast(query).first {
                return result
            }
            
            return nil
        }
        
        private func extractWorldPosition(_ result: ARRaycastResult) -> SIMD3<Float>? {
            let transform = result.worldTransform
            return SIMD3<Float>(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
        }
        
        private func placeDot(at position: SIMD3<Float>) {
            guard let arView = arView else { return }
            
            let sphere = MeshResource.generateSphere(radius: 0.006)
            let material = SimpleMaterial(color: .systemTeal, isMetallic: false)
            let entity = ModelEntity(mesh: sphere, materials: [material])
            
            let anchor = AnchorEntity(world: position)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            visualAnchors.append(anchor)
        }
        
        private func updateVisuals() {
            guard let arView = arView else { return }
            let state = measurementState.wrappedValue
            
            let dotCount = state.points.count
            while visualAnchors.count > dotCount {
                if let lastLine = visualAnchors.popLast() {
                    arView.scene.removeAnchor(lastLine)
                }
            }
            
            if state.points.count >= 2 {
                drawLine(from: state.points[0], to: state.points[1], color: .systemBlue)
            }
            
            if state.points.count >= 3,
               let p1 = state.points[safe: 0],
               let p2 = state.points[safe: 1],
               let p3 = state.points[safe: 2] {
                let mid = (p1 + p2) / 2
                let dir = simd_normalize(p2 - p1)
                let mirrored = mirrorPoint(p3, across: mid, along: dir)
                drawLine(from: p3, to: mirrored, color: .systemGreen)
            }
        }
        
        private func drawLine(from a: SIMD3<Float>, to b: SIMD3<Float>, color: UIColor) {
            guard let arView = arView else { return }
            
            let vector = b - a
            let length = simd_length(vector)
            let direction = simd_normalize(vector)
            let midpoint = (a + b) / 2
            
            let box = MeshResource.generateBox(
                size: SIMD3<Float>(0.003, 0.003, length),
                cornerRadius: 0.0015
            )
            let material = SimpleMaterial(color: color, isMetallic: false)
            let entity = ModelEntity(mesh: box, materials: [material])
            
            let zAxis = SIMD3<Float>(0, 0, 1)
            entity.transform.rotation = rotationBetween(from: zAxis, to: direction)
            
            let anchor = AnchorEntity(world: midpoint)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            visualAnchors.append(anchor)
        }
        
        private func mirrorPoint(
            _ point: SIMD3<Float>,
            across axisPoint: SIMD3<Float>,
            along axisDir: SIMD3<Float>
        ) -> SIMD3<Float> {
            let dir = simd_normalize(axisDir)
            let delta = point - axisPoint
            let alongComponent = simd_dot(delta, dir) * dir
            let perpComponent = delta - alongComponent
            return axisPoint + alongComponent - perpComponent
        }
        
        private func rotationBetween(from: SIMD3<Float>, to: SIMD3<Float>) -> simd_quatf {
            let cross = simd_cross(from, to)
            let dot = simd_dot(from, to)
            
            if dot < -0.9999 {
                let axis = simd_length(simd_cross(from, SIMD3<Float>(1, 0, 0))) > 0.01
                ? simd_normalize(simd_cross(from, SIMD3<Float>(1, 0, 0)))
                : simd_normalize(simd_cross(from, SIMD3<Float>(0, 1, 0)))
                return simd_quatf(angle: .pi, axis: axis)
            }
            
            let s = sqrt((1 + dot) * 2)
            return simd_normalize(simd_quatf(
                ix: cross.x / s,
                iy: cross.y / s,
                iz: cross.z / s,
                r: s / 2
            ))
        }
        
        private func updateConfidence() {
            let state = measurementState.wrappedValue
            guard state.points.count >= 2,
                  let cameraPos = currentCameraPosition else {
                confidenceScore.wrappedValue = nil
                return
            }
            
            let avgDistance = state.averageDistanceFromCamera(cameraPos)
            let planarity = state.surfacePlanarity
            
            let confidence = WoundMeasurementResult.MeasurementConfidence.calculate(
                trackingState: trackingLabel.wrappedValue,
                trackingIsGood: trackingIsGood.wrappedValue,
                distance: avgDistance,
                planarity: planarity
            )
            
            DispatchQueue.main.async {
                self.confidenceScore.wrappedValue = confidence
                
                if let dist = avgDistance {
                    let cm = Int(dist * 100)
                    let prefix = "📏 \(cm)\(LocalizedStrings.cmUnit)"
                    if dist < 0.15 {
                        self.distanceLabel.wrappedValue = "\(prefix) \(LocalizedStrings.distanceSuffixMoveBack)"
                    } else if dist > 0.35 {
                        self.distanceLabel.wrappedValue = "\(prefix) \(LocalizedStrings.distanceSuffixMoveCloser)"
                    } else {
                        self.distanceLabel.wrappedValue = "\(prefix) \(LocalizedStrings.distanceSuffixOK)"
                    }
                }
            }
        }
        
        @objc func handleUndo() {
            guard let arView = arView else { return }
            
            measurementState.wrappedValue.removeLastPoint()
            
            if let last = visualAnchors.popLast() {
                arView.scene.removeAnchor(last)
            }
            
            updateVisuals()
            updateConfidence()
        }
        
        @objc func handleReset() {
            guard let arView = arView else { return }
            
            measurementState.wrappedValue.reset()
            
            visualAnchors.forEach { arView.scene.removeAnchor($0) }
            visualAnchors.removeAll()
            
            DispatchQueue.main.async {
                self.confidenceScore.wrappedValue = nil
                self.distanceLabel.wrappedValue = ""
            }
        }
        
        @objc func capturePhoto() {
            guard let arView = arView,
                  let frame = arView.session.currentFrame else { return }
            
            let pixelBuffer = frame.capturedImage
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
            
            DispatchQueue.main.async {
                self.capturedPhoto.wrappedValue = image
            }
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let transform = frame.camera.transform
            currentCameraPosition = SIMD3<Float>(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
            
            if measurementState.wrappedValue.points.count >= 2 {
                updateConfidence()
            }
        }
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            let (label, isGood) = describeTrackingState(camera.trackingState)
            DispatchQueue.main.async {
                self.trackingLabel.wrappedValue = label
                self.trackingIsGood.wrappedValue = isGood
            }
        }
        
        private func describeTrackingState(_ state: ARCamera.TrackingState) -> (String, Bool) {
            switch state {
            case .normal:
                return (LocalizedStrings.arTrackingGood, true)
            case .notAvailable:
                return (LocalizedStrings.arTrackingNotAvailable, false)
            case .limited(let reason):
                switch reason {
                case .initializing:
                    return (LocalizedStrings.arInitializing, false)
                case .excessiveMotion:
                    return (LocalizedStrings.arTrackingSlowDown, false)
                case .insufficientFeatures:
                    return (LocalizedStrings.arTrackingLowFeatures, false)
                case .relocalizing:
                    return (LocalizedStrings.arTrackingRelocalizing, false)
                @unknown default:
                    return (LocalizedStrings.arTrackingLimited, false)
                }
            }
        }
        
        func cleanup() {
            guard let arView = arView else { return }
            visualAnchors.forEach { arView.scene.removeAnchor($0) }
            visualAnchors.removeAll()
        }
    }
}

extension Notification.Name {
    static let arMeasureUndo = Notification.Name("ARMeasureUndo")
    static let arMeasureReset = Notification.Name("ARMeasureReset")
    static let arCapturePhoto = Notification.Name("ARCapturePhoto")
}
