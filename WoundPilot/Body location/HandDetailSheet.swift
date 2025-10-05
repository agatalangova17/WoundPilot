import SwiftUI

struct HandDetailSheet: View {
    @Binding var selection: String?
    var onDone: () -> Void

    
    private let fingerCodes = ["thumb", "index", "middle", "ring", "pinky"]
    private let areaCodes   = ["palm", "thenar", "hypothenar", "wrist", "dorsum"]

    var body: some View {
        NavigationStack {
            List {
                Section(LocalizedStrings.handSectionFingers) { chipRow(fingerCodes) }
                Section(LocalizedStrings.handSectionAreas)   { chipRow(areaCodes) }
            }
            .navigationTitle(LocalizedStrings.handDetailTitle)
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
                    chipButton(code: code, label: LocalizedStrings.handLabel(code))
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func chipButton(code: String, label: String) -> some View {
        Button { selection = code } label: {
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
