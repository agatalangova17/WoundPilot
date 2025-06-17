
import SwiftUI

struct SingleWoundDetailView: View {
    let wound: Wound

    @State private var navigateToSizeAnalysis = false

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
                    if let location = wound.location {
                        Label(
                            location.replacingOccurrences(of: "_", with: " ").capitalized,
                            systemImage: "mappin.circle.fill"
                        )
                    }

                    Label(
                        wound.timestamp.formatted(date: .long, time: .shortened),
                        systemImage: "calendar"
                    )

                    if let name = wound.woundGroupName {
                        Label(
                            name,
                            systemImage: "folder.fill"
                        )
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
                    Text("Analyze Wound")
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
        .navigationTitle("Wound Entry")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSizeAnalysis) {
            SizeAnalysisView(wound: wound)
        }
    }
}
