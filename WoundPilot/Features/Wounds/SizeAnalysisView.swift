import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import UIKit
import ARKit   // for AR availability check

struct SizeAnalysisView: View {
    let wound: Wound
    @ObservedObject var langManager = LocalizationManager.shared

    // Defaults (until AR/manual provided)
    private let defaultWidth: Double  = 3.5
    private let defaultHeight: Double = 4.0

    // AR state
    @State private var showAR = false
    @State private var showARUnsupported = false
    @State private var arWidthCm: Double?    // short axis
    @State private var arHeightCm: Double?   // long axis
    @State private var arAreaCm2: Double?

    // Manual entry
    @State private var manualEntry = false
    @State private var manualWidth = ""
    @State private var manualHeight = ""

    // Navigation
    @State private var navigateToQuestionnaire = false

    // MARK: - Body

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
            ARMeasureView { res in
                // Map: Height = Length (long axis), Width = Width (short axis)
                let lengthCm = Double(res.lengthM * 100)
                let widthCm  = Double((res.widthAvgM ?? res.width1M ?? 0) * 100)
                let areaCm2  = Double((res.areaEllM2 ?? res.areaRectM2 ?? 0) * 10_000)

                // Fill UI
                self.arHeightCm = lengthCm
                self.arWidthCm  = widthCm
                self.arAreaCm2  = areaCm2

                // Persist to history (and mirror latest on parent wound)
                WoundService.shared.addMeasurement(
                    woundId: wound.id,
                    lengthCm: lengthCm,
                    widthCm: widthCm,
                    areaCm2: areaCm2,
                    width1Cm: Double((res.width1M ?? 0) * 100),
                    width2Cm: Double((res.width2M ?? 0) * 100)
                ) { result in
                    if case let .failure(error) = result {
                        print("Failed to add measurement: \(error)")
                    }
                }

                // If manual on, prefill text fields with AR values
                if manualEntry {
                    self.manualWidth  = formatNumber(widthCm)
                    self.manualHeight = formatNumber(lengthCm)
                }
            }
        }
        .alert("AR not available", isPresented: $showARUnsupported) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Live AR measurement needs a real device that supports ARKit.")
        }
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
        Button {
            #if targetEnvironment(simulator)
            showARUnsupported = true
            #else
            if ARWorldTrackingConfiguration.isSupported {
                showAR = true
            } else {
                showARUnsupported = true
            }
            #endif
        } label: {
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

    private var currentSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStrings.estimatedWoundSize)
                .font(.headline)

            HStack(spacing: 20) {
                measurementCard(
                    title: LocalizedStrings.widthLabel,
                    value: displayWidth,
                    unit: LocalizedStrings.cmUnit,
                    icon: "arrow.left.and.right"
                )
                measurementCard(
                    title: LocalizedStrings.heightLabel,
                    value: displayHeight,
                    unit: LocalizedStrings.cmUnit,
                    icon: "arrow.up.and.down"
                )
            }

            if let area = displayAreaCm2 {
                Text("Area: \(formatNumber(area)) \(LocalizedStrings.cm2Unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if arWidthCm == nil && arHeightCm == nil && !manualEntry {
                Text("Tip: For best accuracy, use the AR button above on a real device.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
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
                TextField(LocalizedStrings.enterWidthCm, text: $manualWidth)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                TextField(LocalizedStrings.enterHeightCm, text: $manualHeight)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    private var continueButton: some View {
        Button {
            navigateToQuestionnaire = true
        } label: {
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

    // MARK: - Cards & Helpers

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

            Text("\(formatNumber(value)) \(unit)")
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
        if manualEntry, let w = parseNumber(manualWidth) { return w }
        if let w = arWidthCm { return w }
        return defaultWidth
    }

    private var displayHeight: Double {
        if manualEntry, let h = parseNumber(manualHeight) { return h }
        if let h = arHeightCm { return h }
        return defaultHeight
    }

    private var displayAreaCm2: Double? {
        if let a = arAreaCm2 { return a }
        // If no AR area, estimate as rectangle from display values
        return displayWidth * displayHeight
    }

    private func formatNumber(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 1
        nf.maximumFractionDigits = 1
        nf.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return nf.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    private func parseNumber(_ s: String) -> Double? {
        let normalized = s.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
