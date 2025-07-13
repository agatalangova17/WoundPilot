import SwiftUI

struct WelcomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var selectedStep = 1
    @State private var expandedQuestion: String?
    @State private var displayedText = ""
    let fullAssistantText = "I am here to guide you through fast and secure wound assessments powered by AI."

    let steps = [
        (1, "Securely log in or register your account", "log"),
        (2, "Access the dashboard and begin a new wound assessment", "start analysis"),
        (3, "Capture a clear wound photo using your camera", "photo"),
        (4, "Mark the wound location on the body diagram", "location"),
        (5, "Automatically analyze wound size and dimensions", "size"),
        (6, "Answer key clinical questions about the wound", "questions"),
        (7, "Receive AI-powered insights and healing guidance", "ai")
    ]

    let faqList: [(question: String, answer: String)] = [
        ("Is my data secure?", "Yes. All data is encrypted and stored securely in compliance with healthcare standards."),
        ("Can I use WoundPilot offline?", "Some features work offline, but AI analysis and syncing require internet."),
        ("Is WoundPilot free?", "The core version is free. Some advanced tools may require a subscription.")
    ]
    
    func typeWriterEffect() {
        displayedText = ""
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 0.035, repeats: true) { timer in
            if index < fullAssistantText.count {
                let nextChar = fullAssistantText[fullAssistantText.index(fullAssistantText.startIndex, offsetBy: index)]
                displayedText.append(nextChar)
                index += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if isUserLoggedIn {
                HomeView(isUserLoggedIn: $isUserLoggedIn)
            } else {
                ScrollView {
                    VStack(spacing: 30) {

                        // MARK: - App Title
                        VStack(spacing: 12) {
                            

                            Text("WoundPilot")
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
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        

                        
                        // MARK: - Meet Your Assistant
                        VStack(spacing: 16) {
                            Image("avatar")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                                .padding(.bottom, 4)
                                .onAppear {
                                    typeWriterEffect()
                                }

                            Text("Meet your clinical assistant.")
                                .font(.headline)
                                .foregroundColor(.black)

                            // Speech Bubble
                            Text(displayedText)
                                .font(.subheadline)
                                .padding()
                                .background(Color.accentBlue.opacity(0.08))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.accentBlue.opacity(0.2), lineWidth: 1)
                                )
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                        .padding()
                        .cornerRadius(14)
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
                        
                        
                        // MARK: - How It Works
                        VStack(spacing: 12) {
                            Text("How it Works")
                                .font(.headline)
                                .foregroundColor(.black)

                            HStack(spacing: 10) {
                                ForEach(1...7, id: \.self) { index in
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

                                    Image(step.2)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 180)
                                        .cornerRadius(12)
                                        .shadow(radius: 2)
                                }
                                .transition(.opacity)
                            }
                            }
                        }
                        .padding(.horizontal)

                        // MARK: - FAQ Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.accentBlue)
                                Text("FAQ")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                            }

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
                                        .padding(.top, 4)
                                        .transition(.opacity)
                                } label: {
                                    Text(faq.question)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.primaryBlue)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentBlue.opacity(0.07))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.accentBlue.opacity(0.2), lineWidth: 1)
                                )
                                .animation(.easeInOut(duration: 0.2), value: expandedQuestion)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
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


