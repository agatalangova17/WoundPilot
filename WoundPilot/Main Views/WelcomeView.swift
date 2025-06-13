import SwiftUI

struct WelcomeView: View {
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // App Title
                    Text("WoundPilot")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    // Tagline
                    Text("AI-powered wound analysis in your pocket")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // App Icon
                    Image(systemName: "cross.case.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue.opacity(0.8))
                        .padding(.top, 10)
                    
                    // Product Description
                    Text("Capture a wound photo — our AI provides rapid, evidence-based clinical insights.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Video Placeholder
                    ZStack {
                        Rectangle()
                            .fill(Color.black.opacity(0.1))
                            .frame(height: 200)
                            .cornerRadius(12)
                        
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.blue)
                            
                            Text("Watch Introduction")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                                .padding(.top, 5)
                        }
                    }
                    .onTapGesture {
                        // TODO: Add action to play video or navigate
                    }
                    .padding(.horizontal)
                    
                    // Log In / Register buttons
                    VStack(spacing: 15) {
                        NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn)) {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        NavigationLink(destination: RegisterView(isUserLoggedIn: $isUserLoggedIn)) {
                            Text("Register")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.horizontal)
                    // MARK: - FAQ
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Frequently Asked Questions")
                            .font(.headline)

                        DisclosureGroup("Is my data secure?") {
                            Text("Yes. All data is encrypted and stored securely in compliance with healthcare standards.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        DisclosureGroup("Can I use WoundPilot offline?") {
                            Text("Some features work offline, but for AI analysis and syncing, you'll need an internet connection.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        DisclosureGroup("Is WoundPilot free?") {
                            Text("WoundPilot offers a free version with core features. Advanced tools may require a subscription in the future.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    
                    
                    Divider().padding(.horizontal)
                    // MARK: - About Us
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About Us")
                            .font(.headline)
                        Text("WoundPilot was created by doctors and engineers to help clinicians deliver faster, smarter wound care using AI-powered tools.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Who It's For
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Who It's For")
                            .font(.headline)
                        Text("Designed for doctors, nurses, and wound care specialists who want fast, accurate wound analysis on the go.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Privacy
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Privacy")
                            .font(.headline)
                        Text("We take data security seriously. All wound photos and user information are stored securely and never shared without your consent.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)}
            }
        }
    }
}
