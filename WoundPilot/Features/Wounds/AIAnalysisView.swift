import SwiftUI

struct AIAnalysisView: View {
    // AI-generated dummy values
    let diagnosis = "Chronic Venous Leg Ulcer"
    let woundType = "Venous Ulcer"
    let healingStage = "Granulating"
    let woundStage = "Stage 2"
    let etiology = "Poor venous return due to varicose veins"
    let treatment = [
        "Clean wound gently with sterile saline",
        "Apply appropriate compression therapy",
        "Monitor closely for signs of infection",
        "Schedule reassessment in 7 days"
    ]

    @State private var animate = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Analysis Report")
                    .font(.title2.bold())
                    .padding(.top)

                Group {
                    analysisItem(title: "Diagnosis", value: diagnosis, icon: "stethoscope")
                    analysisItem(title: "Wound Type", value: woundType, icon: "bandage.fill")
                    analysisItem(title: "Healing Stage", value: healingStage, icon: "waveform.path.ecg")
                    analysisItem(title: "Wound Stage", value: woundStage, icon: "chart.bar.fill")
                    analysisItem(title: "Etiology", value: etiology, icon: "heart.text.square.fill")
                    treatmentCard()
                }
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: animate)

                // Action Buttons
                HStack(spacing: 16) {
                    Button {
                        // TODO: Share
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentBlue.opacity(0.15))
                            .foregroundColor(.accentBlue)
                            .cornerRadius(12)
                    }

                    Button {
                        // TODO: Download
                    } label: {
                        Label("Download", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.horizontal)
        }
        .onAppear {
            animate = true
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Reusable Info Card
    func analysisItem(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.gray)

            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Treatment Card
    func treatmentCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recommended Treatment", systemImage: "cross.case.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.gray)

            ForEach(treatment.indices, id: \.self) { index in
                Text("\(index + 1). \(treatment[index])")
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}


