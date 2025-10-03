//  WoundMeasurementView.swift
//  WoundPilot

import SwiftUI
import ARKit

struct WoundMeasurementView: View {
    var onComplete: ((WoundMeasurementResult) -> Void)?
    
    @State private var hasLiDAR = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    @State private var showManualEntry = false
    
    var body: some View {
        Group {
            if hasLiDAR && !showManualEntry {
                ARMeasureView(
                    onComplete: { result in
                        onComplete?(result)
                        // REMOVED: dismiss() - let parent handle navigation
                    },
                    onSwitchToManual: {
                        showManualEntry = true
                    }
                )
            } else {
                ManualMeasurementView(onComplete: { result in
                    onComplete?(result)
                    // REMOVED: dismiss() - let parent handle navigation
                })
            }
        }
    }
}
