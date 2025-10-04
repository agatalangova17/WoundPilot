import SwiftUI

struct FootDetailSheet: View {
    @Binding var selection: String?
    var onDone: () -> Void

    // Stable codes; text comes from LocalizedStrings
    private let toeOptions  = ["toe_1", "toe_2", "toe_3", "toe_4", "toe_5"]
    private let heelOptions = ["heel_central", "heel_medial", "heel_lateral"]
    private let zoneOptions = ["forefoot", "midfoot", "hindfoot", "plantar_arch"]

    var body: some View {
        NavigationStack {
            List {
                Section(LocalizedStrings.footSectionToes)  { chipRow(toeOptions)  }
                Section(LocalizedStrings.footSectionHeel)  { chipRow(heelOptions) }
                Section(LocalizedStrings.footSectionZones) { chipRow(zoneOptions) }
            }
            .navigationTitle(LocalizedStrings.footDetailTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStrings.actionDone) { onDone() }
                }
            }
        }
    }

    private func chipRow(_ codes: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(codes, id: \.self) { code in
                    chipButton(code: code, label: LocalizedStrings.footLabel(code))
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func chipButton(code: String, label: String) -> some View {
        Button {
            selection = code
        } label: {
            Text(label)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selection == code ? Color.accentColor.opacity(0.18) : Color(.systemGray6))
                )
                .overlay(
                    Capsule()
                        .stroke(selection == code ? Color.accentColor : Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
