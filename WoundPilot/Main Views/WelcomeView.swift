import SwiftUI

struct WelcomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var currentTab = 0
    @State private var selectedStep = 1
    @State private var expandedQuestion: String?
    @State private var displayedText = ""
    @State var selectedLanguage: String = ""
    
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
            TabView(selection: $currentTab) {
                
                // Page 0: Language Selection
                VStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 40))
                            .foregroundColor(.accentBlue)
                        Text("Select your language / Zvoľte jazyk")
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            selectedLanguage = "en"
                            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
                            withAnimation { currentTab = 1 }
                        }) {
                            HStack {
                                Text("🇬🇧 English")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.primaryBlue.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Button(action: {
                            selectedLanguage = "sk"
                            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
                            withAnimation { currentTab = 1 }
                        }) {
                            HStack {
                                Text("🇸🇰 Slovenčina")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentBlue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(0)

                // Page 1: Assistant Greeting
                VStack(spacing: 30) {
                    Text("WoundPilot")
                        .font(.largeTitle.bold())
                        .foregroundColor(.black)

                    Text("AI-powered wound analysis in your pocket")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Image("avatar")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                        .onAppear { typeWriterEffect() }

                    Text("👋 Hi, I’m your clinical assistant.")
                        .font(.headline)
                        .foregroundColor(.black)

                    Text(displayedText)
                        .font(.subheadline)
                        .padding()
                        .background(Color.accentBlue.opacity(0.08))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.accentBlue.opacity(0.2), lineWidth: 1))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn)) {
                        Text("Already using WoundPilot?")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.accentBlue)
                            .padding(.top, 10)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(1)

                // Page 2: Intro Video Placeholder
                VStack(spacing: 24) {
                    Text("Watch Introduction Video")
                        .font(.headline)
                        .foregroundColor(.black)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accentBlue.opacity(0.1))
                            .frame(height: 200)

                        VStack {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.accentBlue)
                            Text("Tap to play the quick overview")
                                .foregroundColor(.accentBlue)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .tag(2)

                // Page 3: How It Works
                VStack(spacing: 20) {
                    Text("How It Works")
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
                                .frame(height: 200)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                        }
                        .transition(.opacity)
                    }
                }
                .padding()
                .tag(3)

                // Page 4: FAQ
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
                        } label: {
                            Text(faq.question)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primaryBlue)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentBlue.opacity(0.07)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentBlue.opacity(0.2), lineWidth: 1))
                        .animation(.easeInOut(duration: 0.2), value: expandedQuestion)
                    }
                }
                .padding()
                .tag(4)

                // Page 5: Login/Register
                VStack(spacing: 30) {
                    Text("Let's Get Started")
                        .font(.largeTitle.bold())
                        .foregroundColor(.black)

                    Text("Log in or create your account to begin")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    VStack(spacing: 16) {
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
                    .padding(.horizontal)
                }
                .padding()
                .tag(5)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

// MARK: - Color Extension
extension Color {
    static let primaryBlue = Color(red: 0.20, green: 0.45, blue: 0.95)
    static let accentBlue  = Color(red: 0.25, green: 0.80, blue: 0.85)
}
