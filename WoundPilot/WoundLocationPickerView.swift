import SwiftUI

struct WoundLocationPickerView: View {
    @Binding var selectedRegion: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Wound Location")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)

            GeometryReader { geo in
                ZStack {
                    // Body diagram (side-by-side front & back)
                    Image("graph")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)

                    // Overlay region buttons (scaled to image size)
                    Group {
                        // FRONT
                        regionButton(region: "front_head", x: 0.29, y: 0.22, size: geo.size)
                        regionButton(region: "front_neck", x: 0.29, y: 0.27, size: geo.size)
                        regionButton(region: "front_left_shoulder", x: 0.19, y: 0.31, size: geo.size)
                        regionButton(region: "front_right_shoulder", x: 0.39, y: 0.31, size: geo.size)
                        regionButton(region: "front_right_chest", x: 0.23, y: 0.36, size: geo.size)
                        regionButton(region: "front_left_chest", x: 0.35, y: 0.36, size: geo.size)
                        regionButton(region: "front_right_elbow", x: 0.175, y: 0.39, size: geo.size)
                        regionButton(region: "front_left_elbow", x: 0.40, y: 0.39, size: geo.size)
                        regionButton(region: "front_right_forearm", x: 0.15, y: 0.48, size: geo.size)
                        regionButton(region: "front_left_forearm", x: 0.42, y: 0.48, size: geo.size)
                        regionButton(region: "abdomen_right_upper_quandrant", x: 0.25, y: 0.42, size: geo.size)
                        regionButton(region: "abdomen_left_upper_quadrant", x: 0.33, y: 0.42, size: geo.size)
                        regionButton(region: "abdomen_right_lower_quandrant", x: 0.25, y: 0.48, size: geo.size)
                        regionButton(region: "abdomen_left_lower_quandrant", x: 0.33, y: 0.48, size: geo.size)
                        regionButton(region: "left_hip", x: 0.34, y: 0.51, size: geo.size)
                        regionButton(region: "right_hip", x: 0.24, y: 0.51, size: geo.size)
                        regionButton(region: "right_thigh", x: 0.25, y: 0.58, size: geo.size)
                        regionButton(region: "left_thigh", x: 0.33, y: 0.58, size: geo.size)
                        regionButton(region: "front_right_knee", x: 0.255, y: 0.655, size: geo.size)
                        regionButton(region: "front_left_knee", x: 0.32, y: 0.655, size: geo.size)
                        regionButton(region: "right_shin", x: 0.255, y: 0.73, size: geo.size)
                        regionButton(region: "left_shin", x: 0.32, y: 0.73, size: geo.size)
                        regionButton(region: "front_right_toes", x: 0.255, y: 0.82, size: geo.size)
                        regionButton(region: "front_left_toes", x: 0.32, y: 0.82, size: geo.size)
                        
                        //BACK
                        regionButton(region: "back_head", x: 0.715, y: 0.22, size: geo.size)
                        regionButton(region: "back_neck", x: 0.715, y: 0.27, size: geo.size)
                        regionButton(region: "back_left_shoulder", x: 0.63, y: 0.31, size: geo.size)
                        regionButton(region: "back_right_shoulder", x: 0.80, y: 0.31, size: geo.size)
                        regionButton(region: "right_scapula", x: 0.77, y: 0.36, size: geo.size)
                        regionButton(region: "left_scapula", x: 0.665, y: 0.36, size: geo.size)
                        regionButton(region: "left_lower_back", x: 0.68, y: 0.46, size: geo.size)
                        regionButton(region: "right_lower_back", x: 0.75, y: 0.46, size: geo.size)
                        regionButton(region: "left_buttock", x: 0.68, y: 0.51, size: geo.size)
                        regionButton(region: "right_buttock", x: 0.75, y: 0.51, size: geo.size)
                        regionButton(region: "back_left_hand", x: 0.56, y: 0.53, size: geo.size)
                        regionButton(region: "back_right_hand", x: 0.87, y: 0.53, size: geo.size)
                        regionButton(region: "left_triceps", x: 0.60, y: 0.39, size: geo.size)
                        regionButton(region: "right_triceps", x: 0.83, y: 0.39, size: geo.size)
                        regionButton(region: "back_left_elbow", x: 0.60, y: 0.43, size: geo.size)
                        regionButton(region: "back_right_elbow", x: 0.83, y: 0.43, size: geo.size)
                        regionButton(region: "back_left_forearm", x: 0.58, y: 0.48, size: geo.size)
                        regionButton(region: "back_right_forearm", x: 0.85, y: 0.48, size: geo.size)
                        regionButton(region: "left_hamstring", x: 0.68, y: 0.58, size: geo.size)
                        regionButton(region: "right_hamstring", x: 0.76, y: 0.58, size: geo.size)
                        regionButton(region: "back_left_knee", x: 0.68, y: 0.655, size: geo.size)
                        regionButton(region: "back_right_knee", x: 0.75, y: 0.655, size: geo.size)
                        regionButton(region: "left_calf", x: 0.685, y: 0.73, size: geo.size)
                        regionButton(region: "right_calf", x: 0.745, y: 0.73, size: geo.size)
                        regionButton(region: "right_heel", x: 0.745, y: 0.82, size: geo.size)
                        regionButton(region: "left_heel", x: 0.685, y: 0.82, size: geo.size)
                        
                    }
                }
            }
            .frame(height: 500)

            // Show selected region
            if let region = selectedRegion {
                Text(region.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.headline)
                    .foregroundColor(.black)
            }

            // Confirm button
            Button("Confirm Location") {
                dismiss()
            }
            .disabled(selectedRegion == nil)
            .padding()
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    // MARK: - Button Builder with Responsive Positioning
    func regionButton(region: String, x: CGFloat, y: CGFloat, size: CGSize) -> some View {
        Button(action: {
            selectedRegion = region
        }) {
            Circle()
                .fill(selectedRegion == region ? Color.blue.opacity(0.3) : Color.clear)
                .frame(width: 20, height: 20)
        }
        .position(x: x * size.width, y: y * size.height)
    }
}


