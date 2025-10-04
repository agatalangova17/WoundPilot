import SwiftUI
import FirebaseFirestore
import UIKit

// =====================================================
// MARK: - Models used by the analysis view (public)
// =====================================================

struct QuestionnairePayload {
    let etiology: String
    let duration: String
    let tissue: String
    let exposedBone: Bool
    let infection: String
    let probeToBone: Bool
    let moisture: String
    let edge: String
    let abi: String
    let pulses: String
    let comorbidities: Set<String>
    let redFlags: Set<String>

    static func from(_ dict: [String: Any]) -> QuestionnairePayload {
        func s(_ key: String) -> String { (dict[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown" }
        func b(_ key: String) -> Bool { dict[key] as? Bool ?? false }
        func arr(_ key: String) -> Set<String> { Set(dict[key] as? [String] ?? []) }

        return QuestionnairePayload(
            etiology: s("etiology"),
            duration: s("duration"),
            tissue: s("tissue"),
            exposedBone: b("exposedBone"),
            infection: s("infection"),
            probeToBone: b("probeToBone"),
            moisture: s("moisture"),
            edge: s("edge"),
            abi: s("abi"),
            pulses: s("pulses"),
            comorbidities: arr("comorbidities"),
            redFlags: arr("redFlags")
        )
    }
}

struct AIReport {
    let diagnosis: String
    let woundType: String
    let healingStage: String
    let woundStage: String
    let etiologyLine: String
    let recommendations: [String]
    let banners: [String]
}

// =====================================================
// MARK: - Rules Engine (uses only public LocalizedStrings)
// =====================================================

enum Rec: Hashable {
    case cleanse, protectPeriwound
    case compressionFull, compressionAvoidHigh, compressionContra
    case debrideEpibole, packUndermining
    case moistureDryHydrogel, moistureModerateFoam, moistureHighAlginate
    case elevationAndMobility, venousEducation
    case arterialNoDebridementUntilPerfused, arterialVascularReferral, arterialPainSupport
    case dfuOffloading, dfuOsteoWorkup, antibioticsIfInfected, glycemicControl, footwearReview
    case followUp7d, closeReview48h
    case immunoCloserReview, anticoagBleedingRisk
}

struct RulesEngine {
    static func analyze(_ q: QuestionnairePayload) -> AIReport {
        let woundType   = LocalizedStrings.mapWoundTypeLabel(for: q.etiology)
        let healingStage = LocalizedStrings.mapHealingStageLabel(for: q.tissue)
        let woundStage  = mapWoundStage(q)
        let diagnosis   = mapDiagnosis(etiology: q.etiology, duration: q.duration, abi: q.abi, infection: q.infection)
        let etiologyLine = LocalizedStrings.mapEtiologyLine(for: q.etiology)

        var banners: [String] = []
        if q.infection == "systemic"
            || q.redFlags.contains("systemicUnwell")
            || q.redFlags.contains("crepitus")
            || q.redFlags.contains("spreadingErythema") {
            banners.append(LocalizedStrings.bannerUrgentAssessment)
        }
        if q.abi == "lt0_5" {
            banners.append(LocalizedStrings.bannerSevereIschaemia)
        }

        var recs: [Rec] = [.cleanse, .protectPeriwound]

        switch q.etiology {
        case "venous":
            if q.abi == "ge0_8" { recs.append(.compressionFull) }
            else if q.abi == "p0_5to0_79" { recs.append(.compressionAvoidHigh) }
            else if q.abi == "lt0_5" { recs.append(.compressionContra) }
            recs += [.elevationAndMobility, .venousEducation]

        case "arterial":
            recs += [.arterialVascularReferral, .arterialNoDebridementUntilPerfused, .arterialPainSupport, .compressionContra]

        case "diabeticFoot":
            recs += [.dfuOffloading, .glycemicControl, .footwearReview]
            if q.probeToBone { recs.append(.dfuOsteoWorkup) }
            if q.infection == "local" || q.infection == "systemic" { recs.append(.antibioticsIfInfected) }

        case "pressure":
            recs.append(.dfuOffloading)

        default: break
        }

        switch q.moisture {
        case "dry":      recs.append(.moistureDryHydrogel)
        case "moderate": recs.append(.moistureModerateFoam)
        case "high":     recs.append(.moistureHighAlginate)
        default: break
        }

        if q.edge == "rolled"     { recs.append(.debrideEpibole) }
        if q.edge == "undermined" { recs.append(.packUndermining) }

        if q.comorbidities.contains("immunosuppressed") { recs.append(.immunoCloserReview) }
        if q.comorbidities.contains("anticoagulants")   { recs.append(.anticoagBleedingRisk) }

        if q.etiology == "arterial" || q.infection == "systemic" { recs.append(.closeReview48h) }
        else { recs.append(.followUp7d) }

        let recoText = dedupePreserveOrder(recs).map { LocalizedStrings.recommendationText($0) }

        return AIReport(
            diagnosis: diagnosis,
            woundType: woundType,
            healingStage: healingStage,
            woundStage: woundStage,
            etiologyLine: etiologyLine,
            recommendations: recoText,
            banners: banners
        )
    }

    private static func mapWoundStage(_ q: QuestionnairePayload) -> String {
        if q.etiology == "diabeticFoot", q.probeToBone {
            return LocalizedStrings.woundStageWagnerSuspected
        }
        return LocalizedStrings.woundStageNotStaged
    }

    private static func mapDiagnosis(etiology: String, duration: String, abi: String, infection: String) -> String {
        if etiology == "arterial" && abi == "lt0_5" { return LocalizedStrings.dxArterialCLI }
        if etiology == "venous" && (duration == "w4to12" || duration == "gt12w") { return LocalizedStrings.sampleDiagnosis }
        if etiology == "diabeticFoot" && infection == "local" { return LocalizedStrings.dxDFULocalInfection }
        return LocalizedStrings.mapDiagnosisGeneric(for: etiology)
    }

    private static func dedupePreserveOrder<T: Hashable>(_ items: [T]) -> [T] {
        var seen = Set<T>(); var out: [T] = []
        for i in items where !seen.contains(i) { seen.insert(i); out.append(i) }
        return out
    }
}

// =====================================================
// MARK: - Analysis View (polished UI + pretty PDF with photo)
// =====================================================

struct ReportView: View {
    @ObservedObject var langManager = LocalizationManager.shared

    let woundGroupId: String
    let patientId: String
    let heroImage: UIImage?
    var isQuickScan: Bool = false
    var quickScanPayload: QuestionnairePayload? = nil
    var measurementResult: WoundMeasurementResult? = nil
    
    @State private var loading = true
    @State private var report: AIReport?
    @State private var payload: QuestionnairePayload?
    @State private var errorMessage: String?
    @State private var animate = false
    @State private var goToDressing = false

    // Sharing
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    init(woundGroupId: String,
         patientId: String,
         heroImage: UIImage? = nil,
         isQuickScan: Bool = false,
         quickScanPayload: QuestionnairePayload? = nil,
         measurementResult: WoundMeasurementResult? = nil) {
        self.woundGroupId = woundGroupId
        self.patientId = patientId
        self.heroImage = heroImage
        self.isQuickScan = isQuickScan
        self.quickScanPayload = quickScanPayload
        self.measurementResult = measurementResult
    }

    var body: some View {
        Group {
            if loading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(LocalizedStrings.preparingAnalysis)
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())

            } else if let report {
                ScrollView {
                    VStack(spacing: 16) {

                        // Quick scan banner
                        if isQuickScan {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.blue)
                                Text("Quick Scan - Not saved to patient records")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }

                        // Banners
                        ForEach(report.banners, id: \.self) { text in
                            AlertBanner(text: text, style: .danger)
                                .padding(.horizontal)
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 10)
                                .animation(.easeOut(duration: 0.35), value: animate)
                        }

                        // Hero header
                        HeroHeader(
                            title: LocalizedStrings.analysisReportTitle,
                            diagnosisTitle: LocalizedStrings.diagnosisField,
                            diagnosis: report.diagnosis,
                            chips: [
                                .init(icon: "bandage.fill",         title: LocalizedStrings.woundTypeField,    value: report.woundType),
                                .init(icon: "waveform.path.ecg",    title: LocalizedStrings.healingStageField, value: report.healingStage),
                                .init(icon: "chart.bar.fill",       title: LocalizedStrings.woundStageField,   value: report.woundStage)
                            ],
                            stageLabel: report.woundStage,
                            stageProgress: stageProgress(for: report.healingStage)
                        )
                        .padding(.horizontal)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 12)
                        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: animate)

                        // Etiology
                        InfoTile(title: LocalizedStrings.etiologyField,
                                 systemImage: "heart.text.square.fill",
                                 content: report.etiologyLine)
                        .padding(.horizontal)

                        // Recommendations grid
                        RecommendationsGrid(
                            title: LocalizedStrings.recommendedTreatment,
                            items: report.recommendations,
                            iconProvider: iconForRecommendation(_:)
                        )
                        .padding(.horizontal)

                        // Dressing recommendation button
                        Button {
                            goToDressing = true
                        } label: {
                            Label("Select Dressings", systemImage: "bandage.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.green)
                                )
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 8)
                }
                .onAppear { animate = true }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .sheet(isPresented: $showShare) {
                    ActivityView(items: shareItems)
                }
                .navigationDestination(isPresented: $goToDressing) {
                    if let payload = payload, let measurements = measurementResult {
                        DressingRecommendationView(
                            measurements: measurements,
                            assessment: payload
                        )
                    }
                }

            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text(errorMessage ?? LocalizedStrings.failedToLoadAnalysis)
                        .foregroundColor(.secondary)
                    Button(LocalizedStrings.retryAction) { loadReport() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadReport() }
    }

