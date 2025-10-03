import SwiftUI

// Keep if you use it elsewhere
struct BodyAtlas {
    let imageName: String = "graph"   // asset name in your Assets.xcassets
    let width: CGFloat = 900          // native pixels of the PNG (for aspect only)
    let height: CGFloat = 1200
    var aspectRatio: CGFloat { width / height }
}

struct WoundLocationPickerView: View {
    @Binding var selectedRegion: String?
    var onConfirm: (String) -> Void   // keep for parent (can be a no-op)

    @ObservedObject var langManager = LocalizationManager.shared
    private let atlas = BodyAtlas()

    var body: some View {
        VStack(spacing: 12) {

            // Image + overlay share EXACTLY the same rect
            ZStack {
                Color.clear
                    .aspectRatio(atlas.aspectRatio, contentMode: .fit)
                    .overlay(
                        GeometryReader { ig in
                            ZStack {
                                // Image layer sized by GeometryReader
                                Image(atlas.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: ig.size.width, height: ig.size.height)

                                // Tap targets (all normalized 0…1 coordinates)
                                Group {
                                    // ---- FRONT ----
                                    regionButton("front_head",               0.29,  0.22, in: ig.size)
                                    regionButton("front_neck",               0.29,  0.27, in: ig.size)
                                    regionButton("front_left_shoulder",      0.19,  0.31, in: ig.size)
                                    regionButton("front_right_shoulder",     0.39,  0.31, in: ig.size)
                                    regionButton("front_right_chest",        0.23,  0.36, in: ig.size)
                                    regionButton("front_left_chest",         0.35,  0.36, in: ig.size)
                                    regionButton("front_right_elbow",        0.175, 0.39, in: ig.size)
                                    regionButton("front_left_elbow",         0.40,  0.39, in: ig.size)
                                    regionButton("front_right_forearm",      0.15,  0.48, in: ig.size)
                                    regionButton("front_left_forearm",       0.42,  0.48, in: ig.size)
                                    regionButton("abdomen_right_upper_quandrant", 0.25, 0.42, in: ig.size)
                                    regionButton("abdomen_left_upper_quadrant",   0.33, 0.42, in: ig.size)
                                    regionButton("abdomen_right_lower_quandrant", 0.25, 0.48, in: ig.size)
                                    regionButton("abdomen_left_lower_quandrant",  0.33, 0.48, in: ig.size)
                                    regionButton("left_hip",                 0.34,  0.51, in: ig.size)
                                    regionButton("right_hip",                0.24,  0.51, in: ig.size)
                                    regionButton("right_thigh",              0.25,  0.58, in: ig.size)
                                    regionButton("left_thigh",               0.33,  0.58, in: ig.size)
                                    regionButton("front_right_knee",         0.255, 0.655, in: ig.size)
                                    regionButton("front_left_knee",          0.32,  0.655, in: ig.size)
                                    regionButton("right_shin",               0.255, 0.73,  in: ig.size)
                                    regionButton("left_shin",                0.32,  0.73,  in: ig.size)
                                    regionButton("front_right_toes",         0.255, 0.82,  in: ig.size)
                                    regionButton("front_left_toes",          0.32,  0.82,  in: ig.size)

                                    // ---- BACK ----
                                    regionButton("back_head",                0.715, 0.22,  in: ig.size)
                                    regionButton("back_neck",                0.715, 0.27,  in: ig.size)
                                    regionButton("back_left_shoulder",       0.63,  0.31,  in: ig.size)
                                    regionButton("back_right_shoulder",      0.80,  0.31,  in: ig.size)
                                    regionButton("right_scapula",            0.77,  0.36,  in: ig.size)
                                    regionButton("left_scapula",             0.665, 0.36,  in: ig.size)
                                    regionButton("left_lower_back",          0.68,  0.46,  in: ig.size)
                                    regionButton("right_lower_back",         0.75,  0.46,  in: ig.size)
                                    regionButton("left_buttock",             0.68,  0.51,  in: ig.size)
                                    regionButton("right_buttock",            0.75,  0.51,  in: ig.size)
                                    regionButton("back_left_hand",           0.56,  0.53,  in: ig.size)
                                    regionButton("back_right_hand",          0.87,  0.53,  in: ig.size)
                                    regionButton("left_triceps",             0.60,  0.39,  in: ig.size)
                                    regionButton("right_triceps",            0.83,  0.39,  in: ig.size)
                                    regionButton("back_left_elbow",          0.60,  0.43,  in: ig.size)
                                    regionButton("back_right_elbow",         0.83,  0.43,  in: ig.size)
                                    regionButton("back_left_forearm",        0.58,  0.48,  in: ig.size)
                                    regionButton("back_right_forearm",       0.85,  0.48,  in: ig.size)
                                    regionButton("left_hamstring",           0.68,  0.58,  in: ig.size)
                                    regionButton("right_hamstring",          0.76,  0.58,  in: ig.size)
                                    regionButton("back_left_knee",           0.68,  0.655, in: ig.size)
                                    regionButton("back_right_knee",          0.75,  0.655, in: ig.size)
                                    regionButton("left_calf",                0.685, 0.73,  in: ig.size)
                                    regionButton("right_calf",               0.745, 0.73,  in: ig.size)
                                    regionButton("right_heel",               0.745, 0.82,  in: ig.size)
                                    regionButton("left_heel",                0.685, 0.82,  in: ig.size)
                                }
                            }
                        }
                    )
            }
            .padding(.horizontal)
            .frame(maxHeight: 360)

            if let region = selectedRegion {
                Text(region.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.headline)
                    .padding(.top, 4)
            }

            Spacer(minLength: 6)
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
    }

    // MARK: - Tap target (size scales with image width)
    @ViewBuilder
    private func regionButton(_ key: String, _ nx: CGFloat, _ ny: CGFloat, in size: CGSize) -> some View {
        let isSelected = (selectedRegion == key)
        // ~3.5% of image width, clamped to a sensible range
        let d = max(18, min(30, size.width * 0.035))

        Button {
            selectedRegion = key
            onConfirm(key)
        } label: {
            // Invisible but tappable circle; show highlight only when selected
            Circle()
                .fill(Color.black.opacity(0.001)) // must be non-zero to receive taps
                .frame(width: d, height: d)
                .overlay(
                    Circle()
                        .strokeBorder(Color.blue.opacity(isSelected ? 0.6 : 0), lineWidth: 2)
                        .background(
                            Circle().fill(isSelected ? Color.blue.opacity(0.25) : .clear)
                        )
                )
        }
        .buttonStyle(.plain)
        .position(x: nx * size.width, y: ny * size.height)
        .accessibilityLabel(Text(key.replacingOccurrences(of: "_", with: " ").capitalized))
    }
}
