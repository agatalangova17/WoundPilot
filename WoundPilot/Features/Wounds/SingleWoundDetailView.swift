import SwiftUI
import ARKit

struct SingleWoundDetailView: View {
    let wound: Wound

    @ObservedObject var langManager = LocalizationManager.shared
    @State private var navigateToSizeAnalysis = false

    // AR sheet + results
    @State private var showAR = false
    @State private var showARUnsupportedAlert = false
    @State private var lastLengthCm: Double?
    @State private var lastWidthCm: Double?
    @State private var lastAreaCm2: Double?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                woundImageSection
                metadataSection
                measurementChipsSection
                measureARButton
                analyzeButton
                Spacer(minLength: 0)
            }
            .padding(.top)
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .navigationTitle(LocalizedStrings.woundEntryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSizeAnalysis) {
            SizeAnalysisView(wound: wound)
        }
        .sheet(isPresented: $showAR) {
            WoundMeasurementView(onComplete: handleMeasurementResult)
        }
        .alert("AR not supported on this device", isPresented: $showARUnsupportedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This iPhone/iPad does not support AR world tracking.")
        }
    }
    
    // MARK: - Measurement Handler
    
    private func handleMeasurementResult(_ result: WoundMeasurementResult) {
        // New structure already in cm
        let lengthCm = Double(result.lengthCm)
        let widthCm = Double(result.widthCm)
        
        let calculatedArea = lengthCm * widthCm * 0.785
        let areaCm2: Double
        if let resultArea = result.areaCm2 {
            areaCm2 = Double(resultArea)
        } else {
            areaCm2 = calculatedArea
        }

        // Show locally
        self.lastLengthCm = lengthCm
        self.lastWidthCm = widthCm
        self.lastAreaCm2 = areaCm2

        // Persist to history
        WoundService.shared.addMeasurement(
            woundId: wound.id,
            lengthCm: lengthCm,
            widthCm: widthCm,
            areaCm2: areaCm2,
            width1Cm: widthCm,
            width2Cm: widthCm
        ) { result in
            if case let .failure(error) = result {
                print("Failed to add measurement: \(error)")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder private var woundImageSection: some View {
        if let imageURL = URL(string: wound.imageURL) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    placeholderCard
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                case .failure:
                    placeholderCard
                @unknown default:
                    placeholderCard
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 260)
            .padding(.horizontal)
        }
    }

    private var placeholderCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
            ProgressView()
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let location = displayLocation {
                Label(location, systemImage: "mappin.circle.fill")
            }
            Label(formattedTimestamp, systemImage: "calendar")
            if let name = wound.woundGroupName {
                Label(name, systemImage: "folder.fill")
            }
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    @ViewBuilder private var measurementChipsSection: some View {
        if let L = lastLengthCm, let W = lastWidthCm {
            HStack(spacing: 12) {
                lengthChip(L)
                widthChip(W)
                if let A = lastAreaCm2 {
                    areaChip(A)
                }
            }
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.horizontal)
        }
    }
    
    private func lengthChip(_ value: Double) -> some View {
        Text(String(format: "L: %.1f cm", value))
    }
    
    private func widthChip(_ value: Double) -> some View {
        Text(String(format: "W: %.1f cm", value))
    }
    
    private func areaChip(_ value: Double) -> some View {
        Text(String(format: "A: %.1f cm²", value))
    }

    private var measureARButton: some View {
        Button(action: handleARButtonTap) {
            Label("Measure (AR)", systemImage: "ruler")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentBlue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private func handleARButtonTap() {
        if ARWorldTrackingConfiguration.isSupported {
            showAR = true
        } else {
            showARUnsupportedAlert = true
        }
    }

    private var analyzeButton: some View {
        Button {
            navigateToSizeAnalysis = true
        } label: {
            Text(LocalizedStrings.analyzeWound)
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentBlue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var formattedTimestamp: String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return df.string(from: wound.timestamp)
    }

    private var displayLocation: String? {
        guard let loc = wound.location, !loc.isEmpty else { return nil }
        return loc.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
