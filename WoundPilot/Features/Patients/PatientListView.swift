import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct PatientListView: View {
    @ObservedObject var langManager = LocalizationManager.shared

    @State private var patients: [Patient] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var patientToDelete: Patient?
    @State private var showDeleteConfirmation = false

    @State private var selectedPatient: Patient?
    @State private var showPatientDetail = false

    @State private var searchText = ""
    @State private var scope: SearchScope = .all

    // MARK: - Filtered + searched list
    private var results: [Patient] {
        var list = patients

        switch scope {
        case .all: break
        case .diabetic: list = list.filter { $0.hasDiabetes == true }  // FIXED
        case .smoker:   list = list.filter { $0.isSmoker   == true }
        case .pad:      list = list.filter { $0.hasPAD     == true }
        }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return list }

        let qLower = q.lowercased()
        return list.filter { p in
            let nameMatch = p.name.lowercased().contains(qLower)
            let a = age(from: p.dateOfBirth)
            let ageMatch = "\(a)".contains(qLower)
            let year = Calendar.current.component(.year, from: p.dateOfBirth)
            let yearMatch = "\(year)".contains(qLower)
            return nameMatch || ageMatch || yearMatch
        }
    }

    private var nameSuggestions: [String] {
        let names = patients.map { $0.name }.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return Array(names.prefix(6))
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView(LocalizedStrings.loadingPatients)
                        Text(LocalizedStrings.loadingPatientsSubtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty {
                    EmptyStateView(
                        title: LocalizedStrings.noPatientsFound,
                        subtitle: searchText.isEmpty
                            ? LocalizedStrings.startByAddingPatient
                            : LocalizedStrings.noSearchResults
                    )
                    .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { patient in
                                Button {
                                    selectedPatient = patient
                                    showPatientDetail = true
                                } label: {
                                    PatientRowCardNoAvatar(
                                        patient: patient,
                                        dobString: formatDOB(patient.dateOfBirth),
                                        badges: patientBadges(patient),
                                        accent: color(from: patient.name)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        patientToDelete = patient
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label(LocalizedStrings.deletePatientAction, systemImage: "trash")
                                    }
                                }
                            }
                            .padding(.top, 6)
                        }
                        .padding(.bottom, 12)
                    }
                    .refreshable { loadPatients() }
                }
            }
            .environment(\.locale, Locale(identifier: langManager.currentLanguage.rawValue))
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: LocalizedStrings.searchPatientsPrompt
            )
            .searchSuggestions {
                Text(LocalizedStrings.tagDM).searchCompletion(LocalizedStrings.tagDM)
                Text(LocalizedStrings.tagSmoker).searchCompletion(LocalizedStrings.tagSmoker)
                Text(LocalizedStrings.tagPAD).searchCompletion(LocalizedStrings.tagPAD)
                Divider()
                ForEach(nameSuggestions, id: \.self) { s in Text(s).searchCompletion(s) }
            }
            .searchScopes($scope) {
                Text(LocalizedStrings.scopeAll).tag(SearchScope.all)
                Text(LocalizedStrings.scopeDM).tag(SearchScope.diabetic)
                Text(LocalizedStrings.scopeSmoker).tag(SearchScope.smoker)
                Text(LocalizedStrings.scopePAD).tag(SearchScope.pad)
            }
            .navigationTitle(LocalizedStrings.yourPatientsTitle)
            .onAppear(perform: loadPatients)
            .navigationDestination(isPresented: $showPatientDetail) {
                if let patient = selectedPatient {
                    PatientDetailView(patient: patient)
                }
            }
            .alert(LocalizedStrings.deletePatientAlertTitle, isPresented: $showDeleteConfirmation) {
                Button(LocalizedStrings.deleteAction, role: .destructive) {
                    if let p = patientToDelete { deletePatientAndAllWounds(patient: p) }
                }
                Button(LocalizedStrings.cancel, role: .cancel) {}
            }
            .overlay(alignment: .bottom) {
                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                        .padding(.bottom, 12)
                        .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helpers (formatting / badges)

    private func formatDOB(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.locale = Locale(identifier: langManager.currentLanguage.rawValue)
        return df.string(from: date)
    }

    private func patientBadges(_ p: Patient) -> [Badge] {
        var items: [Badge] = []
        
        items.append(Badge(icon: "calendar", text: String(age(from: p.dateOfBirth))))
        if p.hasDiabetes == true {  // FIXED
            items.append(Badge(icon: "drop.fill", text: LocalizedStrings.badgeDM))
        }
        if p.isSmoker == true {
            items.append(Badge(icon: "lungs.fill", text: LocalizedStrings.badgeSmoker))
        }
        if p.hasPAD == true {
            items.append(Badge(
                icon: "figure.walk.motion",
                text: LocalizedStrings.badgePAD,
                accessibilityLabel: LocalizedStrings.peripheralArteryDisease
            ))
        }
        return items
    }

    private func age(from dob: Date) -> Int {
        Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }

    private func color(from seed: String) -> Color {
        var total = 0
        for u in seed.unicodeScalars { total = Int(u.value) &+ total }
        let hue = Double(total % 256) / 255.0
        return Color(hue: hue, saturation: 0.65, brightness: 0.80)
    }

    // MARK: - Data

    private func loadPatients() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = LocalizedStrings.userNotLoggedIn
            self.isLoading = false
            return
        }

        isLoading = true
        let db = Firestore.firestore()

        db.collection("patients")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = LocalizedStrings.failedToLoadPatients(error.localizedDescription)
                        return
                    }

                    if let documents = snapshot?.documents {
                        self.patients = documents.compactMap { doc in
                            let data = doc.data()
                            guard let name = data["name"] as? String,
                                  let dobTimestamp = data["dateOfBirth"] as? Timestamp else { return nil }

                            // Parse mobility status
                            var mobilityStatus: MobilityStatus? = nil
                            if let mobilityString = data["mobilityStatus"] as? String {
                                mobilityStatus = MobilityStatus(rawValue: mobilityString)
                            }

                            return Patient(
                                id: doc.documentID,
                                name: name,
                                dateOfBirth: dobTimestamp.dateValue(),
                                sex: data["sex"] as? String,
                                hasDiabetes: data["hasDiabetes"] as? Bool,
                                hasPAD: data["hasPAD"] as? Bool,
                                hasVenousDisease: data["hasVenousDisease"] as? Bool,
                                isImmunosuppressed: data["isImmunosuppressed"] as? Bool,
                                mobilityStatus: mobilityStatus,
                                canOffload: data["canOffload"] as? Bool,
                                isOnAnticoagulants: data["isOnAnticoagulants"] as? Bool,
                                isSmoker: data["isSmoker"] as? Bool,
                                allergyToAdhesives: data["allergyToAdhesives"] as? Bool,
                                allergyToIodine: data["allergyToIodine"] as? Bool,
                                allergyToSilver: data["allergyToSilver"] as? Bool,
                                allergyToLatex: data["allergyToLatex"] as? Bool,
                                weight: data["weight"] as? Double,
                                otherAllergies: data["otherAllergies"] as? String,
                                notes: data["notes"] as? String
                            )
                        }
                    }
                }
            }
    }

    private func deletePatientAndAllWounds(patient: Patient) {
        let db = Firestore.firestore()
        let storage = Storage.storage()

        db.collection("wounds")
            .whereField("patientId", isEqualTo: patient.id)
            .getDocuments { snapshot, _ in
                if let documents = snapshot?.documents {
                    for doc in documents {
                        if let url = doc.data()["imageURL"] as? String {
                            let storageRef = storage.reference(forURL: url)
                            storageRef.delete(completion: nil)
                        }
                        doc.reference.delete()
                    }
                }

                db.collection("patients").document(patient.id).delete { err in
                    if let err = err {
                        self.errorMessage = LocalizedStrings.failedToDeletePatient(err.localizedDescription)
                    } else {
                        loadPatients()
                    }
                }
            }
    }
}

// MARK: - Search scope
private enum SearchScope: Hashable, CaseIterable {
    case all, diabetic, smoker, pad
}

// MARK: - Row/Card components

private struct Badge: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    var accessibilityLabel: String? = nil
}

private struct PatientRowCardNoAvatar: View {
    let patient: Patient
    let dobString: String
    let badges: [Badge]
    let accent: Color

    @ScaledMetric(relativeTo: .title3) private var radius: CGFloat = 14

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accent.opacity(0.9))
                .frame(width: 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(patient.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .imageScale(.small)
                    Text(dobString)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if !badges.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(badges) { b in
                            HStack(spacing: 4) {
                                Image(systemName: b.icon).imageScale(.small)
                                Text(b.text).font(.caption2.weight(.semibold))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                            .accessibilityLabel(b.accessibilityLabel ?? b.text)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .imageScale(.small)
        }
        .padding(14)
        .background(
            shape
                .fill(Color(.secondarySystemBackground))
                .overlay(shape.stroke(Color.black.opacity(0.05), lineWidth: 0.5))
        )
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
        .contentShape(shape)
    }
}

private struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text(title).font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .center)
    }
}
