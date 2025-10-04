import SwiftUI

struct DressingRecommendationView: View {
    let measurements: WoundMeasurementResult
    let assessment: QuestionnairePayload
    
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
                    title: "Primary Dressing",
                    icon: "bandage.fill",
                    products: recommendations?.primary ?? [],
                    color: .blue
                )
                
                // Secondary dressing
                if let secondary = recommendations?.secondary, !secondary.isEmpty {
                    dressingCard(
                        title: "Secondary Dressing",
                        icon: "square.stack.fill",
                        products: secondary,
                        color: .green
                    )
                }
                
                // Border/retention
                if let border = recommendations?.border, !border.isEmpty {
                    dressingCard(
                        title: "Border/Retention",
                        icon: "square.on.square",
                        products: border,
                        color: .orange
                    )
                }
                
                // Instructions and PDF export
                VStack(spacing: 16) {
                    instructionsCard
                    
                    // PDF Export button
                    Button {
                        exportPDF()
                    } label: {
                        Label("Export Complete Report", systemImage: "doc.fill")
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
        .navigationTitle("Dressing Selection")
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
    }
    
    // MARK: - Size Card
    
    private var sizeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Recommended Dressing Sizes", systemImage: "ruler")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let recs = recommendations {
                VStack(spacing: 12) {
                    sizeRow(label: "Wound dimensions", value: recs.woundSize)
                    Divider()
                    sizeRow(label: "Primary dressing", value: recs.primarySize, highlight: true)
                    sizeRow(label: "Secondary dressing", value: recs.secondarySize)
                    sizeRow(label: "Border (if needed)", value: recs.borderSize)
                }
                
                Text("Margins include 2-3cm overlap for adhesion and exudate management")
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
            Label("Application Notes", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("Clean wound bed with normal saline")
                bulletPoint("Apply primary dressing directly to wound")
                bulletPoint("Ensure 2-3cm margin around wound edges")
                bulletPoint("Secure with secondary dressing or border")
                bulletPoint("Change frequency: per product guidelines or when saturated")
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
            Text("•")
                .fontWeight(.bold)
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
            
            print("PDF saved to: \(pdfURL.path)")
            
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
                    Text("PREFERRED")
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
                Text("Examples: \(product.examples.joined(separator: ", "))")
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
    
    enum Priority {
        case preferred, alternative
    }
}

// MARK: - Dressing Engine (Rules-based)

enum DressingEngine {
    static func recommend(measurements: WoundMeasurementResult, assessment: QuestionnairePayload) -> DressingRecommendations {
        
        // Calculate sizes with margins
        let length = measurements.lengthCm
        let width = measurements.widthCm
        
        let primaryLength = Int(ceil(length + 4))
        let primaryWidth = Int(ceil(width + 4))
        let secondaryLength = Int(ceil(length + 6))
        let secondaryWidth = Int(ceil(width + 6))
        let borderLength = Int(ceil(length + 8))
        let borderWidth = Int(ceil(width + 8))
        
        var primary: [DressingProduct] = []
        
        if assessment.tissue == "necrosis" {
            primary.append(DressingProduct(
                name: "Hydrogel Sheet or Gel",
                rationale: "Promotes autolytic debridement of necrotic tissue",
                examples: ["IntraSite Gel", "Purilon Gel", "DuoDERM Hydroactive"],
                priority: .preferred
            ))
        } else if assessment.tissue == "slough" {
            if assessment.moisture == "high" {
                primary.append(DressingProduct(
                    name: "Calcium Alginate",
                    rationale: "High absorbency for sloughy wounds with heavy exudate",
                    examples: ["Kaltostat", "Sorbsan", "Algisite M"],
                    priority: .preferred
                ))
            } else {
                primary.append(DressingProduct(
                    name: "Hydrocolloid or Hydrofiber",
                    rationale: "Supports autolytic debridement while managing moderate exudate",
                    examples: ["DuoDERM Extra Thin", "Aquacel Foam"],
                    priority: .preferred
                ))
            }
        } else if assessment.tissue == "granulation" {
            if assessment.infection == "local" || assessment.infection == "systemic" {
                primary.append(DressingProduct(
                    name: "Silver Foam or Antimicrobial Dressing",
                    rationale: "Manages infection while supporting healing",
                    examples: ["Mepilex Ag", "Aquacel Ag Foam", "Acticoat"],
                    priority: .preferred
                ))
            } else {
                switch assessment.moisture {
                case "dry":
                    primary.append(DressingProduct(
                        name: "Hydrogel Sheet",
                        rationale: "Maintains moist environment for dry granulating wounds",
                        examples: ["IntraSite Gel", "Nu-Gel"],
                        priority: .preferred
                    ))
                case "low":
                    primary.append(DressingProduct(
                        name: "Thin Foam or Hydrocolloid",
                        rationale: "Low absorbency for minimal exudate",
                        examples: ["Mepilex Lite", "DuoDERM Extra Thin"],
                        priority: .preferred
                    ))
                case "moderate":
                    primary.append(DressingProduct(
                        name: "Foam Dressing",
                        rationale: "Balanced absorbency for moderate exudate",
                        examples: ["Mepilex Border", "Allevyn Gentle"],
                        priority: .preferred
                    ))
                case "high":
                    primary.append(DressingProduct(
                        name: "Superabsorbent or Alginate",
                        rationale: "High absorbency for heavily exudating wounds",
                        examples: ["Zetuvit Plus", "Kaltostat", "Aquacel Foam Extra"],
                        priority: .preferred
                    ))
                default:
                    primary.append(DressingProduct(
                        name: "Foam Dressing",
                        rationale: "Versatile option for granulating wounds",
                        examples: ["Mepilex", "Allevyn"],
                        priority: .preferred
                    ))
                }
            }
        }
        
        if (assessment.infection == "local" || assessment.infection == "systemic")
            && !primary.contains(where: { $0.name.contains("Silver") || $0.name.contains("Antimicrobial") }) {
            primary.append(DressingProduct(
                name: "Antimicrobial Dressing (alternative)",
                rationale: "Consider if infection persists",
                examples: ["Acticoat", "Aquacel Ag"],
                priority: .alternative
            ))
        }
        
        var secondary: [DressingProduct] = []
        
        if assessment.etiology == "venous" && assessment.abi == "ge0_8" {
            secondary.append(DressingProduct(
                name: "Compression Bandage System",
                rationale: "Essential for venous ulcer management (ABI >0.8)",
                examples: ["4-layer bandage", "Short-stretch compression"],
                priority: .preferred
            ))
        }
        
        if assessment.moisture == "high" {
            secondary.append(DressingProduct(
                name: "Absorbent Pad",
                rationale: "Additional absorbency for high exudate",
                examples: ["Zetuvit", "Melolin"],
                priority: .preferred
            ))
        }
        
        var border: [DressingProduct] = []
        
        border.append(DressingProduct(
            name: "Film Dressing or Soft Silicone Border",
            rationale: "Secure primary dressing while allowing visual inspection",
            examples: ["Tegaderm", "Mepilex Border", "Opsite Flexigrid"],
            priority: .preferred
        ))
        
        if assessment.etiology == "diabeticFoot" {
            border.append(DressingProduct(
                name: "Offloading Device",
                rationale: "Critical for diabetic foot ulcers - reduces pressure",
                examples: ["Total contact cast", "Removable cast boot", "Felted foam"],
                priority: .preferred
            ))
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
        
        let primaryHTML = dressing.primary.map { p in
            """
            <div class="product">
                <div class="product-name">\(escape(p.name)) \(p.priority == .preferred ? "★" : "")</div>
                <div class="product-rationale">\(escape(p.rationale))</div>
                <div class="product-examples">Examples: \(escape(p.examples.joined(separator: ", ")))</div>
            </div>
            """
        }.joined()
        
        let secondaryHTML = dressing.secondary.isEmpty ? "" : """
        <div class="dressing-section">
            <div class="section-title">Secondary Dressing</div>
            \(dressing.secondary.map { p in
                """
                <div class="product">
                    <div class="product-name">\(escape(p.name))</div>
                    <div class="product-rationale">\(escape(p.rationale))</div>
                </div>
                """
            }.joined())
        </div>
        """
        
        let borderHTML = dressing.border.isEmpty ? "" : """
        <div class="dressing-section">
            <div class="section-title">Border/Retention</div>
            \(dressing.border.map { p in
                """
                <div class="product">
                    <div class="product-name">\(escape(p.name))</div>
                    <div class="product-rationale">\(escape(p.rationale))</div>
                </div>
                """
            }.joined())
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
                <h1>Complete Wound Assessment & Dressing Report</h1>
                <div class="date">\(escape(dateStr))</div>
            </div>
            
            <div class="measurements">
                <h2>Wound Measurements</h2>
                <div class="size-grid">
                    <div class="size-item">
                        <div class="size-label">Wound Size</div>
                        <div class="size-value">\(escape(dressing.woundSize))</div>
                    </div>
                    <div class="size-item">
                        <div class="size-label">Primary Dressing</div>
                        <div class="size-value">\(escape(dressing.primarySize))</div>
                    </div>
                    <div class="size-item">
                        <div class="size-label">Secondary Dressing</div>
                        <div class="size-value">\(escape(dressing.secondarySize))</div>
                    </div>
                    <div class="size-item">
                        <div class="size-label">Border (if needed)</div>
                        <div class="size-value">\(escape(dressing.borderSize))</div>
                    </div>
                </div>
            </div>
            
            <div class="dressing-section">
                <div class="section-title">Primary Dressing</div>
                \(primaryHTML)
            </div>
            
            \(secondaryHTML)
            \(borderHTML)
            
            <div class="instructions">
                <h3>Application Guidelines</h3>
                <ul>
                    <li>Clean wound bed with normal saline</li>
                    <li>Apply primary dressing directly to wound</li>
                    <li>Ensure 2-3cm margin around wound edges</li>
                    <li>Secure with secondary dressing or border</li>
                    <li>Change frequency: per product guidelines or when saturated</li>
                </ul>
            </div>
            
            <div class="footer">
                WoundPilot Report • This document supports clinical judgment and does not replace professional assessment
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
