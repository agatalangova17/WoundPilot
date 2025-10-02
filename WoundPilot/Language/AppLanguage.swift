enum AppLanguage: CaseIterable, Identifiable {
    case english
    case slovak

    var id: Self { self }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .slovak:  return "Slovenčina"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .slovak:  return "🇸🇰"
        }
    }

    // Bridge to your core Language enum
    var asLanguage: Language {
        switch self {
        case .english: return .en
        case .slovak:  return .sk
        }
    }
}
