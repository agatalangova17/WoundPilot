import SwiftUI

struct ShareCaseView: View {
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var recipientEmail: String = ""
    @State private var notes: String = ""
    @State private var isSharing = false

    var body: some View {
        Form {
            Section(header: Text(LocalizedStrings.recipientSection)) {
                TextField(LocalizedStrings.doctorEmailPlaceholder, text: $recipientEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }

            Section(header: Text(LocalizedStrings.messageSection)) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                    if notes.isEmpty {
                        Text(LocalizedStrings.messagePlaceholder)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                }
            }

            Section {
                Button {
                    isSharing = true
                    // TODO: Add Firebase sharing logic
                } label: {
                    HStack {
                        Spacer()
                        if isSharing {
                            ProgressView(LocalizedStrings.sharingInProgress)
                        } else {
                            Text(LocalizedStrings.shareCaseButton)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(recipientEmail.isEmpty)
            }
        }
        .navigationTitle(LocalizedStrings.shareCaseTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
