import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy v1.0")
                    .font(.title)
                    .fontWeight(.bold)

                Text("""
                WoundPilot is committed to protecting your privacy. This Privacy Policy explains how your data is collected, stored, and used.

                1. **Data Collection**
                We collect your email and securely store wound images and metadata (such as wound size and date) in Firebase services.

                2. **Use of Data**
                Your data is used only to provide and improve the wound care functionalities of this app. Images may be used for AI model training under strict anonymization.

                3. **Storage and Security**
                Data is stored on Firebase servers with industry-standard security practices. Access is limited to authorized personnel only.

                4. **Your Rights**
                You may request to export or delete your data at any time by contacting our support team.

                5. **AI Training Consent**
                By agreeing to the Privacy Policy, you consent to allow anonymized wound images to be used in future AI research and model training.

                6. **Changes to This Policy**
                You will be notified of any significant changes to this Privacy Policy via the app.

                For any questions, contact us at: support@woundpilot.app
                """)
                .font(.body)
                .padding(.top)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}
