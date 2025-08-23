import SwiftUI

struct SingleWoundDetailView: View {
    let wound: Wound

    @ObservedObject var langManager = LocalizationManager.shared
    @State private var navigateToSizeAnalysis = false

    // Localized date+time
    private var formattedTimestamp: String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue) // "en" / "sk"
        return df.string(from: wound.timestamp)
    }

    // Human-friendly location from stored code like "left_foot"
    private var displayLocation: String? {
        guard let loc = wound.location, !loc.isEmpty else { return nil }
        return loc.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Wound Image
                if let imageURL = URL(string: wound.imageURL) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 4)
                    } placeholder: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 260)
                    .padding(.horizontal)
                }

                // Left-aligned metadata
                VStack(alignment: .leading, spacing: 10) {
                    if let location = displayLocation {
                        Label(location, systemImage: "mappin.circle.fill")
                    }

                    Label(formattedTimestamp, systemImage: "calendar")

                    if let name = wound.woundGroupName {
                        Label(name, systemImage: "folder.fill")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Analyze Button
                Button {
                    navigateToSizeAnalysis = true
                } label: {
                    Text(LocalizedStrings.analyzeWound)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .navigationTitle(LocalizedStrings.woundEntryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSizeAnalysis) {
            SizeAnalysisView(wound: wound)
        }
    }
}
