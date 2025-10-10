import SwiftUI

struct DressingRecommendationView: View {
    let measurements: WoundMeasurementResult
    let assessment: QuestionnairePayload
    let context: QuestionnaireContext

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var recommendations: DressingRecommendations?
    @State private var animate = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Allergy warnings if present
                if hasRelevantAllergies {
                    allergyWarningCard
                }
                
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

                // Instructions
                VStack(spacing: 16) {
                    instructionsCard

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

    // MARK: - Allergy Warning
    
    private var hasRelevantAllergies: Bool {
        context.allergyToAdhesives == true ||
        context.allergyToIodine == true ||
        context.allergyToSilver == true ||
        context.allergyToLatex == true ||
        (context.otherAllergies != nil && !context.otherAllergies!.isEmpty)
    }
    
    private var allergyWarningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("⚠️ Known Allergies", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 6) {
                if context.allergyToAdhesives == true {
                    Text("• Adhesives - use silicone-based products")
                }
                if context.allergyToIodine == true {
                    Text("• Iodine - avoid iodine-based antimicrobials")
                }
                if context.allergyToSilver == true {
                    Text("• Silver - avoid silver dressings, use PHMB or honey alternatives")
                }
                if context.allergyToLatex == true {
                    Text("• Latex - ensure all products are latex-free")
                }
                if let other = context.otherAllergies, !other.isEmpty {
                    Text("• Other: \(other)")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
    }

    // MARK: - Size Card

    private var sizeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Recommended Dressing Sizes", systemImage: "ruler")
                .font(.headline)
                .foregroundColor(.primary)

            if let recs = recommendations {
                VStack(spacing: 12) {
                    sizeRow(label: "Wound Dimensions", value: recs.woundSize)
                    Divider()
                    sizeRow(label: "Primary Dressing", value: recs.primarySize, highlight: true)
                    sizeRow(label: "Secondary Dressing", value: recs.secondarySize)
                    sizeRow(label: "Border (if needed)", value: recs.borderSize)
                }

                Text("Sizes calculated with appropriate margins for dressing type")
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
                bulletPoint("Clean wound with normal saline")
                bulletPoint("Apply primary dressing directly to wound bed")
                bulletPoint("Ensure adequate margin around wound edges")
                bulletPoint("Secure with appropriate secondary/border dressing")
                bulletPoint("Change frequency: as per product guidance or when strike-through occurs")
                
                if assessment.hasDeepSpaces {
                    bulletPoint("⚠️ Pack deep spaces loosely - do not overfill")
                }
                
                if assessment.infectionSeverity != .none {
                    bulletPoint("⚠️ Monitor for signs of worsening infection")
                }
                
                if assessment.dominantTissueType == "necrosis" && assessment.infectionSeverity != .none {
                    bulletPoint("⚠️ Antimicrobial coverage essential - do not use plain hydrogel alone")
                }
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
                dressing: recs,
                context: context
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
            assessment: assessment,
            context: context
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
                    Text("Preferred")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                }
                if product.allergyWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .imageScale(.small)
                }
            }

            Text(product.rationale)
                .font(.caption)
                .foregroundColor(.secondary)

