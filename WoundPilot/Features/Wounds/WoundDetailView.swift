import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import Charts

struct WoundDetailView: View {
    let woundGroupId: String
    let woundGroupName: String
    let patient: Patient?

    @ObservedObject var langManager = LocalizationManager.shared

    @State private var wounds: [Wound] = []
    @State private var measurements: [WoundMeasurement] = []
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @State private var woundToDelete: Wound?
    @State private var showGroupDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Healing progress chart
                if isLoading {
                    ProgressView()
                        .padding()
                } else if measurements.count >= 2 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStrings.healingProgress)
                            .font(.headline)
                        
                        Chart(measurements) { measurement in
                            LineMark(
                                x: .value("Date", measurement.measured_at),
                                y: .value("Area (cm²)", measurement.area_cm2)
                            )
                            .foregroundStyle(.blue)
                            .symbol(Circle())
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date, format: .dateTime.month().day())
                                    }
                                }
                            }
                        }
                        
                        // Healing indicator
                        if let first = measurements.first, let last = measurements.last {
                            let change = last.area_cm2 - first.area_cm2
                            let percent = (change / first.area_cm2) * 100
                            
                            HStack(spacing: 6) {
                                Image(systemName: change < 0 ? "arrow.down.circle.fill" : "arrow.up.circle")
                                    .foregroundColor(change < 0 ? .green : .orange)
                                Text(String(format: "%.1f%% %@", abs(percent), change < 0 ? "smaller" : "larger"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(change < 0 ? .green : .orange)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill((change < 0 ? Color.green : Color.orange).opacity(0.15))
                            )
                        }
                    }
                } else {
                    // REPLACE THIS SECTION
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 4) {
                            Text("Track Healing Progress")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Take 2+ measurements over time to see healing trends")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.05))
                    )
                }

                Divider()

                // Wound list
                ForEach(wounds) { wound in
                    NavigationLink(destination: SingleWoundDetailView(wound: wound)) {
                        HStack(alignment: .top, spacing: 12) {
                            AsyncImage(url: URL(string: wound.imageURL)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(8)
                            } placeholder: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                    ProgressView()
                                }
                                .frame(width: 70, height: 70)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                if let location = wound.location {
                                    Text(location.replacingOccurrences(of: "_", with: " ")
                                                 .replacingOccurrences(of: "|", with: ", ")
                                                 .capitalized)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                }

                                Text(formatTimestamp(wound.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Button(role: .destructive) {
                                    woundToDelete = wound
                                    showDeleteConfirmation = true
                                } label: {
                                    Label(LocalizedStrings.deleteAction, systemImage: "trash")
                                        .font(.caption)
                                }
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
        }
        .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
        .navigationTitle(LocalizedStrings.woundDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showGroupDeleteConfirmation = true
                } label: {
                    Label(LocalizedStrings.deleteGroupAction, systemImage: "trash")
                }
            }
        }
        .onAppear(perform: loadData)
        .alert(LocalizedStrings.deleteWoundPhotoAlertTitle, isPresented: $showDeleteConfirmation, presenting: woundToDelete) { wound in
            Button(LocalizedStrings.deleteAction, role: .destructive) {
                deleteWound(wound)
            }
            Button(LocalizedStrings.cancel, role: .cancel) {}
        } message: { _ in
            Text(LocalizedStrings.cannotBeUndone)
        }
        .alert(LocalizedStrings.deleteAllInGroupAlertTitle, isPresented: $showGroupDeleteConfirmation) {
            Button(LocalizedStrings.deleteAllAction, role: .destructive) {
                deleteEntireWoundGroup()
            }
            Button(LocalizedStrings.cancel, role: .cancel) {}
        } message: {
            Text(LocalizedStrings.deleteAllInGroupWarning(woundGroupName))
        }
    }

    // MARK: - Data Loading
    
    private func loadData() {
        loadWoundGroup()
        loadMeasurements()
    }
    
    private func loadMeasurements() {
        WoundService.shared.fetchMeasurementHistory(woundGroupId: woundGroupId) { result in
            isLoading = false
            if case .success(let data) = result {
                measurements = data
            }
        }
    }

    private func loadWoundGroup() {
        let db = Firestore.firestore()
        db.collection("wounds")
            .whereField("woundGroupId", isEqualTo: woundGroupId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading group: \(error)")
                    return
                }
                if let docs = snapshot?.documents {
                    wounds = docs.compactMap { doc in
                        let data = doc.data()

                        guard
                            let imageURL = data["imageURL"] as? String,
                            let timestamp = data["timestamp"] as? Timestamp,
                            let patientId = data["patientId"] as? String,
                            let userId = data["userId"] as? String
                        else {
                            return nil
                        }

                        return Wound(
                            id: doc.documentID,
                            imageURL: imageURL,
                            timestamp: timestamp.dateValue(),
                            location: data["location"] as? String,
                            patientId: patientId,
                            userId: userId,
                            woundGroupId: data["woundGroupId"] as? String ?? "",
                            woundGroupName: data["woundGroupName"] as? String
                        )
                    }
                }
            }
    }

    // MARK: - Helpers

    private func formatTimestamp(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return df.string(from: date)
    }

    private func deleteWound(_ wound: Wound) {
        let db = Firestore.firestore()
        let storage = Storage.storage()

        db.collection("wounds").document(wound.id).delete { error in
            if let error = error {
                print("Error deleting wound document: \(error)")
                return
            }

            let storageRef = storage.reference(forURL: wound.imageURL)
            storageRef.delete { error in
                if let error = error {
                    print("Error deleting image from storage: \(error)")
                }
            }

            wounds.removeAll { $0.id == wound.id }
            loadMeasurements() // Refresh chart
        }
    }

    private func deleteEntireWoundGroup() {
        let db = Firestore.firestore()
        let storage = Storage.storage()

        for wound in wounds {
            db.collection("wounds").document(wound.id).delete { error in
                if let error = error {
                    print("Error deleting document: \(error)")
                }
            }

            let ref = storage.reference(forURL: wound.imageURL)
            ref.delete { error in
                if let error = error {
                    print("Error deleting image: \(error)")
                }
            }
        }

        wounds.removeAll()
        measurements.removeAll()
    }
}
