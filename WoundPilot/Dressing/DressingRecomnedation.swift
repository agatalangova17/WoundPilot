import SwiftUI

struct DressingRecommendationView: View {
    let measurements: WoundMeasurementResult
    let assessment: QuestionnairePayload
    
    @State private var recommendations: DressingRecommendations?
    @State private var animate = false
    
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
                
                // Instructions
                instructionsCard
            }
            .padding()
        }
        .navigationTitle("Dressing Selection")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
        
        let primaryLength = Int(ceil(length + 4)) // 2cm margin each side
        let primaryWidth = Int(ceil(width + 4))
        let secondaryLength = Int(ceil(length + 6))
        let secondaryWidth = Int(ceil(width + 6))
        let borderLength = Int(ceil(length + 8))
        let borderWidth = Int(ceil(width + 8))
        
        // Primary dressing selection
        var primary: [DressingProduct] = []
        
        // Based on tissue type
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
        
        // Secondary dressing
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
        
        // Border/Retention
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
        
        // Return complete struct with all required parameters
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
