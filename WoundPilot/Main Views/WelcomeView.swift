import SwiftUI

struct WelcomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var selectedStep = 1
    @State private var expandedQuestion: String?

    let steps = [
        (1, "Register or log in securely", "person.crop.circle"),
        (2, "Add a patient", "person.crop.circle.badge.plus"),
        (3, "Capture wound photo", "camera.viewfinder"),
        (4, "Answer clinical questions", "doc.plaintext"),
        (5, "AI-powered size & healing analysis", "brain.head.profile")
    ]

    let faqList: [(question: String, answer: String)] = [
        ("Is my data secure?", "Yes. All data is encrypted and stored securely in compliance with healthcare standards."),
        ("Can I use WoundPilot offline?", "Some features work offline, but AI analysis and syncing require internet."),
        ("Is WoundPilot free?", "The core version is free. Some advanced tools may require a subscription.")
    ]

    var body: some View {
        NavigationStack {
            if isUserLoggedIn {
                HomeView(isUserLoggedIn: $isUserLoggedIn)
            } else {
                ScrollView {
                    VStack(spacing: 30) {

                        // MARK: - App Title
                        VStack(spacing: 12) {
                            Image(systemName: "cross.case.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.accentBlue)

                            Text("Welcome to WoundPilot!")
                                .font(.largeTitle.bold())
                                .foregroundColor(.black)

                            Text("AI-powered wound analysis in your pocket")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 30)

                        // MARK: - Login/Register Section (Top and Separated)
                        VStack(spacing: 16) {

                            VStack(spacing: 12) {
                                NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn)) {
                                    Text("Log In")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.primaryBlue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                NavigationLink(destination: RegisterView(isUserLoggedIn: $isUserLoggedIn)) {
                                    Text("Register")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentBlue.opacity(0.15))
                                        .foregroundColor(.accentBlue)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // MARK: - Watch Video
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentBlue.opacity(0.1))
                                .frame(height: 180)

                            VStack {
                                Image(systemName: "play.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.accentBlue)

                                Text("Watch Introduction")
                                    .foregroundColor(.accentBlue)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)

                        // MARK: - Benefits
                        VStack(spacing: 12) {
                            Text("Benefits")
                                .font(.headline)
                                .foregroundColor(.black)

                            HStack(spacing: 12) {
                                BenefitCard(icon: "stethoscope", text: "Doctors & Nurses")
                                BenefitCard(icon: "bolt.fill", text: "Fast Insights")
                                BenefitCard(icon: "lock.shield.fill", text: "Secure by Design")
                            }
                        }
                        .padding(.horizontal)

                        // MARK: - How It Works
                        VStack(spacing: 12) {
                            Text("How it Works")
                                .font(.headline)
                                .foregroundColor(.black)

                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { index in
                                    Button(action: {
                                        withAnimation { selectedStep = index }
                                    }) {
                                        Text("\(index)")
                                            .fontWeight(.bold)
                                            .frame(width: 40, height: 40)
                                            .background(selectedStep == index ? Color.primaryBlue : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedStep == index ? .white : .black)
                                            .clipShape(Circle())
                                    }
                                }
                            }

                            if let step = steps.first(where: { $0.0 == selectedStep }) {
                                VStack(spacing: 10) {
                                    Text(step.1)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)

                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(height: 180)

                                        Image(systemName: step.2)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 80, height: 80)
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal)

                        // MARK: - FAQ Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("FAQ")
                                .font(.headline)
                                .foregroundColor(.black)

                            ForEach(faqList, id: \.question) { faq in
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { expandedQuestion == faq.question },
                                        set: { expandedQuestion = $0 ? faq.question : nil }
                                    )
                                ) {
                                    Text(faq.answer)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                } label: {
                                    Text(faq.question)
                                        .foregroundColor(.primaryBlue)
                                }
                                .padding()
                                .background(Color.accentBlue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
                .background(Color.white)
            }
        }
    }
}

// MARK: - Benefit Card
struct BenefitCard: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentBlue)

            Text(text)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color.accentBlue.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Color Extension
extension Color {
    static let primaryBlue = Color(red: 0.20, green: 0.45, blue: 0.95)
    static let accentBlue  = Color(red: 0.25, green: 0.80, blue: 0.85)
}
