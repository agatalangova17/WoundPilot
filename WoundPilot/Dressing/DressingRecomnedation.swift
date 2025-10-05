import SwiftUI

struct DressingRecommendationView: View {
    let measurements: WoundMeasurementResult
    let assessment: QuestionnairePayload

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var recommendations: DressingRecommendations?
    @State private var animate = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Size recommendations
                sizeCard

                // Primary dressing
                dressingCard(
                    title: LocalizedStrings.primaryDressingTitle,
                    icon: "bandage.fill",
                    products: recommendations?.primary ?? [],
                    color: .blue
                )

                // Secondary dressing
                if let secondary = recommendations?.secondary, !secondary.isEmpty {
                    dressingCard(
                        title: LocalizedStrings.secondaryDressingTitle,
                        icon: "square.stack.fill",
                        products: secondary,
                        color: .green
                    )
                }

                // Border/retention
                if let border = recommendations?.border, !border.isEmpty {
                    dressingCard(
                        title: LocalizedStrings.borderDressingTitle,
                        icon: "square.on.square",
                        products: border,
                        color: .orange
                    )
                }

                // Instructions and PDF export
                VStack(spacing: 16) {
                    instructionsCard

                    Button {
                        exportPDF()
                    } label: {
                        Label(LocalizedStrings.exportCompleteReport, systemImage: "doc.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.blue)
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding()
        }
        .navigationTitle(LocalizedStrings.dressingSelectionTitle)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showShare) {
            ActivityView(items: shareItems)
        }
        .onAppear {
            calculateRecommendations()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
    }

    // MARK: - Size Card

    private var sizeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(LocalizedStrings.recommendedDressingSizesTitle, systemImage: "ruler")
                .font(.headline)
                .foregroundColor(.primary)

            if let recs = recommendations {
                VStack(spacing: 12) {
                    sizeRow(label: LocalizedStrings.woundDimensionsLabel, value: recs.woundSize)
                    Divider()
                    sizeRow(label: LocalizedStrings.primaryDressingLabel, value: recs.primarySize, highlight: true)
                    sizeRow(label: LocalizedStrings.secondaryDressingLabel, value: recs.secondarySize)
                    sizeRow(label: LocalizedStrings.borderIfNeededLabel, value: recs.borderSize)
                }

                Text(LocalizedStrings.marginsNote)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
    }

    private func sizeRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(highlight ? .headline : .subheadline)
                .foregroundColor(highlight ? .blue : .primary)
                .fontWeight(highlight ? .bold : .regular)
        }
    }

    // MARK: - Dressing Card

    private func dressingCard(title: String, icon: String, products: [DressingProduct], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)

            ForEach(products) { product in
                ProductRow(product: product)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
    }

    // MARK: - Instructions Card

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(LocalizedStrings.applicationNotesTitle, systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint(LocalizedStrings.appNoteClean)
                bulletPoint(LocalizedStrings.appNoteApplyPrimary)
                bulletPoint(LocalizedStrings.appNoteMargin)
                bulletPoint(LocalizedStrings.appNoteSecure)
                bulletPoint(LocalizedStrings.appNoteChangeFrequency)
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").fontWeight(.bold)
            Text(text)
            Spacer()
        }
    }

    // MARK: - PDF Export

    private func exportPDF() {
        guard let recs = recommendations else { return }

        do {
            let pdfData = try CompletePDFComposer.make(
                assessment: assessment,
                measurements: measurements,
                dressing: recs
            )

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "CompleteWoundReport_\(Date().timeIntervalSince1970).pdf"
            let pdfURL = documentsPath.appendingPathComponent(fileName)

            try pdfData.write(to: pdfURL, options: .atomic)

            shareItems = [pdfURL]
            showShare = true
        } catch {
            print("PDF generation error: \(error)")
        }
    }

    // MARK: - Calculate Recommendations

    private func calculateRecommendations() {
        recommendations = DressingEngine.recommend(
            measurements: measurements,
            assessment: assessment
        )
    }
}

// MARK: - Product Row Component

