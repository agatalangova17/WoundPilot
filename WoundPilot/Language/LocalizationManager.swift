import SwiftUI   // gives ObservableObject / @Published

enum Language: String { case en, sk }   

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.currentLanguage = Language(rawValue: saved) ?? .en
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
    }
}