    // Firestore -> Report or Quick Scan in-memory
    private func loadReport() {
        loading = true
        errorMessage = nil

        // Quick scan mode - use in-memory data
        if isQuickScan, let payload = quickScanPayload {
            self.payload = payload
            self.report = RulesEngine.analyze(payload)
            self.loading = false
            return
        }

        // Patient mode - fetch from Firestore
        Firestore.firestore()
            .collection("woundGroups")
            .document(woundGroupId)
            .getDocument { snap, err in
                if let err = err {
                    loading = false
                    errorMessage = err.localizedDescription
                    return
                }
                guard let data = snap?.data(),
                      let q = data["questionnaire"] as? [String: Any] else {
                    loading = false
                    errorMessage = LocalizedStrings.noQuestionnaireFound
                    return
                }

                let payload = QuestionnairePayload.from(q)
                self.payload = payload
                self.report = RulesEngine.analyze(payload)
                self.loading = false
            }
    }

    // MARK: - PDF

    private func exportPDF() {
        guard let report else { return }
        
        do {
            let pdfData = try PDFComposer.make(
                report: report,
                payload: payload,
                patientId: patientId,
                woundGroupId: woundGroupId,
                heroImage: heroImage
            )
            
            // Save to Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "WoundReport_\(Date().timeIntervalSince1970).pdf"
            let pdfURL = documentsPath.appendingPathComponent(fileName)
            
            try pdfData.write(to: pdfURL, options: .atomic)
            
            print("PDF saved to: \(pdfURL.path)")
            print("File exists: \(FileManager.default.fileExists(atPath: pdfURL.path))")
            
            // Share the URL
            shareItems = [pdfURL]
            showShare = true
            
        } catch {
            print("PDF generation error: \(error)")
            errorMessage = "Failed to create PDF: \(error.localizedDescription)"
        }
    }

