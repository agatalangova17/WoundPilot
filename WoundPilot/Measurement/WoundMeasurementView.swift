//  WoundMeasurementView.swift
//  WoundPilot

import SwiftUI
import ARKit

struct WoundMeasurementView: View {
    var onComplete: ((WoundMeasurementResult) -> Void)?
    
    @State private var hasLiDAR = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    @State private var showManualEntry = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if hasLiDAR && !showManualEntry {
                ARMeasureView(
                    onComplete: { result in
                        onComplete?(result)
                        dismiss()
                    },
                    onSwitchToManual: {
                        showManualEntry = true
                    }
                )
            } else {
                ManualMeasurementView(onComplete: { result in
                    onComplete?(result)
                    dismiss()
                })
            }
        }
    }
}
