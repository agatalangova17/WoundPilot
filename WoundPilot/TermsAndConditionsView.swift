import SwiftUI

struct TermsAndConditionsView: View {
    var body: some View {
        ScrollView {
            Text("""
            Terms and Conditions v1.0

            1. This app is intended for use by medical professionals.
            2. You agree that the wound images you upload may be used to improve AI training.
            3. Your data is stored securely using Firebase infrastructure.
            ...
            """)
            .padding()
        }
        .navigationTitle("Terms & Conditions")
    }
}