    // Visual progress for ring based on healing stage
    private func stageProgress(for healing: String) -> Double {
        let l = healing.lowercased()
        if l.contains("granul") { return 0.75 }
        if l.contains("slough") || l.contains("inflam") { return 0.45 }
        if l.contains("necrot") || l.contains("isch") { return 0.2 }
        return 0.35
    }

    // Icon mapping for recommendation cards
    private func iconForRecommendation(_ text: String) -> String {
        let t = text.lowercased()

        if t.contains("clean") || t.contains("saline") { return "drop.fill" }
        if t.contains("peri-wound") || t.contains("barrier") { return "shield.lefthalf.fill" }

        if t.contains("compression") && t.contains("contra") { return "nosign" }
        if t.contains("compression") { return "arrow.up.and.down.circle.fill" }

        if t.contains("elevate") || t.contains("calf") { return "arrow.up.right.circle.fill" }

        if t.contains("foam") { return "square.grid.2x2.fill" }
        if t.contains("alginate") || t.contains("absorptive") { return "waveform.path.ecg" }
        if t.contains("hydrogel") || t.contains("rehydrat") { return "drop.circle.fill" }

        if t.contains("rolled edges") || t.contains("epibole") || t.contains("debrid") { return "scissors" }
        if t.contains("pack") || t.contains("tunnel") { return "cube.box.fill" }

        if t.contains("vascular") || t.contains("revascular") { return "heart.text.square.fill" }
        if t.contains("analgesi") || t.contains("pain") { return "cross.case.fill" }

        if t.contains("off") && t.contains("load") { return "figure.walk.circle.fill" }
        if t.contains("osteomyelitis") { return "doc.text.magnifyingglass" }

        if t.contains("antibiot") { return "pills.fill" }
        if t.contains("glycemic") || t.contains("diabet") { return "staroflife.fill" }
        if t.contains("footwear") || t.contains("devices") { return "figure.walk" }

        if t.contains("24") || t.contains("72") { return "clock.fill" }
        if t.contains("7") && t.contains("day") { return "calendar" }

        if t.contains("immunosuppressed") { return "exclamationmark.triangle.fill" }
        if t.contains("anticoagulant") || t.contains("bleeding") { return "bandage.fill" }

        return "checkmark.circle"
    }
}

