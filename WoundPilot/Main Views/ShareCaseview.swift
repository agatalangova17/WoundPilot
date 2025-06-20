import SwiftUI

struct ShareCaseView: View {
    @State private var recipientEmail: String = ""
    @State private var notes: String = ""
    @State private var isSharing = false

    var body: some View {
        Form {
            Section(header: Text("Recipient")) {
                TextField("Doctor's Email", text: $recipientEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }

            Section(header: Text("Message")) {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }

            Section {
                Button(action: {
                    isSharing = true
                    // Add Firebase sharing logic here
                }) {
                    HStack {
                        Spacer()
                        if isSharing {
                            ProgressView()
                        } else {
                            Text("Share Case")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(recipientEmail.isEmpty)
            }
        }
        .navigationTitle("Share Case")
        .navigationBarTitleDisplayMode(.inline)
    }
}
