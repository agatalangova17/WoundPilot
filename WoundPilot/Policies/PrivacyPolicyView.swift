import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy v1.0")
                    .font(.title)
                    .fontWeight(.bold)

                Group {
                    Text("Effective Date: 16.6.2025")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("WoundPilot (\"we\", \"us\", or \"our\") is committed to protecting the privacy and security of our users’ personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (\"App\") and related services.")
                    
                    Text("By using the App, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree, please do not use the App.")
                }

                Divider()

                Group {
                    Text("1. Information We Collect")
                        .font(.headline)

                    Text("We collect the following categories of personal and medical data through your use of WoundPilot:")
                    
                    Text("• User Information: Name, Email address, Authentication details (via Firebase), Optional profile metadata")
                    Text("• Patient Information (added by the healthcare provider): Patient name, Medical conditions (e.g., diabetes), Wound-related metadata (location, timestamps, analysis details)")
                    Text("• Wound Image Data: Images of wounds captured via device camera or selected from gallery, Associated metadata: wound group name, anatomical location, size estimates, timestamps")
                    Text("• Usage Data: App usage patterns and interactions (non-identifiable, for performance improvement)")
                }

                Divider()

                Group {
                    Text("2. How We Use Your Information")
                        .font(.headline)

                    Text("We may use collected data for the following purposes:")
                    Text("• To operate and maintain the App")
                    Text("• To allow clinicians to document, monitor, and analyze wound healing")
                    Text("• To support AI-powered classification, measurement, and treatment recommendations")
                    Text("• To store and display patient-specific wound history securely")
                    Text("• To troubleshoot, improve, and personalize app functionality")
                    Text("• To comply with legal obligations")
                }

                Divider()

                Group {
                    Text("3. Data Storage and Security")
                        .font(.headline)

                    Text("All data is stored securely using Firebase Firestore and Firebase Storage. We implement industry-standard encryption (at rest and in transit) and authentication protocols to prevent unauthorized access.")
                    
                    Text("• Wound images are uploaded securely via HTTPS.")
                    Text("• Authentication is handled via Firebase Authentication with secure password handling.")
                    Text("• Access to patient data is restricted to authenticated users only.")
                    Text("• AI analysis is conducted either on-device (via CoreML) or securely in the cloud if applicable in the future.")
                }

                Divider()

                Group {
                    Text("4. Data Sharing and Disclosure")
                        .font(.headline)

                    Text("We do not sell, rent, or share any personal or patient information with third parties except in the following cases:")
                    Text("• With user consent")
                    Text("• To comply with legal obligations, court orders, or law enforcement requests")
                    Text("• To trusted third-party services strictly for app functionality (e.g., Firebase)")
                }

                Divider()

                Group {
                    Text("5. Data Retention")
                        .font(.headline)

                    Text("We retain user and patient data only for as long as necessary to fulfill the purposes described in this policy, unless a longer retention period is required by law.")
                    Text("Users may request deletion of their account or specific data by contacting support at [Insert Contact Email].")
                }

                Divider()

                Group {
                    Text("6. Children’s Privacy")
                        .font(.headline)

                    Text("WoundPilot is not intended for use by individuals under the age of 18. We do not knowingly collect data from minors. If you believe a minor’s data has been collected, please contact us for immediate removal.")
                }

                Divider()

                Group {
                    Text("7. User Rights")
                        .font(.headline)

                    Text("As a user, you have the right to:")
                    Text("• Access and review your personal data")
                    Text("• Correct inaccurate or incomplete data")
                    Text("• Request deletion of your account or data")
                    Text("• Withdraw consent at any time")

                    Text("Please email info@woundpilot.com for data-related requests. We will respond within 30 days.")
                }

                Divider()

                Group {
                    Text("8. International Users")
                        .font(.headline)

                    Text("WoundPilot is currently intended for use within the European Union, and all data is stored in compliance with GDPR. If you access the app from outside this region, you do so at your own risk and are responsible for compliance with local laws.")
                }

                Divider()

                Group {
                    Text("9. Policy Changes")
                        .font(.headline)

                    Text("We may update this Privacy Policy to reflect changes in our practices or legal obligations. We will notify users of significant changes through the app interface or via email. Continued use of the app after changes constitutes acceptance of the updated policy.")
                }

                Divider()

                Group {
                    Text("10. Contact Us")
                        .font(.headline)

                    Text("For questions, concerns, or data requests, please contact:")
                    Text("WoundPilot Privacy Officer")
                    Text("Email: info@woundpilot.com")
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}
