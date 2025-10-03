import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import UIKit
import ARKit

struct SizeAnalysisView: View {
    let wound: Wound
    @ObservedObject var langManager = LocalizationManager.shared

    private let defaultWidth: Double  = 3.5
    private let defaultHeight: Double = 4.0

    @State private var showAR = false
    @State private var showARUnsupported = false
    @State private var arWidthCm: Double?
    @State private var arHeightCm: Double?
    @State private var arAreaCm2: Double?

    @State private var manualEntry = false
    @State private var manualWidth = ""
    @State private var manualHeight = ""

    @State private var navigateToQuestionnaire = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                imageSection
                arMeasureButton
                currentSizeSection
                Divider().padding(.horizontal)
                manualToggleSection
                manualInputsSection
                Spacer(minLength: 30)
                continueButton
            }
            .padding(.top)
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .navigationTitle(LocalizedStrings.sizeAnalysisTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToQuestionnaire) {
            QuestionnaireView(
                woundGroupId: wound.woundGroupId,
                patientId: wound.patientId
            )
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showAR) {
            WoundMeasurementView(onComplete: handleMeasurementResult)
        }
        .alert("AR not available", isPresented: $showARUnsupported) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Live AR measurement needs a real device that supports ARKit.")
        }
    }
    
    // MARK: - Measurement Handler - SIMPLIFIED
    
    private func handleMeasurementResult(_ result: WoundMeasurementResult) {
        let lengthCm = Double(result.lengthCm)
        let widthCm = Double(result.widthCm)
        
        // Break down the complex expression
        let calculatedArea = lengthCm * widthCm * 0.785
        let areaCm2: Double
        if let resultArea = result.areaCm2 {
            areaCm2 = Double(resultArea)
        } else {
            areaCm2 = calculatedArea
        }

        self.arHeightCm = lengthCm
        self.arWidthCm = widthCm
        self.arAreaCm2 = areaCm2

        saveMeasurement(lengthCm: lengthCm, widthCm: widthCm, areaCm2: areaCm2)

        if manualEntry {
            updateManualFields(widthCm: widthCm, lengthCm: lengthCm)
        }
    }
    
    private func saveMeasurement(lengthCm: Double, widthCm: Double, areaCm2: Double) {
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
    
    private func updateManualFields(widthCm: Double, lengthCm: Double) {
        self.manualWidth = formatNumber(widthCm)
        self.manualHeight = formatNumber(lengthCm)
    }

    // MARK: - Sections

    @ViewBuilder private var imageSection: some View {
        if let imageURL = URL(string: wound.imageURL) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    placeholderCard
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .shadow(radius: 6)
                case .failure:
                    placeholderCard
                @unknown default:
                    placeholderCard
                }
            }
            .frame(maxHeight: 250)
            .padding(.horizontal)
        }
    }

    private var arMeasureButton: some View {
        Button(action: handleARButtonTap) {
            Label("Measure with AR (live)", systemImage: "ruler")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func handleARButtonTap() {
        #if targetEnvironment(simulator)
        showARUnsupported = true
        #else
        if ARWorldTrackingConfiguration.isSupported {
            showAR = true
        } else {
            showARUnsupported = true
        }
        #endif
    }

    private var currentSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.estimatedWoundSize)
                .font(.headline)

            measurementCards
            areaDisplay
            tipText
        }
        .padding(.horizontal)
    }
    
    private var measurementCards: some View {
        HStack(spacing: 20) {
            widthCard
            heightCard
        }
    }
    
    private var widthCard: some View {
        measurementCard(
            title: LocalizedStrings.widthLabel,
            value: displayWidth,
            unit: LocalizedStrings.cmUnit,
            icon: "arrow.left.and.right"
        )
    }
    
    private var heightCard: some View {
        measurementCard(
            title: LocalizedStrings.heightLabel,
            value: displayHeight,
            unit: LocalizedStrings.cmUnit,
            icon: "arrow.up.and.down"
        )
    }
    
    @ViewBuilder
    private var areaDisplay: some View {
        if let area = displayAreaCm2 {
            let areaText = "Area: \(formatNumber(area)) \(LocalizedStrings.cm2Unit)"
            Text(areaText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var tipText: some View {
        let shouldShowTip = arWidthCm == nil && arHeightCm == nil && !manualEntry
        if shouldShowTip {
            Text("Tip: For best accuracy, use the AR button above on a real device.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var manualToggleSection: some View {
        Toggle(isOn: $manualEntry) {
            Label(LocalizedStrings.editSizeManually, systemImage: "pencil")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        .padding(.horizontal)
    }

    @ViewBuilder private var manualInputsSection: some View {
        if manualEntry {
            VStack(spacing: 16) {
                widthTextField
                heightTextField
            }
            .padding(.horizontal)
        }
    }
    
    private var widthTextField: some View {
        TextField(LocalizedStrings.enterWidthCm, text: $manualWidth)
            .keyboardType(.decimalPad)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
    }
    
    private var heightTextField: some View {
        TextField(LocalizedStrings.enterHeightCm, text: $manualHeight)
            .keyboardType(.decimalPad)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
    }

    private var continueButton: some View {
        Button(action: { navigateToQuestionnaire = true }) {
            Text(LocalizedStrings.continueButton)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .padding(.horizontal)
    }

    private var placeholderCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 220)
            ProgressView()
        }
    }

    func measurementCard(title: String, value: Double, unit: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            let valueText = "\(formatNumber(value)) \(unit)"
            Text(valueText)
                .font(.title3.bold())

            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var displayWidth: Double {
        if manualEntry {
            if let w = parseNumber(manualWidth) {
                return w
            }
        }
        if let w = arWidthCm {
            return w
        }
        return defaultWidth
    }

    private var displayHeight: Double {
        if manualEntry {
            if let h = parseNumber(manualHeight) {
                return h
            }
        }
        if let h = arHeightCm {
            return h
        }
        return defaultHeight
    }

    private var displayAreaCm2: Double? {
        if let a = arAreaCm2 {
            return a
        }
        let width = displayWidth
        let height = displayHeight
        return width * height
    }

    private func formatNumber(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 1
        nf.maximumFractionDigits = 1
        nf.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        
        if let formatted = nf.string(from: NSNumber(value: value)) {
            return formatted
        }
        return String(format: "%.1f", value)
    }

    private func parseNumber(_ s: String) -> Double? {
        let normalized = s.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
