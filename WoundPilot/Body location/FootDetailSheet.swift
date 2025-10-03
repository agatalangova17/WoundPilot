import SwiftUI

struct FootDetailSheet: View {
    @Binding var selection: String?
    var onDone: () -> Void

    private let toeOptions = [
        ("toe_1", "Hallux"),
        ("toe_2", "2nd toe"),
        ("toe_3", "3rd toe"),
        ("toe_4", "4th toe"),
        ("toe_5", "5th toe")
    ]
    
    private let heelOptions = [
        ("heel_central", "Heel (central)"),
        ("heel_medial", "Heel (medial)"),
        ("heel_lateral", "Heel (lateral)")
    ]
    
    private let zoneOptions = [
        ("forefoot", "Forefoot"),
        ("midfoot", "Midfoot"),
        ("hindfoot", "Hindfoot"),
        ("plantar_arch", "Plantar arch")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Toes") {
                    chipRow(toeOptions)
                }
                
                Section("Heel") {
                    chipRow(heelOptions)
                }
                
                Section("Zones") {
                    chipRow(zoneOptions)
                }
            }
            .navigationTitle("Foot detail")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
    }
    
    private func chipRow(_ options: [(String, String)]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.0) { code, label in
                    chipButton(code: code, label: label)
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
