import SwiftUI

struct TermsAndConditionsView: View {
    @ObservedObject var langManager = LocalizationManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text(LocalizedStrings.termsTitle)
                    .font(.title)
                    .fontWeight(.bold)

                Group {
                    Text(LocalizedStrings.termsEffectiveDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(LocalizedStrings.termsIntro1)
                    Text(LocalizedStrings.termsIntro2)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms1Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms1Body1)
                    Text(LocalizedStrings.terms1Body2)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms2Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms2Body1)
                    Text(LocalizedStrings.terms2Body2)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms3Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms3Body1)
                    Text(LocalizedStrings.terms3Body2)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms4Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms4Body1)
                    Text(LocalizedStrings.terms4Body2)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms5Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms5Body1)
                    Text(LocalizedStrings.terms5Body2)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms6Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms6Body1)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms7Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms7Body1)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms8Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms8Body1)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms9Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms9Body1)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms10Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms10Body1)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.terms11Title)
                        .font(.headline)
                    Text(LocalizedStrings.terms11Lead)
                    Text(LocalizedStrings.terms11Email)
                    Text(LocalizedStrings.terms11Address)
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(LocalizedStrings.termsNavTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
