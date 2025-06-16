import SwiftUI

struct TermsAndConditionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms & Conditions v1.0")
                    .font(.title)
                    .fontWeight(.bold)

                Group {
                    Text("Effective Date: [Insert Date]")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("These Terms and Conditions (\"Terms\") govern your use of the WoundPilot mobile application (\"App\") operated by [Your Company or Individual Name] (\"we\", \"us\", or \"our\"). By downloading, accessing, or using the App, you agree to be bound by these Terms. If you do not agree, you must not use the App.")
                }

                Divider()

                Group {
                    Text("1. Use of the App")
                        .font(.headline)

                    Text("You may use the App only for lawful purposes and in accordance with these Terms. The App is intended for use by licensed medical professionals, such as doctors and nurses, for the purpose of documenting and analyzing wound healing using photographs and metadata.")

                    Text("You are responsible for ensuring that all information entered into the App is accurate, complete, and in compliance with applicable medical guidelines and privacy laws.")
                }

                Divider()

                Group {
                    Text("2. Account Registration")
                        .font(.headline)

                    Text("To use the App, you must register for an account via Firebase Authentication. You agree to provide accurate and current information during registration and to keep your credentials secure.")

                    Text("You are solely responsible for all activity under your account. If you suspect unauthorized access, you must notify us immediately.")
                }

                Divider()

                Group {
                    Text("3. Medical Disclaimer")
                        .font(.headline)

                    Text("The App is intended to assist, not replace, clinical judgment. Any AI-powered analysis, wound classification, size estimation, or treatment recommendation is for informational purposes only and must be reviewed by a qualified healthcare provider before being applied to clinical care.")

                    Text("We do not provide medical advice, and we are not liable for any clinical decisions made using information from the App.")
                }

                Divider()

                Group {
                    Text("4. User Content and Conduct")
                        .font(.headline)

                    Text("By uploading wound images, patient metadata, or any other content (\"User Content\"), you grant us a limited, non-exclusive license to use that content for the operation of the App. You must have the necessary permissions to upload such content, especially in cases involving patient data.")

                    Text("You agree not to upload any content that is unlawful, defamatory, obscene, or violates any third-party rights.")
                }

                Divider()

                Group {
                    Text("5. Data Privacy and Security")
                        .font(.headline)

                    Text("We process personal data in accordance with our Privacy Policy. You agree that by using the App, your data (including patient data) may be stored and processed securely via Firebase services, subject to encryption and authentication controls.")

                    Text("It is your responsibility to obtain any necessary consents or legal bases before uploading personal health information.")
                }

                Divider()

                Group {
                    Text("6. Intellectual Property")
                        .font(.headline)

                    Text("All content, trademarks, software code, and materials within the App (excluding User Content) are owned by or licensed to us and protected by intellectual property laws. You may not reproduce, distribute, or create derivative works without our express permission.")
                }

                Divider()

                Group {
                    Text("7. Termination")
                        .font(.headline)

                    Text("We may suspend or terminate your access to the App at any time, with or without notice, if you violate these Terms or misuse the platform. Upon termination, your right to use the App will cease immediately.")
                }

                Divider()

                Group {
                    Text("8. Limitation of Liability")
                        .font(.headline)

                    Text("To the fullest extent permitted by law, we disclaim all warranties and liability arising from your use of the App. We are not responsible for any direct, indirect, incidental, or consequential damages resulting from App use, errors, or reliance on AI-generated outputs.")
                }

                Divider()

                Group {
                    Text("9. Modifications")
                        .font(.headline)

                    Text("We reserve the right to modify or update these Terms at any time. Continued use of the App after changes are published constitutes your acceptance of the updated Terms.")
                }

                Divider()

                Group {
                    Text("10. Governing Law")
                        .font(.headline)

                    Text("These Terms shall be governed by and construed in accordance with the laws of [Insert Jurisdiction]. Any disputes arising under or related to these Terms shall be resolved in the courts of [Insert Location].")
                }

                Divider()

                Group {
                    Text("11. Contact")
                        .font(.headline)

                    Text("For any questions, concerns, or disputes, please contact us at:")
                    Text("Email: [Insert Contact Email]")
                    Text("Mailing Address: [Insert Address if required]")
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Terms & Conditions")
    }
}