            if !product.examples.isEmpty {
                let line = "Examples: \(product.examples.joined(separator: ", "))"
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
    let allergyWarning: Bool

    enum Priority { case preferred, alternative }
}

// MARK: - CORRECTED Dressing Engine with Infection-First Logic

enum DressingEngine {
    static func recommend(
        measurements: WoundMeasurementResult,
        assessment: QuestionnairePayload,
        context: QuestionnaireContext
    ) -> DressingRecommendations {

        let length = measurements.lengthCm
        let width = measurements.widthCm
        let dominantTissue = assessment.dominantTissueType
        let hasInfection = assessment.infectionSeverity != .none

        // Calculate sizes (simplified - use 2cm margin for most products)
        let primaryMargin: Float = 2.0
        let primaryLength = Int(ceil(length + primaryMargin))
        let primaryWidth  = Int(ceil(width + primaryMargin))
        let secondaryLength = Int(ceil(length + primaryMargin + 2))
        let secondaryWidth  = Int(ceil(width + primaryMargin + 2))
        let borderLength = Int(ceil(length + primaryMargin + 4))
        let borderWidth  = Int(ceil(width + primaryMargin + 4))

        var primary: [DressingProduct] = []
        
        // ====================================================================
        // CRITICAL: INFECTION-FIRST LOGIC
        // If wound is infected, antimicrobial coverage is PRIORITY #1
        // ====================================================================
        
        if hasInfection {
            // INFECTED WOUNDS - need antimicrobial coverage
            
            if dominantTissue == "necrosis" {
                // INFECTED NECROTIC WOUND - needs antimicrobial + autolytic debridement
                
                // Option 1: Medical Grade Honey (works on both infection AND necrosis)
                primary.append(
                    DressingProduct(
                        name: "Medical Grade Manuka Honey",
                        rationale: "Broad-spectrum antimicrobial AND promotes autolytic debridement of necrotic tissue. Dual action addresses both infection and devitalized tissue.",
                        examples: ["Medihoney", "Activon", "Manukamed"],
                        priority: .preferred,
                        allergyWarning: false
                    )
                )
                
                // Option 2: Cadexomer Iodine (if no iodine allergy)
                if context.allergyToIodine != true {
                    primary.append(
                        DressingProduct(
                            name: "Cadexomer Iodine Paste",
                            rationale: "Antimicrobial coverage for infection while promoting autolytic debridement",
                            examples: ["Iodosorb", "Iodoflex"],
                            priority: .preferred,
                            allergyWarning: false
                        )
                    )
                }
                
                // Option 3: Silver Alginate (if no silver allergy)
                if context.allergyToSilver != true {
                    primary.append(
                        DressingProduct(
                            name: "Silver Alginate",
                            rationale: "Antimicrobial silver with high absorbency and autolytic properties",
                            examples: ["Aquacel Ag", "Silvercel"],
                            priority: .alternative,
                            allergyWarning: false
                        )
                    )
                }
                
            } else if dominantTissue == "slough" {
                // INFECTED SLOUGHY WOUND
                
                // Option 1: Medical honey
                primary.append(
                    DressingProduct(
                        name: "Medical Grade Manuka Honey",
                        rationale: "Antimicrobial action with autolytic debridement for infected sloughy tissue",
                        examples: ["Medihoney", "Activon"],
                        priority: .preferred,
                        allergyWarning: false
                    )
                )
                
                // Option 2: Silver foam/hydrofiber
                if context.allergyToSilver != true {
                    if assessment.exudate == "high" {
                        primary.append(
                            DressingProduct(
                                name: "Silver Hydrofiber",
                                rationale: "High absorbency antimicrobial for infected wound with slough",
                                examples: ["Aquacel Ag", "Aquacel Ag Extra"],
                                priority: .preferred,
                                allergyWarning: false
                            )
                        )
                    } else {
                        primary.append(
                            DressingProduct(
                                name: "Silver Foam",
                                rationale: "Antimicrobial foam for infected sloughy wound",
                                examples: ["Mepilex Ag", "Allevyn Ag"],
                                priority: .alternative,
                                allergyWarning: context.allergyToAdhesives == true
                            )
                        )
                    }
                }
                
                // Option 3: PHMB (if silver allergy)
                if context.allergyToSilver == true {
                    primary.append(
                        DressingProduct(
                            name: "PHMB Antimicrobial Foam",
                            rationale: "Antimicrobial without silver (patient has silver allergy)",
                            examples: ["Kendall AMD", "Biatain PHMB"],
                            priority: .preferred,
                            allergyWarning: false
                        )
                    )
                }
                
            } else {
                // INFECTED GRANULATION TISSUE
                
                // Option 1: Medical honey
                primary.append(
                    DressingProduct(
                        name: "Medical Grade Manuka Honey",
                        rationale: "Antimicrobial for infected granulating wound, promotes healing",
                        examples: ["Medihoney", "Activon"],
                        priority: .preferred,
                        allergyWarning: false
                    )
                )
                
                // Option 2: Silver foam
                if context.allergyToSilver != true {
                    primary.append(
                        DressingProduct(
                            name: "Silver Foam Dressing",
                            rationale: "Antimicrobial action for infected granulating wound",
                            examples: ["Mepilex Ag", "Aquacel Ag Foam", "Allevyn Ag"],
                            priority: .preferred,
                            allergyWarning: context.allergyToAdhesives == true
                        )
                    )
                }
                
                // Option 3: PHMB (if silver allergy)
                if context.allergyToSilver == true {
                    primary.append(
                        DressingProduct(
                            name: "PHMB Antimicrobial Foam",
                            rationale: "Antimicrobial without silver (patient has silver allergy)",
                            examples: ["Kendall AMD", "Biatain PHMB"],
                            priority: .preferred,
                            allergyWarning: false
                        )
                    )
                }
            }
            
        } else {
            // NO INFECTION - Select based on tissue type and exudate
            
            if dominantTissue == "necrosis" {
                // CLEAN NECROTIC WOUND - autolytic debridement
                
                primary.append(
                    DressingProduct(
                        name: "Hydrogel",
                        rationale: "Autolytic debridement - softens and rehydrates necrotic tissue",
                        examples: ["IntraSite Gel", "Purilon Gel", "Nu-Gel"],
                        priority: .preferred,
                        allergyWarning: false
                    )
                )
                
                // Alternative: Medical honey (also good for clean necrotic wounds)
                primary.append(
                    DressingProduct(
                        name: "Medical Grade Manuka Honey",
                        rationale: "Natural autolytic debridement with anti-inflammatory properties",
                        examples: ["Medihoney", "Activon"],
                        priority: .alternative,
                        allergyWarning: false
                    )
                )
                
            } else if dominantTissue == "slough" {
                // CLEAN SLOUGHY WOUND
                
                if assessment.exudate == "high" {
                    primary.append(
                        DressingProduct(
                            name: "Alginate",
                            rationale: "High absorbency while promoting autolytic debridement",
                            examples: ["Kaltostat", "Sorbsan", "Algisite M"],
                            priority: .preferred,
                            allergyWarning: false
                        )
                    )
                } else {
                    primary.append(
                        DressingProduct(
                            name: "Hydrofiber or Hydrocolloid",
                            rationale: "Maintains moist environment for autolytic debridement",
                            examples: ["Aquacel", "DuoDERM CGF"],
                            priority: .preferred,
                            allergyWarning: context.allergyToAdhesives == true
                        )
                    )
                }
                
            } else if dominantTissue == "granulation" {
                // CLEAN GRANULATING WOUND - select by exudate level
                
                switch assessment.exudate {
                case "dry":
                    primary.append(
                        DressingProduct(
                            name: "Hydrogel Sheet",
                            rationale: "Hydrates dry wound bed to support cell migration",
                            examples: ["IntraSite Conformable", "Nu-Gel"],
                            priority: .preferred,
                            allergyWarning: false
                        )
                    )
                    
                case "low":
                    primary.append(
                        DressingProduct(
                            name: "Thin Foam or Hydrocolloid",
                            rationale: "Low absorbency for minimal exudate",
                            examples: ["Mepilex Lite", "DuoDERM Extra Thin"],
                            priority: .preferred,
                            allergyWarning: context.allergyToAdhesives == true
                        )
                    )
                    
                case "moderate":
                    primary.append(
                        DressingProduct(
                            name: "Foam Dressing",
                            rationale: "Balanced absorbency maintains optimal moisture",
                            examples: ["Mepilex Border", "Allevyn Gentle"],
                            priority: .preferred,
                            allergyWarning: context.allergyToAdhesives == true
                        )
                    )
                    
                case "high":
                    primary.append(
                        DressingProduct(
                            name: "Superabsorbent or Alginate",
                            rationale: "High absorbency for heavy exudate management",
                            examples: ["Zetuvit Plus", "Kaltostat", "Aquacel Foam Extra"],
                            priority: .preferred,
                            allergyWarning: false
                        )
                    )
                    
                default:
                    primary.append(
                        DressingProduct(
                            name: "Foam Dressing",
                            rationale: "Versatile option for granulating wounds",
                            examples: ["Mepilex", "Allevyn"],
                            priority: .preferred,
                            allergyWarning: context.allergyToAdhesives == true
                        )
                    )
                }
                
            } else if dominantTissue == "epithelializing" {
                // EPITHELIALIZING WOUND - protect new tissue
                
                primary.append(
                    DressingProduct(
                        name: "Thin Film or Hydrocolloid",
                        rationale: "Protect new epithelial tissue while allowing moisture vapor transmission",
                        examples: ["Tegaderm", "DuoDERM Extra Thin", "Opsite"],
                        priority: .preferred,
                        allergyWarning: context.allergyToAdhesives == true
                    )
                )
            }
        }

        // ====================================================================
        // SECONDARY DRESSINGS
        // ====================================================================
        
        var secondary: [DressingProduct] = []

        // Compression for venous wounds (if perfusion adequate)
        if context.hasVenousDisease == true {
            if assessment.abi == "ge0_8" {
                secondary.append(
                    DressingProduct(
                        name: "Full Compression (30-40mmHg)",
                        rationale: "Essential for venous ulcer healing - improves venous return",
                        examples: ["4-layer bandage", "Short-stretch bandage", "Compression hosiery"],
                        priority: .preferred,
                        allergyWarning: context.allergyToLatex == true
                    )
                )
            } else if assessment.abi == "p0_5to0_79" {
                secondary.append(
                    DressingProduct(
                        name: "Reduced Compression (20-30mmHg)",
                        rationale: "Modified compression due to reduced arterial supply - requires close monitoring",
                        examples: ["Modified compression bandage", "Light compression hosiery"],
                        priority: .preferred,
                        allergyWarning: context.allergyToLatex == true
                    )
                )
            }
            // If ABI <0.5 or unknown, compression is contraindicated (not added)
        }

        // Absorbent pad for high exudate
        if assessment.exudate == "high" {
            secondary.append(
                DressingProduct(
                    name: "Absorbent Pad",
                    rationale: "Additional exudate management to protect periwound skin",
                    examples: ["Zetuvit", "Melolin", "ABD pad"],
                    priority: .preferred,
                    allergyWarning: false
                )
            )
        }

        // ====================================================================
        // BORDER/RETENTION + OFFLOADING
        // ====================================================================
        
        var border: [DressingProduct] = []

        // Border/retention dressing
        if context.allergyToAdhesives == true {
            border.append(
                DressingProduct(
                    name: "Silicone Border or Retention Bandage",
                    rationale: "Gentle fixation without adhesive (patient has adhesive allergy)",
                    examples: ["Mepilex Border (silicone)", "Retention bandage", "Tubular net"],
                    priority: .preferred,
                    allergyWarning: false
                )
            )
        } else {
            border.append(
                DressingProduct(
                    name: "Film Dressing or Self-Adherent Border",
                    rationale: "Secure primary dressing and protect from external contamination",
                    examples: ["Tegaderm", "Opsite Flexigrid", "Mepilex Border"],
                    priority: .preferred,
                    allergyWarning: false
                )
            )
        }

        // CRITICAL: Offloading for diabetic foot ulcers
        if context.hasDiabetes == true && context.isFootLocation {
            border.append(
                DressingProduct(
                    name: "Offloading Device (ESSENTIAL)",
                    rationale: "Mandatory for diabetic foot ulcer healing - eliminates pressure at wound site",
                    examples: ["Total contact cast (gold standard)", "Removable cast boot", "Felted foam offloading"],
                    priority: .preferred,
                    allergyWarning: false
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
        dressing: DressingRecommendations,
        context: QuestionnaireContext
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
                \(p.examples.isEmpty ? "" : "<div class=\"product-examples\">Examples: \(escape(p.examples.joined(separator: ", ")))</div>")
            </div>
            """
        }

        let primaryHTML = dressing.primary.map { productHTML($0, showStar: true) }.joined()

        let secondaryHTML = dressing.secondary.isEmpty ? "" : """
        <div class="dressing-section">
            <div class="section-title">Secondary Dressing</div>
            \(dressing.secondary.map { productHTML($0) }.joined())
        </div>
        """

        let borderHTML = dressing.border.isEmpty ? "" : """
        <div class="dressing-section">
            <div class="section-title">Border/Retention</div>
            \(dressing.border.map { productHTML($0) }.joined())
        </div>
        """
        
        let allergyHTML = context.allergyToAdhesives == true ||
                          context.allergyToSilver == true ||
                          context.allergyToIodine == true ||
                          context.allergyToLatex == true ? """
        <div class="alert">
            <h3>⚠️ Known Allergies</h3>
            <ul>
                \(context.allergyToAdhesives == true ? "<li>Adhesives - use silicone products</li>" : "")
                \(context.allergyToSilver == true ? "<li>Silver - use PHMB or honey alternatives</li>" : "")
                \(context.allergyToIodine == true ? "<li>Iodine - avoid iodine-based products</li>" : "")
                \(context.allergyToLatex == true ? "<li>Latex - ensure latex-free products</li>" : "")
            </ul>
        </div>
        """ : ""

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

            .alert {
                background: #ffe5e5; border-left: 4pt solid #ff0000;
                padding: 12pt; margin: 12pt 0; border-radius: 6pt;
            }
            .alert h3 { margin: 0 0 8pt 0; color: #c00; font-size: 12pt; }
            .alert ul { margin: 4pt 0 0 16pt; padding: 0; }
            .alert li { margin: 4pt 0; font-size: 10pt; }

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
                <h1>Dressing Recommendation Report</h1>
                <div class="date">\(escape(dateStr))</div>
            </div>

            \(allergyHTML)

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
                        <div class="size-label">Secondary</div>
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
                    <li>Clean wound with normal saline</li>
                    <li>Apply primary dressing directly to wound bed</li>
                    <li>Ensure adequate margin around wound edges</li>
                    <li>Secure with appropriate secondary/border dressing</li>
                    <li>Change frequency: as per product guidance or when strike-through</li>
                    \(assessment.hasDeepSpaces ? "<li><strong>Pack deep spaces loosely - do not overfill</strong></li>" : "")
                    \(assessment.infectionSeverity != .none ? "<li><strong>Monitor for worsening infection signs</strong></li>" : "")
                </ul>
            </div>

            <div class="footer">
                This recommendation supports clinical judgment and should be adapted based on individual patient needs, product availability, and local protocols.
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
