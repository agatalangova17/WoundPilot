import SwiftUI

struct PrivacyPolicyView: View {
    @ObservedObject var langManager = LocalizationManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text(LocalizedStrings.privacyPolicyTitle)
                    .font(.title)
                    .fontWeight(.bold)

                Group {
                    Text(LocalizedStrings.privacyPolicyEffectiveDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(LocalizedStrings.privacyIntro1)
                    Text(LocalizedStrings.privacyIntro2)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection1Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection1Intro)
                    ForEach(LocalizedStrings.privacySection1Bullets, id: \.self) { line in
                        Text("• \(line)")
                    }
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection2Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection2Intro)
                    ForEach(LocalizedStrings.privacySection2Bullets, id: \.self) { line in
                        Text("• \(line)")
                    }
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection3Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection3Intro)
                    ForEach(LocalizedStrings.privacySection3Bullets, id: \.self) { line in
                        Text("• \(line)")
                    }
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection4Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection4Intro)
                    ForEach(LocalizedStrings.privacySection4Bullets, id: \.self) { line in
                        Text("• \(line)")
                    }
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection5Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection5Body1)
                    Text(LocalizedStrings.privacySection5Body2)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection6Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection6Body)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection7Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection7Intro)
                    ForEach(LocalizedStrings.privacySection7Bullets, id: \.self) { line in
                        Text("• \(line)")
                    }
                    Text(LocalizedStrings.privacySection7Contact)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection8Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection8Body)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection9Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection9Body)
                }

                Divider()

                Group {
                    Text(LocalizedStrings.privacySection10Title)
                        .font(.headline)

                    Text(LocalizedStrings.privacySection10Lead)
                    Text(LocalizedStrings.privacySection10Officer)
                    Text(LocalizedStrings.privacySection10Email)
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(LocalizedStrings.privacyPolicyNavTitle)
    }
}