// =====================================================
// MARK: - PDF Composer (HTML -> A4, photo + details, page footer)
// =====================================================

private enum PDFComposer {
    static func make(report: AIReport,
                     payload: QuestionnairePayload?,
                     patientId: String,
                     woundGroupId: String,
                     heroImage: UIImage?) throws -> Data {

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let dateStr = df.string(from: Date())

        let imageHTML: String = {
            guard let ui = heroImage, let data = ui.jpegData(compressionQuality: 0.85) else { return "" }
            let b64 = data.base64EncodedString()
            return """
            <div class="photo-card">
                <div class="photo-meta">Wound Photo</div>
                <img class="photo" src="data:image/jpeg;base64,\(b64)" />
            </div>
            """
        }()

        let bannerHTML = report.banners.map { b in
            "<div class='banner danger'>\(escape(b))</div>"
        }.joined()

        let chipsHTML = """
        <div class="chips">
            <div class="chip"><span>\(escape(LocalizedStrings.woundTypeField))</span>\(escape(report.woundType))</div>
            <div class="chip"><span>\(escape(LocalizedStrings.healingStageField))</span>\(escape(report.healingStage))</div>
            <div class="chip"><span>\(escape(LocalizedStrings.woundStageField))</span>\(escape(report.woundStage))</div>
        </div>
        """

        let recsHTML = report.recommendations.enumerated().map { (i, r) in
            "<li><span class='num'>\(i+1)</span><div>\(escape(r))</div></li>"
        }.joined()

        let etiologyHTML = """
        <div class="card">
            <div class="card-title">\(escape(LocalizedStrings.etiologyField))</div>
            <div class="card-body">\(escape(report.etiologyLine))</div>
        </div>
        """

        let detailsHTML: String = {
            guard let q = payload else { return "" }
            func yesNo(_ b: Bool) -> String { b ? LocalizedStrings.optYes : LocalizedStrings.optNo }
            func join(_ s: Set<String>) -> String { s.isEmpty ? "—" : s.joined(separator: ", ") }

            let rows: [(String, String)] = [
                (LocalizedStrings.secEtiology, LocalizedStrings.mapWoundTypeLabel(for: q.etiology)),
                (LocalizedStrings.secDuration, prettyDuration(q.duration)),
                (LocalizedStrings.secTissue,   LocalizedStrings.mapHealingStageLabel(for: q.tissue)),
                (LocalizedStrings.secInfection, prettyInfection(q.infection)),
                (LocalizedStrings.secMoisture, prettyMoisture(q.moisture)),
                (LocalizedStrings.secEdge,     prettyEdge(q.edge)),
                ("ABI",                         prettyABI(q.abi)),
                (LocalizedStrings.rowPulses,    q.pulses.capitalized),
                (LocalizedStrings.rowExposedBone, yesNo(q.exposedBone)),
                (LocalizedStrings.rowProbeToBone, yesNo(q.probeToBone)),
                (LocalizedStrings.secComorbidities, join(q.comorbidities)),
                (LocalizedStrings.secRedFlags,      join(q.redFlags))
            ]

            let trs = rows.map { "<tr><th>\(escape($0.0))</th><td>\(escape($0.1))</td></tr>" }.joined()
            return """
            <div class="card">
                <div class="card-title">Clinical Details</div>
                <table class="kv">
                    \(trs)
                </table>
            </div>
            """
        }()

        let html = """
        <html>
        <head>
        <meta name="viewport" content="initial-scale=1.0"/>
        <style>
            @page { size: A4; margin: 28pt; }
            body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro', 'Helvetica Neue', Arial, sans-serif; color:#111; }

            .header {
                background: linear-gradient(135deg, rgba(10,132,255,0.98), rgba(10,132,255,0.86));
                color: #fff; border-radius: 14pt; padding: 16pt; margin-bottom: 12pt;
                box-shadow: 0 7pt 18pt rgba(0,0,0,0.15);
            }
            .header .title { font-weight: 700; letter-spacing: .2px; margin-bottom: 6pt; }
            .header .diag-label { font-size: 9pt; opacity: .9; font-weight: 600; }
            .header .diag { font-size: 16pt; font-weight: 800; margin: 2pt 0 8pt; }
            .chips { display: grid; grid-template-columns: repeat(3, 1fr); gap: 6pt; }
            .chip { background: rgba(255,255,255,.18); color: #fff; border-radius: 10pt; padding: 8pt 10pt; font-size: 9pt; font-weight: 700; }
            .chip span { display:block; font-size:8pt; opacity:.9; font-weight:700; margin-bottom:2pt; }
            .meta { display:flex; gap:12pt; margin-top: 6pt; font-size: 9pt; opacity: .95; }

            .banner { padding: 10pt 12pt; border-radius: 10pt; font-weight: 700; margin: 10pt 0; }
            .danger { color: #b00020; background: rgba(176,0,32,.12); }

            .photo-card { margin: 12pt 0; background: #fff; border: 1px solid rgba(0,0,0,.08); border-radius: 12pt; overflow:hidden; }
            .photo-meta { padding: 8pt 10pt; font-size: 10pt; font-weight: 700; color:#666; background: #f7f8fa; border-bottom:1px solid rgba(0,0,0,.06); }
            .photo { width: 100%; height: auto; display:block; }

            .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 10pt; }
            .card { background: #f6f7f9; border: 1px solid rgba(0,0,0,.06); border-radius: 12pt; padding: 12pt; }
            .card-title { font-size: 10pt; font-weight: 800; color: #666; margin-bottom: 6pt; }
            .card-body { font-size: 11pt; }

            .kv { width:100%; border-collapse: collapse; }
            .kv th { text-align:left; color:#666; font-size: 9pt; padding: 6pt 8pt; width: 42%; border-bottom:1px solid rgba(0,0,0,.05); }
            .kv td { font-size: 10pt; padding: 6pt 8pt; border-bottom:1px solid rgba(0,0,0,.05); }

            .recs ol { margin: 0; padding-left: 0; list-style: none; }
            .recs li { display:grid; grid-template-columns: 18pt auto; align-items: start; gap: 8pt; margin: 6pt 0; }
            .recs .num { display:inline-grid; place-items:center; width: 18pt; height: 18pt; font-weight: 800; color: #fff; background: #0a84ff; border-radius: 50%; font-size: 9pt; }

            .footer { margin-top: 14pt; font-size: 8pt; color: #666; }
        </style>
        </head>
        <body>
            <div class="header">
                <div class="title">\(escape(LocalizedStrings.analysisReportTitle))</div>
                <div class="diag-label">\(escape(LocalizedStrings.diagnosisField).uppercased())</div>
                <div class="diag">\(escape(report.diagnosis))</div>
                \(chipsHTML)
                <div class="meta">
                    <div><strong>ID:</strong> \(escape(patientId))</div>
                    <div><strong>WG:</strong> \(escape(woundGroupId))</div>
                    <div><strong>Date:</strong> \(escape(dateStr))</div>
                </div>
            </div>

            \(bannerHTML)
            \(imageHTML)

            <div class="grid-2">
                \(etiologyHTML)
                <div class="card recs">
                    <div class="card-title">\(escape(LocalizedStrings.recommendedTreatment))</div>
                    <ol>\(recsHTML)</ol>
                </div>
            </div>

            \(detailsHTML)

            <div class="footer">
                This report supports— and does not replace — clinical judgment. Escalate according to red flags and local policy.
            </div>
        </body>
        </html>
        """

        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = PDFPrintPageRendererWithFooter()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, .zero, nil)
        let pages = renderer.numberOfPages
        for i in 0..<pages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return data as Data
    }

    private static func escape(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: "&", with: "&amp;")
        out = out.replacingOccurrences(of: "<", with: "&lt;")
        out = out.replacingOccurrences(of: ">", with: "&gt;")
        out = out.replacingOccurrences(of: "\"", with: "&quot;")
        return out
    }

    private static func prettyDuration(_ id: String) -> String {
        switch id {
        case "lt4w":   return LocalizedStrings.optDurationLt4w
        case "w4to12": return LocalizedStrings.optDuration4to12
        case "gt12w":  return LocalizedStrings.optDurationGt12w
        default:       return LocalizedStrings.optUnknown
        }
    }
    private static func prettyInfection(_ id: String) -> String {
        switch id {
        case "none":     return LocalizedStrings.optInfectionNone
        case "local":    return LocalizedStrings.optInfectionLocal
        case "systemic": return LocalizedStrings.optInfectionSystemic
        default:         return LocalizedStrings.optUnknown
        }
    }
    private static func prettyMoisture(_ id: String) -> String {
        switch id {
        case "dry":      return LocalizedStrings.optMoistureDry
        case "low":      return LocalizedStrings.optMoistureLow
        case "moderate": return LocalizedStrings.optMoistureModerate
        case "high":     return LocalizedStrings.optMoistureHigh
        default:         return LocalizedStrings.optUnknown
        }
    }
    private static func prettyEdge(_ id: String) -> String {
        switch id {
        case "attached":   return LocalizedStrings.optEdgeAttached
        case "rolled":     return LocalizedStrings.optEdgeRolled
        case "undermined": return LocalizedStrings.optEdgeUndermined
        default:           return LocalizedStrings.optUnknown
        }
    }
    private static func prettyABI(_ id: String) -> String {
        switch id {
        case "ge0_8":      return LocalizedStrings.optAbiGE0_8
        case "p0_5to0_79": return LocalizedStrings.optAbi0_5to0_79
        case "lt0_5":      return LocalizedStrings.optAbiLT0_5
        default:           return LocalizedStrings.optUnknown
        }
    }
}