private struct ProductRow: View {
    let product: DressingProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if product.priority == .preferred {
                    Text(LocalizedStrings.preferredTag)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                }
            }

            Text(product.rationale)
                .font(.caption)
                .foregroundColor(.secondary)

            if !product.examples.isEmpty {
                let line = "\(LocalizedStrings.examplesPrefix) \(product.examples.joined(separator: ", "))"
                Text(line)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Models

struct DressingRecommendations {
    let woundSize: String
    let primarySize: String
    let secondarySize: String
    let borderSize: String

    let primary: [DressingProduct]
    let secondary: [DressingProduct]
    let border: [DressingProduct]
}

struct DressingProduct: Identifiable {
    let id = UUID()
    let name: String
    let rationale: String
    let examples: [String]
    let priority: Priority

    enum Priority { case preferred, alternative }
}

// MARK: - Dressing Engine (Rules-based)

enum DressingEngine {
    static func recommend(measurements: WoundMeasurementResult, assessment: QuestionnairePayload) -> DressingRecommendations {

        // Calculate sizes with margins
        let length = measurements.lengthCm
        let width = measurements.widthCm

        let primaryLength = Int(ceil(length + 4))
        let primaryWidth  = Int(ceil(width + 4))
        let secondaryLength = Int(ceil(length + 6))
        let secondaryWidth  = Int(ceil(width + 6))
        let borderLength    = Int(ceil(length + 8))
        let borderWidth     = Int(ceil(width + 8))

        var primary: [DressingProduct] = []

        if assessment.tissue == "necrosis" {
            primary.append(
                DressingProduct(
                    name: LocalizedStrings.dpHydrogelName,
                    rationale: LocalizedStrings.dpHydrogelRationale,
                    examples: ["IntraSite Gel", "Purilon Gel", "DuoDERM Hydroactive"],
                    priority: .preferred
                )
            )
        } else if assessment.tissue == "slough" {
            if assessment.moisture == "high" {
                primary.append(
                    DressingProduct(
                        name: LocalizedStrings.dpAlginateName,
                        rationale: LocalizedStrings.dpAlginateRationale,
                        examples: ["Kaltostat", "Sorbsan", "Algisite M"],
                        priority: .preferred
                    )
                )
            } else {
                primary.append(
                    DressingProduct(
                        name: LocalizedStrings.dpHydrocolloidHydrofiberName,
                        rationale: LocalizedStrings.dpHydrocolloidHydrofiberRationale,
                        examples: ["DuoDERM Extra Thin", "Aquacel Foam"],
                        priority: .preferred
                    )
                )
            }
        } else if assessment.tissue == "granulation" {
            if assessment.infection == "local" || assessment.infection == "systemic" {
                primary.append(
                    DressingProduct(
                        name: LocalizedStrings.dpSilverFoamName,
                        rationale: LocalizedStrings.dpSilverFoamRationale,
                        examples: ["Mepilex Ag", "Aquacel Ag Foam", "Acticoat"],
                        priority: .preferred
                    )
                )
            } else {
                switch assessment.moisture {
                case "dry":
                    primary.append(
                        DressingProduct(
                            name: LocalizedStrings.dpHydrogelSheetName,
                            rationale: LocalizedStrings.dpHydrogelSheetRationale,
                            examples: ["IntraSite Gel", "Nu-Gel"],
                            priority: .preferred
                        )
                    )
                case "low":
                    primary.append(
                        DressingProduct(
                            name: LocalizedStrings.dpThinFoamOrHydrocolloidName,
                            rationale: LocalizedStrings.dpThinFoamOrHydrocolloidRationale,
                            examples: ["Mepilex Lite", "DuoDERM Extra Thin"],
                            priority: .preferred
                        )
                    )
                case "moderate":
                    primary.append(
                        DressingProduct(
                            name: LocalizedStrings.dpFoamName,
                            rationale: LocalizedStrings.dpFoamRationale,
                            examples: ["Mepilex Border", "Allevyn Gentle"],
                            priority: .preferred
                        )
                    )
                case "high":
                    primary.append(
                        DressingProduct(
                            name: LocalizedStrings.dpSuperabsorbentOrAlginateName,
                            rationale: LocalizedStrings.dpSuperabsorbentOrAlginateRationale,
                            examples: ["Zetuvit Plus", "Kaltostat", "Aquacel Foam Extra"],
                            priority: .preferred
                        )
                    )
                default:
                    primary.append(
                        DressingProduct(
                            name: LocalizedStrings.dpFoamName,
                            rationale: LocalizedStrings.dpFoamRationaleGeneric,
                            examples: ["Mepilex", "Allevyn"],
                            priority: .preferred
                        )
                    )
                }
            }
        }

        if (assessment.infection == "local" || assessment.infection == "systemic")
            && !primary.contains(where: { $0.name.contains("Silver") || $0.name.contains("Strieborný") || $0.name.contains("Antimicrobial") || $0.name.contains("Antimikrobiálny") }) {
            primary.append(
                DressingProduct(
                    name: LocalizedStrings.dpAntimicrobialAltName,
                    rationale: LocalizedStrings.dpAntimicrobialAltRationale,
                    examples: ["Acticoat", "Aquacel Ag"],
                    priority: .alternative
                )
            )
        }

        var secondary: [DressingProduct] = []

        if assessment.etiology == "venous" && assessment.abi == "ge0_8" {
            secondary.append(
                DressingProduct(
                    name: LocalizedStrings.dpCompressionSystemName,
                    rationale: LocalizedStrings.dpCompressionSystemRationale,
                    examples: [LocalizedStrings.dpCompressionExample4Layer, LocalizedStrings.dpCompressionExampleShortStretch],
                    priority: .preferred
                )
            )
        }

        if assessment.moisture == "high" {
            secondary.append(
                DressingProduct(
                    name: LocalizedStrings.dpAbsorbentPadName,
                    rationale: LocalizedStrings.dpAbsorbentPadRationale,
                    examples: ["Zetuvit", "Melolin"],
                    priority: .preferred
                )
            )
        }

        var border: [DressingProduct] = []

        border.append(
            DressingProduct(
                name: LocalizedStrings.dpFilmOrSiliconeBorderName,
                rationale: LocalizedStrings.dpFilmOrSiliconeBorderRationale,
                examples: ["Tegaderm", "Mepilex Border", "Opsite Flexigrid"],
                priority: .preferred
            )
        )

        if assessment.etiology == "diabeticFoot" {
            border.append(
                DressingProduct(
                    name: LocalizedStrings.dpOffloadingDeviceName,
                    rationale: LocalizedStrings.dpOffloadingDeviceRationale,
                    examples: ["Total contact cast", "Removable cast boot", "Felted foam"],
                    priority: .preferred
                )
            )
        }

        return DressingRecommendations(
            woundSize: "\(String(format: "%.1f", length)) × \(String(format: "%.1f", width)) cm",
            primarySize: "\(primaryLength) × \(primaryWidth) cm",
            secondarySize: "\(secondaryLength) × \(secondaryWidth) cm",
            borderSize: "\(borderLength) × \(borderWidth) cm",
            primary: primary,
            secondary: secondary,
            border: border
        )
    }
}

// MARK: - PDF Composer 

private enum CompletePDFComposer {
    static func make(
        assessment: QuestionnairePayload,
        measurements: WoundMeasurementResult,
        dressing: DressingRecommendations
    ) throws -> Data {

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let dateStr = df.string(from: Date())

        func productHTML(_ p: DressingProduct, showStar: Bool = false) -> String {
            """
            <div class="product">
                <div class="product-name">\(escape(p.name)) \(showStar && p.priority == .preferred ? "★" : "")</div>
                <div class="product-rationale">\(escape(p.rationale))</div>
                \(p.examples.isEmpty ? "" : "<div class=\"product-examples\">\(escape(LocalizedStrings.examplesPrefix)) \(escape(p.examples.joined(separator: ", ")))</div>")
            </div>
            """
        }

        let primaryHTML = dressing.primary.map { productHTML($0, showStar: true) }.joined()

        let secondaryHTML = dressing.secondary.isEmpty ? "" : """
        <div class="dressing-section">
            <div class="section-title">\(escape(LocalizedStrings.secondaryDressingTitle))</div>
            \(dressing.secondary.map { productHTML($0) }.joined())
        </div>
        """

        let borderHTML = dressing.border.isEmpty ? "" : """
        <div class="dressing-section">
            <div class="section-title">\(escape(LocalizedStrings.borderDressingTitle))</div>
            \(dressing.border.map { productHTML($0) }.joined())
        </div>
        """

        let html = """
        <html>
        <head>
        <meta name="viewport" content="initial-scale=1.0"/>
        <style>
            @page { size: A4; margin: 28pt; }
            body { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; color:#111; font-size: 11pt; }

            .header {
                background: linear-gradient(135deg, #0a84ff, #0066cc);
                color: #fff; border-radius: 12pt; padding: 16pt; margin-bottom: 12pt;
            }
            .header h1 { margin: 0 0 8pt 0; font-size: 18pt; }
            .header .date { font-size: 9pt; opacity: 0.9; }

            .measurements {
                background: #f6f7f9; border-radius: 10pt; padding: 12pt; margin-bottom: 12pt;
            }
            .measurements h2 { font-size: 12pt; margin: 0 0 8pt 0; color: #666; }
            .size-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8pt; }
            .size-item { padding: 6pt; background: white; border-radius: 6pt; }
            .size-label { font-size: 9pt; color: #666; }
            .size-value { font-size: 11pt; font-weight: bold; color: #0a84ff; }

            .dressing-section { margin: 12pt 0; }
            .section-title { font-size: 13pt; font-weight: bold; color: #0a84ff; margin-bottom: 8pt; }

            .product {
                background: #f6f7f9; border-radius: 8pt; padding: 10pt; margin-bottom: 8pt;
            }
            .product-name { font-weight: bold; margin-bottom: 4pt; }
            .product-rationale { font-size: 10pt; color: #555; margin-bottom: 4pt; }
            .product-examples { font-size: 9pt; color: #0a84ff; }

            .instructions {
                background: #e3f2fd; border-radius: 10pt; padding: 12pt; margin-top: 12pt;
            }
            .instructions h3 { margin: 0 0 8pt 0; font-size: 12pt; color: #0a84ff; }
            .instructions ul { margin: 0; padding-left: 16pt; }
            .instructions li { margin: 4pt 0; font-size: 10pt; }

            .footer { margin-top: 16pt; font-size: 8pt; color: #666; border-top: 1pt solid #ddd; padding-top: 8pt; }
        </style>
        </head>
        <body>
            <div class="header">
                <h1>\(escape(LocalizedStrings.pdfReportTitle))</h1>
                <div class="date">\(escape(dateStr))</div>
            </div>

            <div class="measurements">
                <h2>\(escape(LocalizedStrings.pdfWoundMeasurements))</h2>
                <div class="size-grid">
                    <div class="size-item">
                        <div class="size-label">\(escape(LocalizedStrings.pdfWoundSize))</div>
                        <div class="size-value">\(escape(dressing.woundSize))</div>
                    </div>
                    <div class="size-item">
                        <div class="size-label">\(escape(LocalizedStrings.pdfPrimary))</div>
                        <div class="size-value">\(escape(dressing.primarySize))</div>
                    </div>
                    <div class="size-item">
                        <div class="size-label">\(escape(LocalizedStrings.pdfSecondary))</div>
                        <div class="size-value">\(escape(dressing.secondarySize))</div>
                    </div>
                    <div class="size-item">
                        <div class="size-label">\(escape(LocalizedStrings.pdfBorderIfNeeded))</div>
                        <div class="size-value">\(escape(dressing.borderSize))</div>
                    </div>
                </div>
            </div>

            <div class="dressing-section">
                <div class="section-title">\(escape(LocalizedStrings.primaryDressingTitle))</div>
                \(primaryHTML)
            </div>

            \(secondaryHTML)
            \(borderHTML)

            <div class="instructions">
                <h3>\(escape(LocalizedStrings.pdfApplicationGuidelines))</h3>
                <ul>
                    <li>\(escape(LocalizedStrings.appNoteClean))</li>
                    <li>\(escape(LocalizedStrings.appNoteApplyPrimary))</li>
                    <li>\(escape(LocalizedStrings.appNoteMargin))</li>
                    <li>\(escape(LocalizedStrings.appNoteSecure))</li>
                    <li>\(escape(LocalizedStrings.appNoteChangeFrequency))</li>
                </ul>
            </div>

            <div class="footer">
                \(escape(LocalizedStrings.pdfFooterText))
            </div>
        </body>
        </html>
        """

        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIPrintPageRenderer()

        let a4 = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let margin: CGFloat = 28
        renderer.setValue(a4, forKey: "paperRect")
        renderer.setValue(a4.insetBy(dx: margin, dy: margin), forKey: "printableRect")

        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, .zero, nil)

        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()
        return data as Data
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

