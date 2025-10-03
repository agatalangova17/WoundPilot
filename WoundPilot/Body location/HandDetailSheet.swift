import SwiftUI

struct HandDetailSheet: View {
    @Binding var selection: String?
    var onDone: () -> Void

    private let fingerOptions = [
        ("thumb", "Thumb"),
        ("index", "Index finger"),
        ("middle", "Middle finger"),
        ("ring", "Ring finger"),
        ("pinky", "Pinky")
    ]
    
    private let areaOptions = [
        ("palm", "Palm"),
        ("thenar", "Thenar"),
        ("hypothenar", "Hypothenar"),
        ("wrist", "Wrist"),
        ("dorsum", "Back of hand")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Fingers") {
                    chipRow(fingerOptions)
                }
                
                Section("Hand areas") {
                    chipRow(areaOptions)
                }
            }
            .navigationTitle("Hand detail")
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