private final class PDFPrintPageRendererWithFooter: UIPrintPageRenderer {
    override init() {
        super.init()
        let a4 = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let margin: CGFloat = 28
        setValue(a4, forKey: "paperRect")
        setValue(a4.insetBy(dx: margin, dy: margin), forKey: "printableRect")
        self.headerHeight = 0
        self.footerHeight = 24
    }

    override func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect) {
        let pageText = "WoundPilot • \(pageIndex + 1) / \(numberOfPages)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let size = (pageText as NSString).size(withAttributes: attrs)
        let x = footerRect.midX - size.width / 2
        let y = footerRect.minY + (footerRect.height - size.height) / 2
        (pageText as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }
}

// =====================================================
// MARK: - UI Building Blocks
// =====================================================

private enum AlertBannerStyle { case danger, warning, info }

private struct AlertBanner: View {
    let text: String
    let style: AlertBannerStyle
    var body: some View {
        let bg: Color
        let fg: Color
        switch style {
        case .danger:  bg = .red.opacity(0.12);        fg = .red
        case .warning: bg = .orange.opacity(0.12);     fg = .orange
        case .info:    bg = .accentColor.opacity(0.12); fg = .accentColor
        }
        return HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text).font(.footnote.weight(.semibold))
            Spacer()
        }
        .foregroundColor(fg)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(bg))
        .padding(.top, 4)
    }
}

private struct HeroHeader: View {
    struct Chip: Identifiable { let id = UUID(); let icon: String; let title: String; let value: String }

    let title: String
    let diagnosisTitle: String
    let diagnosis: String
    let chips: [Chip]
    let stageLabel: String
    let stageProgress: Double

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.9)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(.white.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "stethoscope")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(diagnosisTitle.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(diagnosis)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(chips) { chip in
                        HStack(spacing: 8) {
                            Image(systemName: chip.icon).imageScale(.small)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(chip.title).font(.caption2.weight(.semibold)).opacity(0.85)
                                Text(chip.value).font(.caption.weight(.semibold))
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(.white.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding(16)

            ProgressRing(progress: stageProgress, label: stageLabel)
                .padding(12)
        }
        .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
    }
}

private struct ProgressRing: View {
    let progress: Double
    let label: String

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.25), lineWidth: 8)
                .frame(width: 64, height: 64)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 64, height: 64)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .frame(width: 54)
        }
    }
}

private struct InfoTile: View {
    let title: String
    let systemImage: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.05), lineWidth: 0.6))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

private struct RecommendationsGrid: View {
    let title: String
    let items: [String]
    let iconProvider: (String) -> String

    private var cols: [GridItem] { [GridItem(.adaptive(minimum: 170), spacing: 10)] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "cross.case.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(items.indices, id: \.self) { i in
                    RecommendationCard(index: i + 1,
                                       text: items[i],
                                       symbol: iconProvider(items[i]))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.05), lineWidth: 0.6))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

private struct RecommendationCard: View {
    let index: Int
    let text: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.14)).frame(width: 30, height: 30)
                Image(systemName: symbol).font(.caption)
                    .foregroundColor(.accentColor)
            }
            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.black.opacity(0.04), lineWidth: 0.6))
        .overlay(
            ZStack {
                Circle().fill(Color.accentColor).frame(width: 18, height: 18)
                Text("\(index)").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            }
            .offset(x: -8, y: -8),
            alignment: .topTrailing
        )
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
