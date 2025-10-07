import Foundation

struct LocalizedStrings {
    private static var lang: Language { LocalizationManager.shared.currentLanguage }
    static func t(_ en: String, _ sk: String) -> String {
        lang == .sk ? sk : en
    }

    // MARK: - Common strings
    static var ok: String { t("OK", "OK") }
    static var cancel: String { t("Cancel", "Zrušiť") }
    static var save: String { t("Save", "Uložiť") }
    static var delete: String { t("Delete", "Vymazať") }
    static var edit: String { t("Edit", "Upraviť") }
    static var continueBtn: String { t("Continue", "Pokračovať") }
    static var back: String { t("Back", "Späť") }
    static var loading: String { t("Loading…", "Načítava sa…") }
    static var retry: String { t("Retry", "Skúsiť znova") }

    // MARK: - Welcome / Language
    static var welcomeTitle: String { t("Choose your language", "Vyberte si jazyk") }
    static var appTitle: String { "WoundPilot" }
    static var appSubtitle: String {
        t("Your smart wound care assistant",
          "Tvoj asistent ošetrovania rán")
    }
    static var assistantIntroLine: String {
        t("I am your clinical assistant.",
          "Som váš klinický asistent.")
    }
    static var assistantTypingText: String {
        t("I will help you with wound measurement, documentation, and healing trends.",
          "Pomôžem s meraním rán, dokumentáciou a sledovaním hojenia.")
    }
    
    static var getStartedTitle: String { t("Proceed", "Začnime") }
    static var getStartedSubtitle: String {
        t("Log in or create your account to begin",
          "Prihláste sa alebo si vytvorte účet")
    }
    static var loginButton: String { t("Log In", "Prihlás sa") }
    static var registerButton: String { t("Register", "Zaregistruj sa") }
    


    // MARK: - Auth
    static var email: String { t("Email", "Email") }
    static var password: String { t("Password", "Heslo") }
    static var confirmPassword: String { t("Confirm Password", "Potvrďte heslo") }
    static var signOut: String { t("Sign Out", "Odhlásiť sa") }
    static var forgotPassword: String { t("Forgot password?", "Zabudnuté heslo?") }

    // MARK: - Dashboard / Navigation
    static var addPatient: String { t("Add Patient", "Pridať pacienta") }
    static var quickAnalysis: String { t("Quick Analysis", "Rýchla analýza") }

    // MARK: - Patients
    static var patients: String { t("Patients", "Pacienti") }
    static var patientName: String { t("Patient Name", "Meno pacienta") }
    static var dateOfBirth: String { t("Date of Birth", "Dátum narodenia") }
    static var noPatients: String { t("No patients yet", "Zatiaľ žiadni pacienti") }

    // MARK: - Wounds & Capture
    static var newWound: String { t("New Wound", "Nová rana") }
    static var capturePhoto: String { t("Capture Photo", "Odfotiť") }
    static var chooseFromLibrary: String { t("Choose from Library", "Vybrať z galérie") }
    static var useDummyImage: String { t("Use Dummy Image", "Použiť ukážkový obrázok") }
    static var selectLocation: String { t("Select Location", "Vyberte polohu") }
    static var groupName: String { t("Wound Group Name", "Názov skupiny rán") }
    static var saveWound: String { t("Save Wound", "Uložiť ranu") }

    // MARK: - Analysis
    static var prepareAnalysis: String { t("Prepare Analysis", "Príprava analýzy") }
    static var startAnalysis: String { t("Start Analysis", "Spustiť analýzu") }
    static var measuringSize: String { t("Measuring size…", "Meranie veľkosti…") }
    static var generatingReport: String { t("Generating report…", "Generovanie správy…") }

    // MARK: - Questionnaire
    static var questionnaireTitle: String { t("Clinical Questionnaire", "Klinický dotazník") }
    static var hasDiabetes: String { t("Diabetes", "Diabetes") }
    static var signsOfInfection: String { t("Signs of Infection", "Známky infekcie") }
    static var exudateLevel: String { t("Exudate Level", "Množstvo exsudátu") }
    static var woundAge: String { t("Wound Age", "Trvanie rany") }

    // MARK: - Reports
    static var exportPDF: String { t("Export PDF", "Export PDF") }
    static var addClinicLogo: String { t("Add Clinic Logo", "Pridať logo kliniky") }

    // MARK: - Errors / Alerts
    static var errorTitle: String { t("Something went wrong", "Niečo sa pokazilo") }
    static var networkError: String { t("Network error. Please try again.", "Chyba siete. Skúste znova.") }
    static var requiredField: String { t("This field is required", "Toto pole je povinné") }
    static var invalidEmail: String { t("Please enter a valid email", "Zadajte platný email") }
    static var passwordsDontMatch: String { t("Passwords do not match", "Heslá sa nezhodujú") }
    
    // MARK: - Analytics
    static var analyticsTitle: String { t("Analytics", "Analytika") }
    static var timeRangeLabel: String { t("Time Range", "Časové obdobie") }
    static var totalPatients: String { t("Total Patients", "Počet pacientov") }
    static var totalWoundCaptures: String { t("Total Wound Captures", "Počet zachytených rán") }

    // Time range labels
    static var timeToday: String { t("Today", "Dnes") }
    static var timeThisWeek: String { t("This Week", "Tento týždeň") }
    static var timeAllTime: String { t("All Time", "Celé obdobie") }
    
    // MARK: - Clinical Tips
    static var clinicalTipsTitle: String {
        t("Clinical Tips", "Klinické tipy")
    }
    static var clinicalTipsSubtitle: String {
        t("Best-practice wound care guidelines for clinicians. These tips are rooted in evidence and regularly reviewed.",
          "Odporúčané postupy pri ošetrovaní rán pre klinikov. Tipy vychádzajú z dôkazov a pravidelne sa aktualizujú.")
    }

    // Individual tips
    static var tipMoistureTitle: String {
        t("Moisture Balance", "Rovnováha vlhkosti")
    }
    static var tipMoistureDesc: String {
        t("Keeping wounds moist—not wet—accelerates epithelialization and tissue repair.",
          "Udržiavanie rán vlhkých—nie mokrých—urýchľuje epitelizáciu a regeneráciu tkaniva.")
    }

    static var tipEdgeTitle: String {
        t("Edge Assessment", "Hodnotenie okrajov")
    }
    static var tipEdgeDesc: String {
        t("Monitor wound edges for maceration, undermining, or rolled borders to guide interventions.",
          "Sledujte okraje rany pre maceráciu, podkopanie alebo zrolované okraje, aby ste zvolili vhodný zásah.")
    }

    static var tipTimeTitle: String {
        t("TIME Framework", "Rámec TIME")
    }
    static var tipTimeDesc: String {
        t("Apply the TIME approach: Tissue management, Inflammation/Infection control, Moisture balance, and Edge advancement.",
          "Používajte prístup TIME: Tkanivo, Zápal/Infekcia, Vlhkosť a Okraj.")
    }

    static var tipGranulationTitle: String {
        t("Granulation Tissue", "Granulačné tkanivo")
    }
    static var tipGranulationDesc: String {
        t("Bright red, bumpy tissue in the wound bed is a positive sign of healing progress.",
          "Sýtočervené, hrboľaté tkanivo v lôžku rany je pozitívnym znakom hojenia.")
    }

    static var tipInfectionTitle: String {
        t("Infection Indicators", "Známky infekcie")
    }
    static var tipInfectionDesc: String {
        t("Look for increased pain, redness, warmth, swelling, or odor — signs that may require antimicrobial therapy.",
          "Sledujte zvýšenú bolesť, začervenanie, teplo, opuch alebo zápach — môžu vyžadovať antimikrobiálnu liečbu.")
    }

    static var tipSizeTitle: String {
        t("Size Monitoring", "Monitorovanie veľkosti")
    }
    static var tipSizeDesc: String {
        t("Document wound dimensions regularly to track healing trajectory and adjust treatment.",
          "Pravidelne zaznamenávajte rozmery rany na sledovanie hojenia a úpravu liečby.")
    }

    static var tipEpithelialTitle: String {
        t("Epithelialization", "Epitelizácia")
    }
    static var tipEpithelialDesc: String {
        t("Thin, pale pink tissue covering the wound indicates closure is approaching.",
          "Tenké, bledoružové tkanivo pokrývajúce ranu naznačuje blížiace sa uzatváranie.")
    }
    
    // MARK: - Home / Dashboard
    static var dashboard: String { t("Dashboard", "Prehľad") }
    static var quickScanTitle: String { t("Quick Wound Scan", "Rýchly sken rany") }
    static var quickScanSubtitle: String { t("Start fast analysis", "Spustiť rýchlu analýzu") }
    static var createProfile: String { t("Create profile", "Vytvoriť profil") }
    static var viewPatients: String { t("Patients", "Pacienti") }
    static var browseHistories: String { t("Browse histories", "Prehliadať záznamy") }
    static var evidenceBasedAdvice: String { t("Evidence-based advice", "Odporúčania založené na dôkazoch") }

    // MARK: - Daily Tip strings
    static var dailyTipMoisture: String {
        t("Maintain moisture balance for faster healing.",
          "Udržiavajte rovnováhu vlhkosti pre rýchlejšie hojenie.")
    }
    static var dailyTipEdges: String {
        t("Assess wound edges for signs of maceration.",
          "Posudzujte okraje rany pre známky macerácie.")
    }
    static var dailyTipTIME: String {
        t("Use the TIME framework: Tissue, Infection, Moisture, Edge.",
          "Používajte rámec TIME: Tkanivo, Infekcia, Vlhkosť, Okraj.")
    }
    static var dailyTipGranulation: String {
        t("Granulation tissue is a sign of healing progress.",
          "Granulačné tkanivo je znakom postupu hojenia.")
    }
    static var dailyTipInfection: String {
        t("Check for signs of infection: redness, swelling, odor.",
          "Skontrolujte príznaky infekcie: začervenanie, opuch, zápach.")
    }
    static var dailyTipMeasure: String {
        t("Regularly measure wound size to monitor healing trends.",
          "Pravidelne merajte veľkosť rany na sledovanie trendov hojenia.")
    }
    static var dailyTipEpithelial: String {
        t("Epithelialization signals wound closure is near.",
          "Epitelizácia signalizuje blížiace sa uzatváranie rany.")
    }
    static var dailyTipDebridement: String {
        t("Sharp debridement can accelerate healing when indicated.",
          "Chirurgické odstránenie tkaniva môže pri indikácii urýchliť hojenie.")
    }
    static var dailyTipExudate: String {
        t("Excess exudate may indicate infection or delayed healing.",
          "Nadmerný exsudát môže naznačovať infekciu alebo spomalené hojenie.")
    }
    
    // MARK: - Tab Bar
    static var dashboardTab: String { t("Dashboard", "Prehľad") }
    static var analyticsTab: String { t("Analytics", "Analytika") }
    static var sharingTab: String { t("Sharing", "Zdieľanie") }
    
    // MARK: - Profile
    static var profileNavTitle: String { t("Profile", "Profil") }
    static var profileHeaderTitle: String { t("Your Profile", "Váš profil") }
    static var fullNameLabel: String { t("Full Name", "Celé meno") }
    static var emailLabel: String { t("Email", "Email") }
    static var joinedLabel: String { t("Joined", "Dátum registrácie") }
    static var contactSupport: String { t("Contact Support", "Kontaktovať podporu") }
    static var logOut: String { t("Log Out", "Odhlásiť sa") }
    static var unknownName: String { t("Unknown", "Neznáme") }
    
    // MARK: - Sharing / Received Cases
    static var receivedCasesTitle: String { t("Received Cases", "Prijaté prípady") }
    static var noReceivedCases: String { t("No received cases yet", "Zatiaľ žiadne prijaté prípady") }
    static func receivedFrom(_ email: String) -> String {
        t("Received from \(email)", "Prijaté od \(email)")
    }
    
    
    // MARK: - Share Case
    static var shareCaseTitle: String { t("Share Case", "Zdieľať prípad") }
    static var recipientSection: String { t("Recipient", "Príjemca") }
    static var doctorEmailPlaceholder: String { t("Doctor's Email", "E-mail lekára") }
    static var messageSection: String { t("Message", "Správa") }
    static var messagePlaceholder: String { t("Optional message", "Voliteľná správa") }
    static var shareCaseButton: String { t("Share Case", "Zdieľať prípad") }
    static var sharingInProgress: String { t("Sharing…", "Zdieľanie…") }
    
    
    // MARK: - Sharing (screen header + cards)
    static var caseSharingHeaderTitle: String {
        t("Sharing", "Zdieľanie")
    }
    static var caseSharingHeaderSubtitle: String {
        t("Easily share patient cases and wound data with colleagues for a second opinion or remote collaboration.",
          "Jednoducho zdieľajte prípady a údaje o ranách s kolegami na druhý názor alebo vzdialenú spoluprácu.")
    }

    static var shareNewCaseTitle: String {
        t("Share a New Case", "Zdieľať nový prípad")
    }
    static var shareNewCaseSubtitle: String {
        t("Send patient data securely", "Bezpečne odošlite údaje pacienta")
    }

    static var viewReceivedCasesTitle: String {
        t("View Received Cases", "Zobraziť prijaté prípady")
    }
    static var viewReceivedCasesSubtitle: String {
        t("Check referrals from colleagues", "Skontrolujte odporúčania od kolegov")
    }
    
    
    // MARK: - Privacy Policy
    static var privacyPolicyNavTitle: String {
        t("Privacy Policy", "Zásady ochrany osobných údajov")
    }
    static var privacyPolicyTitle: String {
        t("Privacy Policy v1.0", "Zásady ochrany osobných údajov v1.0")
    }
    static var privacyPolicyEffectiveDate: String {
        t("Effective Date: 16.6.2025", "Dátum účinnosti: 16.6.2025")
    }
    static var privacyIntro1: String {
        t("WoundPilot (\"we\", \"us\", or \"our\") is committed to protecting the privacy and security of our users’ personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (\"App\") and related services.",
          "WoundPilot („my“) sa zaväzuje chrániť súkromie a bezpečnosť osobných údajov našich používateľov. Tieto zásady vysvetľujú, ako zhromažďujeme, používame, zverejňujeme a chránime vaše údaje pri používaní našej mobilnej aplikácie („Aplikácia“) a súvisiacich služieb.")
    }
    static var privacyIntro2: String {
        t("By using the App, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree, please do not use the App.",
          "Používaním Aplikácie súhlasíte so zhromažďovaním a používaním informácií v súlade s týmito zásadami. Ak nesúhlasíte, Aplikáciu nepoužívajte.")
    }

    // 1. Information We Collect
    static var privacySection1Title: String {
        t("1. Information We Collect", "1. Aké údaje zhromažďujeme")
    }
    static var privacySection1Intro: String {
        t("We collect the following categories of personal and medical data through your use of WoundPilot:",
          "Pri používaní WoundPilot zhromažďujeme tieto kategórie osobných a medicínskych údajov:")
    }
    static var privacySection1Bullets: [String] {
        switch lang {
        case .en: return [
            "User Information: Name, Email address, Authentication details (via Firebase), Optional profile metadata",
            "Patient Information (added by the healthcare provider): Patient name, Medical conditions (e.g., diabetes), Wound-related metadata (location, timestamps, analysis details)",
            "Wound Image Data: Images of wounds captured via device camera or selected from gallery, Associated metadata: wound group name, anatomical location, size estimates, timestamps",
            "Usage Data: App usage patterns and interactions (non-identifiable, for performance improvement)"
        ]
        case .sk: return [
            "Informácie o používateľovi: Meno, e-mailová adresa, prihlasovacie údaje (cez Firebase), voliteľné údaje profilu",
            "Informácie o pacientovi (pridáva poskytovateľ zdravotnej starostlivosti): Meno pacienta, zdravotné stavy (napr. diabetes), metadáta o rane (poloha, časové pečiatky, údaje analýzy)",
            "Dáta obrázkov rán: Fotografie rán z kamery zariadenia alebo galérie, súvisiace metadáta: názov skupiny rán, anatomická poloha, odhady veľkosti, časové pečiatky",
            "Údaje o používaní: Vzory používania aplikácie a interakcie (neidentifikovateľné, na zlepšenie výkonu)"
        ]
        }
    }

    // 2. How We Use Your Information
    static var privacySection2Title: String {
        t("2. How We Use Your Information", "2. Ako používame vaše údaje")
    }
    static var privacySection2Intro: String {
        t("We may use collected data for the following purposes:",
          "Zhromaždené údaje môžeme používať na tieto účely:")
    }
    static var privacySection2Bullets: [String] {
        switch lang {
        case .en: return [
            "To operate and maintain the App",
            "To allow clinicians to document, monitor, and analyze wound healing",
            "To support AI-powered classification, measurement, and treatment recommendations",
            "To store and display patient-specific wound history securely",
            "To troubleshoot, improve, and personalize app functionality",
            "To comply with legal obligations"
        ]
        case .sk: return [
            "Na prevádzku a údržbu Aplikácie",
            "Aby klinikom umožnila dokumentovať, sledovať a analyzovať hojenie rán",
            "Na podporu klasifikácie, merania a odporúčaní liečby pomocou AI",
            "Na bezpečné ukladanie a zobrazovanie histórie rán konkrétneho pacienta",
            "Na riešenie problémov, zlepšovanie a prispôsobenie funkcií",
            "Na splnenie zákonných povinností"
        ]
        }
    }

    // 3. Data Storage and Security
    static var privacySection3Title: String {
        t("3. Data Storage and Security", "3. Ukladanie dát a bezpečnosť")
    }
    static var privacySection3Intro: String {
        t("All data is stored securely using Firebase Firestore and Firebase Storage. We implement industry-standard encryption (at rest and in transit) and authentication protocols to prevent unauthorized access.",
          "Všetky údaje sú bezpečne uložené v službách Firebase Firestore a Firebase Storage. Používame štandardné šifrovanie (pri ukladaní aj prenose) a autentifikačné protokoly na zabránenie neoprávnenému prístupu.")
    }
    static var privacySection3Bullets: [String] {
        switch lang {
        case .en: return [
            "Wound images are uploaded securely via HTTPS.",
            "Authentication is handled via Firebase Authentication with secure password handling.",
            "Access to patient data is restricted to authenticated users only.",
            "AI analysis is conducted either on-device (via CoreML) or securely in the cloud if applicable in the future."
        ]
        case .sk: return [
            "Obrázky rán sa nahrávajú bezpečne cez HTTPS.",
            "Autentifikáciu zaisťuje Firebase Authentication s bezpečnou správou hesiel.",
            "Prístup k údajom pacientov je povolený iba prihláseným používateľom.",
            "Analýza AI prebieha buď priamo v zariadení (CoreML), alebo bezpečne v cloude (ak bude relevantné)."
        ]
        }
    }

    // 4. Data Sharing and Disclosure
    static var privacySection4Title: String {
        t("4. Data Sharing and Disclosure", "4. Zdieľanie a zverejňovanie údajov")
    }
    static var privacySection4Intro: String {
        t("We do not sell, rent, or share any personal or patient information with third parties except in the following cases:",
          "Osobné údaje ani údaje o pacientoch nepredávame, neprenajímame ani nezdieľame s tretími stranami, okrem týchto prípadov:")
    }
    static var privacySection4Bullets: [String] {
        switch lang {
        case .en: return [
            "With user consent",
            "To comply with legal obligations, court orders, or law enforcement requests",
            "To trusted third-party services strictly for app functionality (e.g., Firebase)"
        ]
        case .sk: return [
            "So súhlasom používateľa",
            "Na splnenie zákonných povinností, súdnych príkazov alebo požiadaviek orgánov činných v trestnom konaní",
            "Spoľahlivým tretím stranám výlučne na účely fungovania aplikácie (napr. Firebase)"
        ]
        }
    }

    // 5. Data Retention
    static var privacySection5Title: String {
        t("5. Data Retention", "5. Uchovávanie údajov")
    }
    static var privacySection5Body1: String {
        t("We retain user and patient data only for as long as necessary to fulfill the purposes described in this policy, unless a longer retention period is required by law.",
          "Údaje používateľov aj pacientov uchovávame len po dobu nevyhnutnú na splnenie účelov opísaných v týchto zásadách, pokiaľ zákon nevyžaduje dlhšiu lehotu.")
    }
    static var privacySection5Body2: String {
        t("Users may request deletion of their account or specific data by contacting support at [Insert Contact Email].",
          "Používatelia môžu požiadať o vymazanie účtu alebo konkrétnych údajov kontaktovaním podpory na adrese [Vložte kontaktný e-mail].")
    }

    // 6. Children’s Privacy
    static var privacySection6Title: String {
        t("6. Children’s Privacy", "6. Ochrana súkromia detí")
    }
    static var privacySection6Body: String {
        t("WoundPilot is not intended for use by individuals under the age of 18. We do not knowingly collect data from minors. If you believe a minor’s data has been collected, please contact us for immediate removal.",
          "WoundPilot nie je určený pre osoby mladšie ako 18 rokov. Údaje od maloletých vedome nezhromažďujeme. Ak sa domnievate, že sme údaje maloletého získali, kontaktujte nás na ich okamžité odstránenie.")
    }

    // 7. User Rights
    static var privacySection7Title: String {
        t("7. User Rights", "7. Práva používateľov")
    }
    static var privacySection7Intro: String {
        t("As a user, you have the right to:", "Ako používateľ máte právo:")
    }
    static var privacySection7Bullets: [String] {
        switch lang {
        case .en: return [
            "Access and review your personal data",
            "Correct inaccurate or incomplete data",
            "Request deletion of your account or data",
            "Withdraw consent at any time"
        ]
        case .sk: return [
            "Získať prístup k svojim osobným údajom a skontrolovať ich",
            "Opraviť nepresné alebo neúplné údaje",
            "Požiadať o vymazanie účtu alebo údajov",
            "Kedykoľvek odvolať súhlas"
        ]
        }
    }
    static var privacySection7Contact: String {
        t("Please email info@woundpilot.com for data-related requests. We will respond within 30 days.",
          "Pre požiadavky týkajúce sa údajov napíšte na info@woundpilot.com. Odpovieme do 30 dní.")
    }

    // 8. International Users
    static var privacySection8Title: String {
        t("8. International Users", "8. Používatelia mimo SR/EÚ")
    }
    static var privacySection8Body: String {
        t("WoundPilot is currently intended for use within the European Union, and all data is stored in compliance with GDPR. If you access the app from outside this region, you do so at your own risk and are responsible for compliance with local laws.",
          "WoundPilot je v súčasnosti určený na používanie v rámci Európskej únie a všetky údaje sú spracúvané v súlade s GDPR. Ak aplikáciu používate mimo tohto regiónu, robíte tak na vlastné riziko a zodpovedáte za dodržiavanie miestnych zákonov.")
    }

    // 9. Policy Changes
    static var privacySection9Title: String {
        t("9. Policy Changes", "9. Zmeny zásad")
    }
    static var privacySection9Body: String {
        t("We may update this Privacy Policy to reflect changes in our practices or legal obligations. We will notify users of significant changes through the app interface or via email. Continued use of the app after changes constitutes acceptance of the updated policy.",
          "Tieto zásady môžeme aktualizovať v súvislosti so zmenami postupov alebo zákonných povinností. O významných zmenách budeme informovať v aplikácii alebo e-mailom. Pokračovaním v používaní aplikácie po zmenách vyjadrujete súhlas s aktualizovanými zásadami.")
    }

    // 10. Contact Us
    static var privacySection10Title: String {
        t("10. Contact Us", "10. Kontaktujte nás")
    }
    static var privacySection10Lead: String {
        t("For questions, concerns, or data requests, please contact:",
          "V prípade otázok, pripomienok alebo žiadostí o údaje nás kontaktujte:")
    }
    static var privacySection10Officer: String {
        t("WoundPilot Privacy Officer", "Zodpovedná osoba pre ochranu súkromia – WoundPilot")
    }
    static var privacySection10Email: String {
        t("Email: info@woundpilot.com", "E-mail: info@woundpilot.com")
    }
    
    // MARK: - Terms & Conditions
    static var termsNavTitle: String { t("Terms & Conditions", "Podmienky používania") }
    static var termsTitle: String { t("Terms & Conditions v1.0", "Podmienky používania v1.0") }
    static var termsEffectiveDate: String { t("Effective Date: [Insert Date]", "Dátum účinnosti: [Doplňte dátum]") }

    // Intro
    static var termsIntro1: String {
        t("These Terms and Conditions (\"Terms\") govern your use of the WoundPilot mobile application (\"App\") operated by [Your Company or Individual Name] (\"we\", \"us\", or \"our\").",
          "Tieto podmienky používania („Podmienky“) upravujú vaše používanie mobilnej aplikácie WoundPilot („Aplikácia“), ktorú prevádzkuje [Názov spoločnosti alebo meno] („my“).")
    }
    static var termsIntro2: String {
        t("By downloading, accessing, or using the App, you agree to be bound by these Terms. If you do not agree, you must not use the App.",
          "Stiahnutím, prístupom alebo používaním Aplikácie súhlasíte s týmito Podmienkami. Ak nesúhlasíte, Aplikáciu nepoužívajte.")
    }

    // 1. Use of the App
    static var terms1Title: String { t("1. Use of the App", "1. Používanie Aplikácie") }
    static var terms1Body1: String {
        t("You may use the App only for lawful purposes and in accordance with these Terms. The App is intended for use by licensed medical professionals, such as doctors and nurses, for the purpose of documenting and analyzing wound healing using photographs and metadata.",
          "Aplikáciu smiete používať len zákonným spôsobom a v súlade s týmito Podmienkami. Je určená pre licencovaných zdravotníkov (lekárov, sestry) na dokumentáciu a analýzu hojenia rán pomocou fotografií a metadát.")
    }
    static var terms1Body2: String {
        t("You are responsible for ensuring that all information entered into the App is accurate, complete, and in compliance with applicable medical guidelines and privacy laws.",
          "Zodpovedáte za to, že všetky údaje zadané do Aplikácie sú presné, úplné a v súlade s príslušnými medicínskymi odporúčaniami a zákonmi o ochrane súkromia.")
    }

    // 2. Account Registration
    static var terms2Title: String { t("2. Account Registration", "2. Registrácia účtu") }
    static var terms2Body1: String {
        t("To use the App, you must register for an account via Firebase Authentication. You agree to provide accurate and current information during registration and to keep your credentials secure.",
          "Na používanie Aplikácie je potrebné zaregistrovať účet cez Firebase Authentication. Pri registrácii poskytnete pravdivé a aktuálne údaje a budete chrániť svoje prihlasovacie údaje.")
    }
    static var terms2Body2: String {
        t("You are solely responsible for all activity under your account. If you suspect unauthorized access, you must notify us immediately.",
          "Za všetky aktivity na svojom účte zodpovedáte výlučne vy. V prípade podozrenia na neoprávnený prístup nás okamžite kontaktujte.")
    }

    // 3. Medical Disclaimer
    static var terms3Title: String { t("3. Medical Disclaimer", "3. Zdravotné upozornenie") }
    static var terms3Body1: String {
        t("The App is intended to assist, not replace, clinical judgment. Any AI-powered analysis, wound classification, size estimation, or treatment recommendation is for informational purposes only and must be reviewed by a qualified healthcare provider before being applied to clinical care.",
          "Aplikácia má pomáhať, nie nahrádzať klinické rozhodovanie. Analýzy a odporúčania AI sú len informatívne a pred použitím v klinickej praxi ich musí posúdiť kvalifikovaný zdravotník.")
    }
    static var terms3Body2: String {
        t("We do not provide medical advice, and we are not liable for any clinical decisions made using information from the App.",
          "Neposkytujeme lekárske poradenstvo a nenesieme zodpovednosť za klinické rozhodnutia urobené na základe informácií z Aplikácie.")
    }

    // 4. User Content and Conduct
    static var terms4Title: String { t("4. User Content and Conduct", "4. Obsah používateľa a správanie") }
    static var terms4Body1: String {
        t("By uploading wound images, patient metadata, or any other content (\"User Content\"), you grant us a limited, non-exclusive license to use that content for the operation of the App. You must have the necessary permissions to upload such content, especially in cases involving patient data.",
          "Nahraním fotografií rán, metadát pacienta alebo iného obsahu („Používateľský obsah“) nám udeľujete obmedzenú, nevýhradnú licenciu na jeho použitie na účely prevádzky Aplikácie. Musíte mať potrebné povolenia, najmä pri údajoch o pacientoch.")
    }
    static var terms4Body2: String {
        t("You agree not to upload any content that is unlawful, defamatory, obscene, or violates any third-party rights.",
          "Nebudete nahrávať obsah, ktorý je nezákonný, hanlivý, obscénny alebo porušuje práva tretích strán.")
    }

    // 5. Data Privacy and Security
    static var terms5Title: String { t("5. Data Privacy and Security", "5. Ochrana osobných údajov a bezpečnosť") }
    static var terms5Body1: String {
        t("We process personal data in accordance with our Privacy Policy. You agree that by using the App, your data (including patient data) may be stored and processed securely via Firebase services, subject to encryption and authentication controls.",
          "Osobné údaje spracúvame podľa našich Zásad ochrany osobných údajov. Súhlasíte, že pri používaní Aplikácie môžu byť vaše údaje (vrátane údajov o pacientoch) bezpečne spracúvané a ukladané v službách Firebase so šifrovaním a autentifikáciou.")
    }
    static var terms5Body2: String {
        t("It is your responsibility to obtain any necessary consents or legal bases before uploading personal health information.",
          "Pred nahratím zdravotných údajov je vašou povinnosťou zabezpečiť potrebné súhlasy alebo právne základy.")
    }

    // 6. Intellectual Property
    static var terms6Title: String { t("6. Intellectual Property", "6. Duševné vlastníctvo") }
    static var terms6Body1: String {
        t("All content, trademarks, software code, and materials within the App (excluding User Content) are owned by or licensed to us and protected by intellectual property laws. You may not reproduce, distribute, or create derivative works without our express permission.",
          "Všetok obsah, ochranné známky, softvérový kód a materiály v Aplikácii (okrem Používateľského obsahu) sú naším vlastníctvom alebo máme na ne licenciu a sú chránené právami duševného vlastníctva. Bez nášho výslovného súhlasu ich nemožno reprodukovať, šíriť ani vytvárať odvodené diela.")
    }

    // 7. Termination
    static var terms7Title: String { t("7. Termination", "7. Ukončenie používania") }
    static var terms7Body1: String {
        t("We may suspend or terminate your access to the App at any time, with or without notice, if you violate these Terms or misuse the platform. Upon termination, your right to use the App will cease immediately.",
          "Môžeme dočasne pozastaviť alebo ukončiť váš prístup k Aplikácii kedykoľvek, s oznámením alebo bez neho, ak porušíte tieto Podmienky alebo platformu zneužívate. Po ukončení okamžite zaniká vaše právo Aplikáciu používať.")
    }

    // 8. Limitation of Liability
    static var terms8Title: String { t("8. Limitation of Liability", "8. Obmedzenie zodpovednosti") }
    static var terms8Body1: String {
        t("To the fullest extent permitted by law, we disclaim all warranties and liability arising from your use of the App. We are not responsible for any direct, indirect, incidental, or consequential damages resulting from App use, errors, or reliance on AI-generated outputs.",
          "V najširšom rozsahu povolenom zákonom sa zriekneme všetkých záruk a zodpovednosti vyplývajúcich z používania Aplikácie. Nenesieme zodpovednosť za priame ani nepriame škody, následné či náhodné škody spôsobené používaním Aplikácie, chybami alebo spoliehaním sa na výstupy AI.")
    }

    // 9. Modifications
    static var terms9Title: String { t("9. Modifications", "9. Zmeny podmienok") }
    static var terms9Body1: String {
        t("We reserve the right to modify or update these Terms at any time. Continued use of the App after changes are published constitutes your acceptance of the updated Terms.",
          "Vyhradzujeme si právo tieto Podmienky kedykoľvek upraviť alebo aktualizovať. Pokračovaním v používaní Aplikácie po zverejnení zmien vyjadrujete súhlas s aktualizovanými Podmienkami.")
    }

    // 10. Governing Law
    static var terms10Title: String { t("10. Governing Law", "10. Rozhodné právo") }
    static var terms10Body1: String {
        t("These Terms shall be governed by and construed in accordance with the laws of [Insert Jurisdiction]. Any disputes arising under or related to these Terms shall be resolved in the courts of [Insert Location].",
          "Tieto Podmienky sa riadia právom [Doplňte jurisdikciu]. Spory vyplývajúce z týchto Podmienok alebo s nimi súvisiace sa budú riešiť na súdoch v [Doplňte miesto].")
    }

    // 11. Contact
    static var terms11Title: String { t("11. Contact", "11. Kontakt") }
    static var terms11Lead: String {
        t("For any questions, concerns, or disputes, please contact us at:",
          "V prípade otázok, pripomienok alebo sporov nás kontaktujte na:")
    }
    static var terms11Email: String { t("Email: [Insert Contact Email]", "E-mail: [Doplňte kontaktný e-mail]") }
    static var terms11Address: String { t("Mailing Address: [Insert Address if required]", "Poštová adresa: [Doplňte adresu, ak je potrebné]") }
    
    // MARK: - Auth / Password Reset
    static var resetPasswordTitle: String { t("Reset Password", "Obnovenie hesla") }
    static var enterEmailPlaceholder: String { t("Enter your email", "Zadajte svoj e-mail") }
    static var sendResetEmailButton: String { t("Send Reset Email", "Odoslať e-mail na obnovenie") }
    static var backToLoginButton: String { t("Back to Login", "Späť na prihlásenie") }
    static var enterEmailError: String { t("Please enter your email.", "Prosím, zadajte svoj e-mail.") }
    static var resetEmailSentMessage: String { t("Password reset email sent.", "E-mail na obnovenie hesla bol odoslaný.") }
    
    // MARK: - Auth / Login
    static var loginTitle: String { t("Login", "Prihlásenie") }
    static var noAccountRegister: String { t("No account? Register here", "Nemáte účet? Zaregistrujte sa") }
    static var passwordRequirement: String {
        t("Must be 8+ characters with uppercase, lowercase, number & symbol.",
          "Min. 8 znakov vrátane veľkého a malého písmena, čísla a symbolu.")
    }
    static var fixValidationFirst: String {
        t("Fix validation errors first.", "Najprv opravte chyby validácie.")
    }
    
    // MARK: - Auth / Register
    static var registerTitle: String { t("Register", "Registrácia") }
    static var emailPasswordRequired: String {
        t("Email and password are required.", "E-mail a heslo sú povinné.")
    }
    static var fullNameRequired: String {
        t("Full name is required.", "Celé meno je povinné.")
    }
    static var mustAgreeToTerms: String {
        t("You must agree to the Terms and Privacy Policy.", "Musíte súhlasiť s Podmienkami a Zásadami ochrany osobných údajov.")
    }

    // Terms/Privacy line
    static var iAgreePrefix: String { t("I agree to the ", "Súhlasím s ") }
    static var andPrefix: String { t("and ", "a ") }
    static var termsLinkText: String { t("Terms & Conditions", "Podmienkami používania") }
    static var privacyLinkText: String { t("Privacy Policy", "Zásadami ochrany osobných údajov") }
    static var cm2Unit: String { t("cm²", "cm²")}
    // Firestore save error
    static func savingAgreementError(_ details: String) -> String {
        t("Error saving agreement: \(details)", "Chyba pri ukladaní súhlasu: \(details)")
    }
    
    
    // MARK: - Add Patient
    static var patientInformationSection: String { t("Patient Information", "Údaje o pacientovi") }
    static var optionalClinicalInfoSection: String { t("Optional Clinical Info", "Voliteľné klinické údaje") }
    static var sexLabel: String { t("Sex", "Pohlavie") }
    static var sexUnspecified: String { t("Unspecified", "Neurčené") }
    static var sexMale: String { t("Male", "Muž") }
    static var sexFemale: String { t("Female", "Žena") }
    static var diabetic: String { t("Diabetic", "Diabetik") }
    static var smoker: String { t("Smoker", "Fajčiar") }
    static var peripheralArteryDisease: String { t("Peripheral Artery Disease", "Periférne arteriálne ochorenie") }
    static var mobilityIssues: String { t("Mobility Issues", "Problémy s pohyblivosťou") }
    static var bloodPressureIssues: String { t("Blood Pressure Issues", "Problémy s krvným tlakom") }
    static var weightKgPlaceholder: String { t("Weight (kg)", "Hmotnosť (kg)") }
    static var knownAllergiesPlaceholder: String { t("Known Allergies", "Známe alergie") }
    static var saving: String { t("Saving...", "Ukladá sa…") }
    static var savePatient: String { t("Save Patient", "Uložiť pacienta") }
    static var userNotLoggedIn: String { t("User not logged in.", "Používateľ nie je prihlásený.") }
    static func failedToSave(_ details: String) -> String {
        t("Failed to save: \(details)", "Uloženie zlyhalo: \(details)")
    }
    static var patientSavedSuccessfully: String { t("Patient saved successfully!", "Pacient bol úspešne uložený!") }
    
    
    // MARK: - Edit Patient
    static var editPatientTitle: String { t("Edit Patient", "Upraviť pacienta") }
    static var basicInfoSection: String { t("Basic Info", "Základné informácie") }
    static var clinicalDetailsSection: String { t("Clinical Details", "Klinické údaje") }
    static var saveChangesButton: String { t("Save Changes", "Uložiť zmeny") }
    static func failedToUpdate(_ details: String) -> String {
        t("Failed to update: \(details)", "Aktualizácia zlyhala: \(details)")
    }
    
    
    // MARK: - Patient Detail
    static var patientDetailsTitle: String { t("Patient Details", "Detail pacienta") }
    static var patientOverview: String { t("Patient Overview", "Prehľad pacienta") }
    static var viewPatientInfo: String { t("View Patient Info", "Zobraziť údaje pacienta") }
    static var woundManagement: String { t("Wound Management", "Manažment rán") }
    static var newWoundEntry: String { t("New Wound Entry", "Nový záznam rany") }
    static var viewWoundHistory: String { t("View Wound History", "Zobraziť históriu rán") }
    
    
    // MARK: - Patient Info Screen
    static var patientInfoTitle: String { t("Patient Info", "Údaje pacienta") }
    static var editPatientInfo: String { t("Edit Patient Info", "Upraviť údaje pacienta") }
    static var weightLabel: String { t("Weight", "Hmotnosť") }
    static var kgUnit: String { t("kg", "kg") }
    static var allergiesLabel: String { t("Allergies", "Alergie") }

    // MARK: - Patient List
    static var yourPatientsTitle: String { t("Your Patients", "Vaši pacienti") }
    static var loadingPatients: String { t("Loading patients...", "Načítavajú sa pacienti…") }
    static var noPatientsFound: String { t("No patients found", "Nenašli sa žiadni pacienti") }
    static var startByAddingPatient: String { t("Start by adding a patient.", "Začnite pridaním pacienta.") }
    static var searchPatientsPrompt: String { t("Search patients by name", "Hľadajte pacienta podľa mena") }

    static var deletePatientAlertTitle: String {
        t("Delete this patient and all their wound photos?", "Odstrániť tohto pacienta a všetky fotky rán?")
    }
    static var deleteAction: String { t("Delete", "Odstrániť") }
    static var deletePatientAction: String { t("Delete Patient", "Odstrániť pacienta") }

    static func failedToLoadPatients(_ details: String) -> String {
        t("Failed to load patients: \(details)", "Načítanie pacientov zlyhalo: \(details)")
    }
    static func failedToDeletePatient(_ details: String) -> String {
        t("Error deleting patient: \(details)", "Chyba pri odstraňovaní pacienta: \(details)")
    }
    // MARK: - AI Analysis
    static var analysisReportTitle: String { t("Analysis Report", "Správa z analýzy") }
    static var diagnosisField: String { t("Diagnosis", "Diagnóza") }
    static var woundTypeField: String { t("Wound Type", "Typ rany") }
    static var healingStageField: String { t("Healing Stage", "Fáza hojenia") }
    static var woundStageField: String { t("Wound Stage", "Stupeň rany") }
    static var etiologyField: String { t("Etiology", "Etiológia") }
    static var recommendedTreatment: String { t("Recommended Treatment", "Odporúčaná liečba") }
    static var shareAction: String { t("Share", "Zdieľať") }
    static var downloadAction: String { t("Download", "Stiahnuť") }

    // Sample AI values (dummy placeholders that localize)
    static var sampleDiagnosis: String {
        t("Chronic Venous Leg Ulcer", "Chronický venózny vred predkolenia")
    }
    static var sampleWoundType: String {
        t("Venous Ulcer", "Venózny vred")
    }
    static var sampleHealingStage: String {
        t("Granulating", "Granulujúca fáza")
    }
    static var sampleWoundStage: String {
        t("Stage 2", "Stupeň 2")
    }
    static var sampleEtiology: String {
        t("Poor venous return due to varicose veins", "Zhoršený venózny návrat v dôsledku varixov")
    }
    static var sampleTreatmentRecommendations: [String] {
        switch lang {
        case .en:
            return [
                "Clean wound gently with sterile saline",
                "Apply appropriate compression therapy",
                "Monitor closely for signs of infection",
                "Schedule reassessment in 7 days"
            ]
        case .sk:
            return [
                "Jemne vyčistite ranu sterilným fyziologickým roztokom",
                "Aplikujte primeranú kompresívnu terapiu",
                "Pozorne sledujte príznaky infekcie",
                "Naplánujte kontrolu o 7 dní"
            ]
        }
    }
    
    
    static var continueCTA: String { t("Continue", "Pokračovať") }
    static var authChooserTitle: String { t("Your account", "Váš účet") }
    static var authChooserSubtitle: String { t("Sign in to continue, or create a new account.", "Prihláste sa alebo si vytvorte nový účet.") }
    // MARK: - Image Confirmation
    static var confirmWoundPhotoTitle: String {
        t("Confirm Wound Photo", "Potvrďte fotografiu rany")
    }
    static var confirmWoundPhotoSubtitle: String {
        t("Make sure the photo is clear and ruler is visible.", "Uistite sa, že fotografia je ostrá a pravítko je viditeľné.")
    }
    static var retakeButton: String { t("Retake", "Znova odfotiť") }
    static var usePhotoButton: String { t("Use Photo", "Použiť fotografiu") }
    
    
    // MARK: - Prepare Wound Analysis
    static var prepare3StepsTitle: String {
        t("You're just 3 steps away from an AI-powered wound evaluation.",
          "Od AI hodnotenia rany vás delia už len 3 kroky.")
    }
    static var getStartedNavTitle: String { t("Get Started", "Začíname") }
    static var continueButton: String { t("Continue", "Pokračovať") }

    static func stepN(_ n: Int) -> String {
        switch lang {
        case .en: return "Step \(n)"
        case .sk: return "Krok \(n)"
        }
    }
    static var selectWoundLocation: String { t("Select wound location", "Vyberte umiestnenie rany") }
    static var answerClinicalQuestions: String { t("Answer clinical questions", "Zodpovedzte klinické otázky") }
    static var aiAnalyzesWound: String { t("AI analyzes wound", "AI analyzuje ranu") }
    
    
    // MARK: - Preparing Analysis
    static var analyzingSizeProgress: String {
        t("Analysing size…", "Analyzuje sa veľkosť…")
    }
    
    
    // MARK: - Clinical Questionnaire
    static var clinicalQuestionnaireTitle: String {
        t("Clinical Questionnaire", "Klinický dotazník")
    }
    static var qPatientHasDiabetes: String {
        t("Patient has diabetes", "Pacient má cukrovku")
    }
    static var qWoundShowsInfection: String {
        t("Wound shows signs of infection", "Rana vykazuje známky infekcie")
    }
    static var qWoundHasExudate: String {
        t("Wound has exudate (fluid)", "Rana má exsudát (tekutinu)")
    }
    static var qWoundAgeDays: String {
        t("Wound age (in days)", "Vek rany (v dňoch)")
    }
    static var enterNumberPlaceholder: String { t("Enter number", "Zadajte číslo") }
    static var qPainLevelLabel: String { t("Pain level (0–10)", "Úroveň bolesti (0–10)") }
    static var qPainLevelPickerTitle: String { t("Pain level", "Úroveň bolesti") }
    static var continueToAIAnalysisButton: String {
        t("Continue to AI Analysis", "Pokračovať na AI analýzu")
    }
    static var enterValidDaysError: String {
        t("Please enter a valid number of days", "Zadajte platný počet dní")
    }
    // MARK: - Wound Detail
    static var analyzeWound: String { t("Analyze Wound", "Analyzovať ranu") }
    static var woundEntryTitle: String { t("Wound Entry", "Záznam rany") }
    
    // MARK: - Size Analysis
    static var sizeAnalysisTitle: String { t("Size Analysis", "Analýza veľkosti") }
    static var estimatedWoundSize: String { t("Estimated Wound Size", "Odhadovaná veľkosť rany") }
    static var widthLabel: String { t("Width", "Šírka") }
    static var heightLabel: String { t("Height", "Výška") }
    static var editSizeManually: String { t("Edit Size Manually", "Upraviť veľkosť manuálne") }
    static var enterWidthCm: String { t("Enter Width (cm)", "Zadajte šírku (cm)") }
    static var enterHeightCm: String { t("Enter Height (cm)", "Zadajte výšku (cm)") }
    static var cmUnit: String { t("cm", "cm") } // unit stays the same
    
    
    
    // MARK: - Wound Detail (Group)
    static var woundDetailsTitle: String { t("Wound Details", "Detaily rán") }
    static var healingProgress: String { t("Healing Progress", "Priebeh hojenia") }
    static var notEnoughDataForGraph: String { t("Not enough data for graph.", "Nedostatok údajov pre graf.") }

    static var deleteGroupAction: String { t("Delete Group", "Odstrániť skupinu") }
    
    static var deleteAllAction: String { t("Delete All", "Odstrániť všetko") }
    

    static var deleteWoundPhotoAlertTitle: String {
        t("Delete this wound photo?", "Odstrániť túto fotku rany?")
    }
    static var cannotBeUndone: String {
        t("This cannot be undone.", "Túto akciu nemožno vrátiť späť.")
    }

    static var deleteAllInGroupAlertTitle: String {
        t("Delete ALL photos in this group?", "Odstrániť VŠETKY fotky v tejto skupine?")
    }
    static func deleteAllInGroupWarning(_ groupName: String) -> String {
        t("This will permanently delete all wound entries in '\(groupName)'.",
          "Týmto sa natrvalo odstránia všetky záznamy rán v „\(groupName)“.")
    }
    
    // MARK: - Wound Group Picker
    static var selectWoundGroupTitle: String { t("Select Wound Group", "Vyberte skupinu rán") }
    static var groupWoundImagesTitle: String { t("Group Wound Images", "Zoskupujte fotografie rán") }
    static var groupWoundImagesSubtitle: String {
        t("Track healing by grouping images of the same wound area, like 'Left Heel'.",
          "Sledujte hojenie zoskupením fotiek tej istej rany, napríklad „Ľavá päta“.")
    }
    static var existingWoundGroups: String { t("Existing Wound Groups", "Existujúce skupiny rán") }
    static var noGroupsYetForPatient: String { t("No groups yet for this patient.", "Pre tohto pacienta zatiaľ nie sú žiadne skupiny.") }
    static var tapToContinue: String { t("Tap to continue", "Ťuknite pre pokračovanie") }
    static var createNewWoundGroup: String { t("Create New Wound Group", "Vytvoriť novú skupinu rán") }
    static var exampleLeftFootUlcerPlaceholder: String { t("e.g. Left Foot Ulcer", "napr. Vred na ľavej nohe") }
    static var createAndContinue: String { t("Create and Continue", "Vytvoriť a pokračovať") }
    
    // MARK: - Wound Image Source
    static var newWoundTitle: String { t("New Wound", "Nová rana") }
    static var takePhoto: String { t("Take Photo", "Odfotiť") }
    static var takePhotoCaption: String { t("Use your camera in real time", "Použite fotoaparát v reálnom čase") }
    static var choosePhoto: String { t("Choose Photo", "Vybrať fotografiu") }
    static var choosePhotoCaption: String { t("Pick an existing photo from gallery", "Vyberte existujúcu fotografiu z galérie") }
    static var useDummyWoundImage: String { t("Use Dummy Wound Image", "Použiť ukážkovú fotku rany") }
    static var simulatorOnlyTestingImage: String { t("Simulator-only testing image", "Obrázok len pre simulátor") }
    
    
    // MARK: - Wound List
    static var myWoundsTitle: String { t("My Wounds", "Moje rany") }
    static var loadingWounds: String { t("Loading wounds...", "Načítavajú sa rany…") }
    static var noWoundsYet: String { t("No wounds uploaded yet.", "Zatiaľ neboli nahrané žiadne rany.") }
    static var unnamedWound: String { t("Unnamed Wound", "Nepomenovaná rana") }
    static var lastUpdateLabel: String { t("Last update:", "Posledná aktualizácia:") }
    
    
    // MARK: - Wound Location Picker
    static var selectWoundLocationTitle: String { t("Select Wound Location", "Vyberte umiestnenie rany") }
    static var confirmSelection: String { t("Confirm Selection", "Potvrdiť výber") }
    
    static var confirm: String { t("Confirm", "Potvrdiť") }
    static var fastCaptureName: String { t("Fast Capture", "Rýchle zachytenie") }
    static var profile: String { t("Profile", "Profil") }
    static var start: String { t("Start", "Štart") }
    
    static var shareCaseNavTitle: String {
            t("Share Case", "Zdieľať prípad")
        }
    static var shareCaseSubtitle: String {
            t("Securely share case details with a colleague.",
              "Bezpečne odošlite údaje prípadu kolegovi.")
        }
    static var cancelButton: String {
            t("Cancel", "Zrušiť")
        }
    static var smokerShort: String   { t("Smoker", "Fajčiar") }
    // Greeting under the Dashboard title
    static func welcomeBack(_ name: String) -> String {
        t("Welcome back, \(name)", "Vitajte späť, \(name)")
    }

    // Section title above the chips row
    static var recentPatientsTitle: String {
        t("Recent patients", "Nedávni pacienti")
    }

    // Small link on the right of that row
    static var seeAll: String {
        t("See all", "Zobraziť všetko")
    }

    // Banner text for pending reviews (simple pluralization)
    static func pendingReviewsCount(_ n: Int) -> String {
        if n == 1 {
            return t("1 case awaiting review", "1 prípad čaká na kontrolu")
        } else if (2...4).contains(n) {
            return t("\(n) cases awaiting review", "\(n) prípady čakajú na kontrolu")
        } else {
            return t("\(n) cases awaiting review", "\(n) prípadov čaká na kontrolu")
        }
    }
    
    // MARK: - Photo Guide (Tips card on ImageConfirmationView)
    static var photoGuideTitle: String {
        t("Tips for a good wound photo", "Tipy pre dobrú fotku rany")
    }
    static var photoGuideTipCaptureCenter: String {
        t("Capture the entire wound centered in the frame.",
          "Zachyťte celú ranu, nech je uprostred záberu.")
    }
    static var photoGuideTipAddScale: String {
        t("Add a scale (ruler or finger) next to the wound.",
          "Pridajte mierku (pravítko alebo prst) vedľa rany.")
    }
    static var photoGuideTipLighting: String {
        t("Ensure good light: near a window, avoid strong shadows.",
          "Dostatok svetla: pri okne, bez silného tieňa.")
    }
    static var photoGuideTipTopDown: String {
        t("Shoot top-down (perpendicular), not at an angle.",
          "Foťte kolmo zhora – nie pod uhlom.")
    }
    static var photoGuideTipCleanLens: String {
        t("Clean the camera lens.",
          "Vyčistite objektív.")
    }
    static var photoGuideTipRemoveObstructions: String {
        t("Remove obstructions: gauze, glove, glare.",
          "Odstráňte prekážky: gáza, rukavica, odlesky.")
    }
    
    static var qTitle: String { t("Clinical Questionnaire", "Klinický dotazník") }
        static var btnContinue: String { t("Continue", "Pokračovať") }

        // Sections
        static var secEtiology: String { t("Etiology (pick one)", "Etiológia (vyberte jednu)") }
        static var secDuration: String { t("Duration", "Trvanie") }
        static var secTissue: String { t("Tissue", "Tkanivo") }
        static var secInfection: String { t("Infection / Inflammation", "Infekcia / zápal") }
        static var secMoisture: String { t("Moisture", "Vlhkosť") }
        static var secEdge: String { t("Edge", "Okraje rany") }
        static var secPerfusion: String { t("Perfusion", "Perfúzia") }
        static var secComorbidities: String { t("Comorbidities", "Komorbidity") }
        static var secRedFlags: String { t("Red flags", "Varovné príznaky") }

        // Rows / toggles
        static var rowExposedBone: String { t("Exposed bone", "Odhalená kosť") }
        static var rowProbeToBone: String { t("Probe-to-bone positive", "Pozitívne sonda na kosť") }
        static var rowPulses: String { t("Foot pulses", "Pulzy na nohe") }

        // Shared options
        static var optYes: String { t("Yes", "Áno") }
        static var optNo: String { t("No", "Nie") }
        static var optUnknown: String { t("Unknown", "Nevedno") }

        // Etiology options
        static var optEtiologyVenous: String   { t("Venous", "Venózna") }
        static var optEtiologyArterial: String { t("Arterial", "Arteriálna") }
        static var optEtiologyDiabetic: String { t("Diabetic foot", "Diabetická noha") }
        static var optEtiologyPressure: String { t("Pressure", "Preležanina") }
        static var optEtiologyTrauma: String   { t("Trauma", "Trauma") }
        static var optEtiologySurgical: String { t("Surgical", "Pooperačná") }

        // Duration options
        static var optDurationLt4w: String  { t("< 4 weeks", "< 4 týždne") }
        static var optDuration4to12: String { t("4–12 weeks", "4–12 týždňov") }
        static var optDurationGt12w: String { t("> 12 weeks", "> 12 týždňov") }

        // Tissue options
        static var optTissueGranulation: String { t("Granulation", "Granulácia") }
        static var optTissueSlough: String      { t("Slough", "Fibrín / povlak") }
        static var optTissueNecrosis: String    { t("Necrosis", "Nekróza") }

        // Infection options
        static var optInfectionNone: String     { t("None", "Žiadna") }
        static var optInfectionLocal: String    { t("Local", "Lokálna") }
        static var optInfectionSystemic: String { t("Systemic", "Systémová") }

        // Moisture options
        static var optMoistureDry: String      { t("Dry", "Suchá") }
        static var optMoistureLow: String      { t("Low", "Nízka") }
        static var optMoistureModerate: String { t("Moderate", "Stredná") }
        static var optMoistureHigh: String     { t("High", "Vysoká") }

        // Edge options
        static var optEdgeAttached: String   { t("Attached", "Priľahlé") }
        static var optEdgeRolled: String     { t("Rolled", "Zahrnuté/rolované") }
        static var optEdgeUndermined: String { t("Undermined", "Podmínované") }

        // ABI options
        static var optAbiGE0_8: String     { t("ABI ≥ 0.8", "ABI ≥ 0,8") }
        static var optAbi0_5to0_79: String { t("ABI 0.5–0.79", "ABI 0,5–0,79") }
        static var optAbiLT0_5: String     { t("ABI < 0.5", "ABI < 0,5") }

        // Comorbidities
        static var optCoDiabetes: String   { t("Diabetes", "Diabetes") }
        static var optCoPAD: String        { t("Peripheral arterial disease", "Periférne artériové ochorenie") }
        static var optCoNeuropathy: String { t("Neuropathy", "Neuropatia") }
        static var optCoImmuno: String     { t("Immunosuppressed", "Imunosupresia") }
        static var optCoAnticoag: String   { t("Anticoagulants", "Antikoagulanciá") }

        // Red flags
        static var optRFSpread: String   { t("Spreading erythema", "Šíriace sa začervenanie") }
        static var optRFPain: String     { t("Severe pain out of proportion", "Silná bolesť neprimeraná nálezu") }
        static var optRFCrepitus: String { t("Crepitus / gas", "Krepitácie / plyn") }
        static var optRFSystemic: String { t("Systemically unwell (fever, rigors)", "Systémové príznaky (horúčka, triaška)") }

    static func answeredProgress(_ answered: Int, _ total: Int) -> String {
            t("Answered \(answered) / \(total)", "Zodpovedaných \(answered) / \(total)")
        }
        static func reviewProgress(_ answered: Int, _ total: Int) -> String {
            t("\(answered)/\(total) sections answered • Finish anyway",
              "\(answered)/\(total) sekcií hotových • Dokončiť aj tak")
        }

        // Top banners (urgent states)
        static var bannerUrgentAssessment: String {
            t("Urgent assessment required", "Vyžaduje sa urgentné vyšetrenie")
        }
        static var bannerSevereIschaemia: String {
            t("Severe ischemia suspected (ABI < 0.5) — urgent vascular referral.",
              "Pravdepodobná ťažká ischémia (ABI < 0,5) — urgentné cievne vyšetrenie.")
        }

        // Inline guardrail badges
        static var badgeCompressionContraindicated: String {
            t("Compression contraindicated (ABI < 0.5)", "Kompresia kontraindikovaná (ABI < 0,5)")
        }
        static var badgeSystemicInfectionUrgent: String {
            t("Systemic infection — urgent management", "Systémová infekcia — nutný urgentný postup")
        }
        static var badgeProbeToBone: String {
            t("Probe-to-bone positive — suspect osteomyelitis",
              "Pozitívna sonda na kosť — myslite na osteomyelitídu")
        }
        static var badgeRedFlagsEscalate: String {
            t("Red flags present — escalate care", "Prítomné varovné príznaky — nutná eskalácia starostlivosti")
        }
    
    static var preparingAnalysis: String {
            t("Preparing analysis…", "Pripravuje sa analýza…")
        }
        static var failedToLoadAnalysis: String {
            t("Failed to load analysis.", "Analýzu sa nepodarilo načítať.")
        }
        static var retryAction: String {
            t("Retry", "Skúsiť znova")
        }
        static var noQuestionnaireFound: String {
            t("No questionnaire found.", "Dotazník sa nenašiel.")
        }

       
        

        // Wound Type labels
        static var woundTypeVenous: String       { t("Venous ulcer", "Venózny vred") }
        static var woundTypeArterial: String     { t("Arterial ulcer", "Arteriálny vred") }
        static var woundTypeDFU: String          { t("Diabetic foot ulcer", "Diabetický vred nohy") }
        static var woundTypePressure: String     { t("Pressure injury", "Preležanina") }
        static var woundTypeTrauma: String       { t("Traumatic wound", "Traumatická rana") }
        static var woundTypeSurgical: String     { t("Surgical wound", "Pooperačná rana") }
        static var woundTypeUnspecified: String  { t("Unspecified wound", "Nešpecifikovaná rana") }

        // Healing Stage labels
        static var healingGranulating: String        { t("Granulating", "Granulujúca fáza") }
        static var healingSloughInflamed: String     { t("Sloughy / inflamed", "Povlak / zápal") }
        static var healingNecroticIschemic: String   { t("Necrotic / ischemic", "Nekrotická / ischemická") }
        static var healingNotDefined: String         { t("Not defined", "Nedefinované") }

        // Wound Stage labels
        static var woundStageNotStaged: String       { t("Not staged", "Nestupňované") }
        static var woundStageWagnerSuspected: String { t("Likely Wagner 2–3 (suspected)", "Pravdepodobne Wagner 2–3 (predpoklad)") }

        // Diagnosis lines
        static var dxArterialCLI: String         { t("Arterial ulcer with critical limb ischemia", "Arteriálny vred s kritickou ischémiou končatiny") }
        static var dxVenousLegUlcer: String      { t("Venous leg ulcer", "Venózny vred predkolenia") }
        static var dxDFULocalInfection: String   { t("Diabetic foot ulcer with local infection", "Diabetický vred nohy s lokálnou infekciou") }
        static var dxVenousGeneric: String       { t("Venous leg ulcer", "Venózny vred predkolenia") }
        static var dxArterialGeneric: String     { t("Arterial ulcer", "Arteriálny vred") }
        static var dxDFUGeneric: String          { t("Diabetic foot ulcer", "Diabetický vred nohy") }
        static var dxPressureGeneric: String     { t("Pressure injury", "Preležanina") }
        static var dxTraumaGeneric: String       { t("Traumatic wound", "Traumatická rana") }
        static var dxSurgicalGeneric: String     { t("Surgical wound", "Pooperačná rana") }
        static var dxUnspecified: String         { t("Wound (unspecified)", "Rana (nešpecifikované)") }

        // Etiology one-liners
        static var etiologyLineVenous: String    { t("Poor venous return / venous hypertension", "Zhoršený venózny návrat / venózna hypertenzia") }
        static var etiologyLineArterial: String  { t("Peripheral arterial disease with reduced perfusion", "Periférne artériové ochorenie so zníženou perfúziou") }
        static var etiologyLineDFU: String       { t("Neuropathy + pressure on background of diabetes", "Neuropatia + tlak na podklade diabetu") }
        static var etiologyLinePressure: String  { t("Pressure/shear over bony prominence", "Tlak/šmyk nad kostným výčnelkom") }
        static var etiologyLineTrauma: String    { t("Traumatic mechanism", "Traumatický mechanizmus") }
        static var etiologyLineSurgical: String  { t("Post-surgical wound", "Pooperačná rana") }
        static var etiologyLineUnclear: String   { t("Unclear etiology", "Nejasná etiológia") }

        // Recommendation sentences (1:1 with Rec cases)
        static var recCleanse: String {
            t("Clean the wound gently with sterile saline.",
              "Jemne vyčistite ranu sterilným fyziologickým roztokom.")
        }
        static var recPeriwound: String {
            t("Protect peri-wound skin with barrier film.",
              "Chráňte okolie rany bariérovým filmom.")
        }
        static var recCompressionFull: String {
            t("Apply therapeutic compression (e.g., 2-layer/short-stretch) if tolerated.",
              "Aplikujte terapeutickú kompresiu (napr. 2-vrstvovú/krátkotažnú), ak je tolerovaná.")
        }
        static var recCompressionAvoidHigh: String {
            t("Avoid high compression; consider light compression pending vascular assessment.",
              "Vyhnite sa silnej kompresii; zvažujte ľahkú kompresiu do cievneho vyšetrenia.")
        }
        static var recCompressionContra: String {
            t("Compression is contraindicated (ABI < 0.5).",
              "Kompresia je kontraindikovaná (ABI < 0,5).")
        }
        static var recDebrideEpibole: String {
            t("Address rolled edges (epibole) with conservative sharp/mechanical debridement.",
              "Riešte zahrnuté okraje (epibole) konzervatívnym ostrým/mechanickým debridementom.")
        }
        static var recPackUndermining: String {
            t("Lightly pack undermining/tunnels as indicated.",
              "Jemne vypĺňajte podmínovanie/tunely podľa potreby.")
        }
        static var recMoistureDryHydrogel: String {
            t("Dry wound: consider hydrogel/occlusive to rehydrate.",
              "Suchá rana: zvažujte hydrogel/okluzívnu terapiu na rehydratáciu.")
        }
        static var recMoistureModerateFoam: String {
            t("Moderate exudate: use foam dressing; change daily–q48h.",
              "Stredný exsudát: použite penový obväz; výmena denne–každých 48 h.")
        }
        static var recMoistureHighAlginate: String {
            t("High exudate: use alginate/absorptive dressing with secondary retention.",
              "Vysoký exsudát: použite alginát/absorpčný obväz so sekundárnou fixáciou.")
        }
        static var recElevationMobility: String {
            t("Elevate limb when resting and encourage calf-pump mobilization.",
              "Pri odpočinku končatinu elevujte a podporujte mobilizáciu lýtkovej pumpy.")
        }
        static var recVenousEducation: String {
            t("Educate on compression adherence and leg elevation.",
              "Poučte o dodržiavaní kompresie a elevácii končatiny.")
        }
        static var recArterialNoDebridementUntilPerfused: String {
            t("Keep dry eschar dry; avoid debridement until perfusion is restored.",
              "Suchú eschar ponechajte suchú; debridement až po obnovení perfúzie.")
        }
        static var recArterialVascularReferral: String {
            t("Urgent vascular referral for revascularization assessment.",
              "Urgentné odoslanie na cievne vyšetrenie a zhodnotenie revaskularizácie.")
        }
        static var recArterialPainSupport: String {
            t("Provide analgesia; keep limb warm; avoid high elevation if it worsens pain.",
              "Zabezpečte analgéziu; udržujte končatinu v teple; vyhnite sa vysokej elevácii pri zhoršení bolesti.")
        }
        static var recDFUOffloading: String {
            t("Enforce off-loading (TCC or removable walker); strict pressure relief.",
              "Zabezpečte off-loading (TCC alebo odnímateľná ortéza); striktne odľahčiť tlak.")
        }
        static var recDFUOsteoWorkup: String {
            t("Probe-to-bone positive: evaluate for osteomyelitis (imaging ± bone culture).",
              "Pozitívna sonda na kosť: vyšetrite osteomyelitídu (zobrazovanie ± kultivácia kosti).")
        }
        static var recAntibioticsIfInfected: String {
            t("Start antibiotics per local guidance; adjust to culture.",
              "Nasadiť antibiotiká podľa lokálnych odporúčaní; upraviť podľa kultivácie.")
        }
        static var recGlycemicControl: String {
            t("Optimize glycemic control; coordinate with diabetic care.",
              "Optimalizujte glykemickú kontrolu; koordinujte s diabetologickou starostlivosťou.")
        }
        static var recFootwearReview: String {
            t("Review footwear and off-loading devices.",
              "Skontrolujte obuv a odľahčovacie pomôcky.")
        }
        static var recFollowUp7d: String {
            t("Reassess in ~7 days; expect measurable improvement within 4 weeks.",
              "Kontrola o ~7 dní; očakávajte merateľné zlepšenie do 4 týždňov.")
        }
        static var recCloseReview48h: String {
            t("Close review in 24–72 h or sooner if deterioration.",
              "Kontrola do 24–72 h, prípadne skôr pri zhoršení.")
        }
        static var recImmunoCloserReview: String {
            t("Immunosuppressed: lower threshold for antibiotics and closer follow-up.",
              "Imunosupresia: nižší prah pre antibiotiká a tesnejšie kontroly.")
        }
        static var recAnticoagBleedingRisk: String {
            t("On anticoagulants: consider bleeding risk during debridement.",
              "Pri antikoagulanciách: zohľadnite riziko krvácania pri debridemente.")
        }
    // Simple label used in PDF metadata
    static var generatedReportDate: String { t("Date", "Dátum") }

        // Helper to map Rec -> string (plug straight into your engine)
        static func recommendationText(_ r: Rec) -> String {
            switch r {
            case .cleanse:                           return recCleanse
            case .protectPeriwound:                  return recPeriwound
            case .compressionFull:                   return recCompressionFull
            case .compressionAvoidHigh:              return recCompressionAvoidHigh
            case .compressionContra:                 return recCompressionContra
            case .debrideEpibole:                    return recDebrideEpibole
            case .packUndermining:                   return recPackUndermining
            case .moistureDryHydrogel:               return recMoistureDryHydrogel
            case .moistureModerateFoam:              return recMoistureModerateFoam
            case .moistureHighAlginate:              return recMoistureHighAlginate
            case .elevationAndMobility:              return recElevationMobility
            case .venousEducation:                   return recVenousEducation
            case .arterialNoDebridementUntilPerfused:return recArterialNoDebridementUntilPerfused
            case .arterialVascularReferral:          return recArterialVascularReferral
            case .arterialPainSupport:               return recArterialPainSupport
            case .dfuOffloading:                     return recDFUOffloading
            case .dfuOsteoWorkup:                    return recDFUOsteoWorkup
            case .antibioticsIfInfected:             return recAntibioticsIfInfected
            case .glycemicControl:                   return recGlycemicControl
            case .footwearReview:                    return recFootwearReview
            case .followUp7d:                        return recFollowUp7d
            case .closeReview48h:                    return recCloseReview48h
            case .immunoCloserReview:                return recImmunoCloserReview
            case .anticoagBleedingRisk:              return recAnticoagBleedingRisk
            }
        }

        // Public helpers for mapping (if you want to avoid inline t(...) in the engine)
        static func mapWoundTypeLabel(for etiologyId: String) -> String {
            switch etiologyId {
            case "venous":       return woundTypeVenous
            case "arterial":     return woundTypeArterial
            case "diabeticFoot": return woundTypeDFU
            case "pressure":     return woundTypePressure
            case "trauma":       return woundTypeTrauma
            case "surgical":     return woundTypeSurgical
            default:             return woundTypeUnspecified
            }
        }
        static func mapHealingStageLabel(for tissueId: String) -> String {
            switch tissueId {
            case "granulation": return healingGranulating
            case "slough":      return healingSloughInflamed
            case "necrosis":    return healingNecroticIschemic
            default:            return healingNotDefined
            }
        }
        static func mapEtiologyLine(for etiologyId: String) -> String {
            switch etiologyId {
            case "venous":       return etiologyLineVenous
            case "arterial":     return etiologyLineArterial
            case "diabeticFoot": return etiologyLineDFU
            case "pressure":     return etiologyLinePressure
            case "trauma":       return etiologyLineTrauma
            case "surgical":     return etiologyLineSurgical
            default:             return etiologyLineUnclear
            }
        }
        static func mapDiagnosisGeneric(for etiologyId: String) -> String {
            switch etiologyId {
            case "venous":       return dxVenousGeneric
            case "arterial":     return dxArterialGeneric
            case "diabeticFoot": return dxDFUGeneric
            case "pressure":     return dxPressureGeneric
            case "trauma":       return dxTraumaGeneric
            case "surgical":     return dxSurgicalGeneric
            default:             return dxUnspecified
            }
        }
    
    
    // MARK: - Foot detail (EN/SK via `t` helper)
    static var footDetailTitle: String  { t("Foot detail", "Podrobnosti chodidla") }
    static var footSectionToes: String  { t("Toes", "Prsty") }
    static var footSectionHeel: String  { t("Heel", "Päta") }
    static var footSectionZones: String { t("Zones", "Zóny") }
    static var actionDone: String       { t("Done", "Hotovo") }

    // Resolves stable codes to localized labels
    static func footLabel(_ code: String) -> String {
        switch code {
        case "toe_1":         return t("Hallux", "Palec (hallux)")
        case "toe_2":         return t("2nd toe", "2. prst")
        case "toe_3":         return t("3rd toe", "3. prst")
        case "toe_4":         return t("4th toe", "4. prst")
        case "toe_5":         return t("5th toe", "5. prst")

        case "heel_central":  return t("Heel (central)", "Päta (stred)")
        case "heel_medial":   return t("Heel (medial)", "Päta (mediálne)")
        case "heel_lateral":  return t("Heel (lateral)", "Päta (laterálne)")

        case "forefoot":      return t("Forefoot", "Predonožie")
        case "midfoot":       return t("Midfoot", "Strednožie")
        case "hindfoot":      return t("Hindfoot", "Zadonožie")
        case "plantar_arch":  return t("Plantar arch", "Plantárna klenba")

        default:              return code
        }
    }
    
    // MARK: - Hand detail
    static var handDetailTitle: String   { t("Hand detail", "Podrobnosti ruky") }
    static var handSectionFingers: String { t("Fingers", "Prsty") }
    static var handSectionAreas: String   { t("Hand areas", "Oblasti ruky") }

    // Map stable codes -> localized labels
    static func handLabel(_ code: String) -> String {
        switch code {
        case "thumb":       return t("Thumb", "Palec")
        case "index":       return t("Index finger", "Ukazovák")
        case "middle":      return t("Middle finger", "Prostredník")
        case "ring":        return t("Ring finger", "Prstenník")
        case "pinky":       return t("Pinky", "Malíček")

        case "palm":        return t("Palm", "Dlaň")
        case "thenar":      return t("Thenar", "Thenar")           // medical term kept
        case "hypothenar":  return t("Hypothenar", "Hypothenar")   // medical term kept
        case "wrist":       return t("Wrist", "Zápästie")
        case "dorsum":      return t("Back of hand", "Chrbát ruky")

        default:            return code
        }
    }
    
    
    // MARK: - Body region labels (Atlas)
    // NOTE: There are keys with a typo "quandrant". We map both to the same label.
    // Consider normalizing the keys later (data migration).

    static func bodyRegionLabel(_ code: String) -> String {
        switch code {

        // FRONT
        case "front_head":                 return t("Head (front)", "Hlava (vpredu)")
        case "front_neck":                 return t("Neck (front)", "Krk (vpredu)")
        case "front_left_shoulder":        return t("Left shoulder (front)", "Ľavé rameno (vpredu)")
        case "front_right_shoulder":       return t("Right shoulder (front)", "Pravé rameno (vpredu)")
        case "front_left_chest":           return t("Left chest", "Ľavý hrudník")
        case "front_right_chest":          return t("Right chest", "Pravý hrudník")
        case "front_left_elbow":           return t("Left elbow (front)", "Ľavý lakeť (vpredu)")
        case "front_right_elbow":          return t("Right elbow (front)", "Pravý lakeť (vpredu)")
        case "front_left_forearm":         return t("Left forearm (front)", "Ľavé predlaktie (vpredu)")
        case "front_right_forearm":        return t("Right forearm (front)", "Pravé predlaktie (vpredu)")

        case "abdomen_left_upper_quadrant",
             "abdomen_left_upper_quandrant":   return t("Abdomen – left upper quadrant", "Brucho – ľavý horný kvadrant")
        case "abdomen_right_upper_quadrant",
             "abdomen_right_upper_quandrant":  return t("Abdomen – right upper quadrant", "Brucho – pravý horný kvadrant")
        case "abdomen_left_lower_quadrant",
             "abdomen_left_lower_quandrant":   return t("Abdomen – left lower quadrant", "Brucho – ľavý dolný kvadrant")
        case "abdomen_right_lower_quadrant",
             "abdomen_right_lower_quandrant":  return t("Abdomen – right lower quadrant", "Brucho – pravý dolný kvadrant")

        case "left_hip":                  return t("Left hip", "Ľavé bedro")
        case "right_hip":                 return t("Right hip", "Pravé bedro")
        case "left_thigh":                return t("Left thigh (front)", "Ľavé stehno (vpredu)")
        case "right_thigh":               return t("Right thigh (front)", "Pravé stehno (vpredu)")
        case "front_left_knee":           return t("Left knee (front)", "Ľavé koleno (vpredu)")
        case "front_right_knee":          return t("Right knee (front)", "Pravé koleno (vpredu)")
        case "left_shin":                 return t("Left shin", "Ľavé predkolenie")
        case "right_shin":                return t("Right shin", "Pravé predkolenie")
        case "front_left_toes":           return t("Left toes (front)", "Ľavé prsty na nohe (vpredu)")
        case "front_right_toes":          return t("Right toes (front)", "Pravé prsty na nohe (vpredu)")
        case "front_left_hand":           return t("Left hand (palm)", "Ľavá ruka (dlaň)")
        case "front_right_hand":          return t("Right hand (palm)", "Pravá ruka (dlaň)")

        // BACK
        case "back_head":                 return t("Head (back)", "Hlava (vzadu)")
        case "back_neck":                 return t("Neck (back)", "Krk (vzadu)")
        case "back_left_shoulder":        return t("Left shoulder (back)", "Ľavé rameno (vzadu)")
        case "back_right_shoulder":       return t("Right shoulder (back)", "Pravé rameno (vzadu)")
        case "left_scapula":              return t("Left scapula", "Ľavá lopatka")
        case "right_scapula":             return t("Right scapula", "Pravá lopatka")
        case "left_lower_back":           return t("Lower back – left", "Dolná časť chrbta – ľavá")
        case "right_lower_back":          return t("Lower back – right", "Dolná časť chrbta – pravá")
        case "left_buttock":              return t("Left buttock", "Ľavá sedacia časť")
        case "right_buttock":             return t("Right buttock", "Pravá sedacia časť")
        case "back_left_hand":            return t("Left hand (dorsum)", "Ľavá ruka (chrbát)")
        case "back_right_hand":           return t("Right hand (dorsum)", "Pravá ruka (chrbát)")
        case "left_triceps":              return t("Left triceps", "Ľavý triceps")
        case "right_triceps":             return t("Right triceps", "Pravý triceps")
        case "back_left_elbow":           return t("Left elbow (back)", "Ľavý lakeť (vzadu)")
        case "back_right_elbow":          return t("Right elbow (back)", "Pravý lakeť (vzadu)")
        case "back_left_forearm":         return t("Left forearm (back)", "Ľavé predlaktie (vzadu)")
        case "back_right_forearm":        return t("Right forearm (back)", "Pravé predlaktie (vzadu)")
        case "left_hamstring":            return t("Left hamstring", "Ľavý hamstring")
        case "right_hamstring":           return t("Right hamstring", "Pravý hamstring")
        case "back_left_knee":            return t("Left knee (back)", "Ľavé koleno (vzadu)")
        case "back_right_knee":           return t("Right knee (back)", "Pravé koleno (vzadu)")
        case "left_calf":                 return t("Left calf", "Ľavé lýtko")
        case "right_calf":                return t("Right calf", "Pravé lýtko")
        case "left_heel":                 return t("Left heel", "Ľavá päta")
        case "right_heel":                return t("Right heel", "Pravá päta")

        // Fallback: humanize the code
        default:
            let human = code.replacingOccurrences(of: "_", with: " ").capitalized
            return t(human, human)
        }
    }
    
    // MARK: - Body localization view strings


    static var subsiteLabel: String { t("Sub-site", "Podlokalita") }
    

    // Subsite names used across body regions
    static func subsiteName(_ code: String) -> String {
        switch code {
        case "plantar":    return t("Plantar", "Plantárna")
        case "dorsal":     return t("Dorsal", "Dorzálna")
        case "anterior":   return t("Anterior", "Predná")
        case "posterior":  return t("Posterior", "Zadná")
        case "lateral":    return t("Lateral", "Laterálna")
        case "medial":     return t("Medial", "Mediálna")
        case "palmar":     return t("Palmar", "Palmárna")
        case "thenar":     return t("Thenar", "Thenar")
        case "hypothenar": return t("Hypothenar", "Hypothenar")
        case "olecranon":  return t("Olecranon", "Olecranon")
        case "acromial":   return t("Acromial", "Akromiálna")
        case "deltoid":    return t("Deltoid", "Deltová")
        case "scapular":   return t("Scapular", "Lopatková")
        case "superior":   return t("Superior", "Horná")
        case "inferior":   return t("Inferior", "Dolná")
        default:
            let human = code.replacingOccurrences(of: "_", with: " ").capitalized
            return t(human, human)
        }
    }

    // Foot detail chips (toes, heel, zones)
    static func footDetailLabel(_ code: String) -> String {
        switch code {
        case "toe_1":        return t("Hallux", "Palec")
        case "toe_2":        return t("2nd toe", "2. prst")
        case "toe_3":        return t("3rd toe", "3. prst")
        case "toe_4":        return t("4th toe", "4. prst")
        case "toe_5":        return t("5th toe", "5. prst")
        case "heel_central": return t("Heel (central)", "Päta (stred)")
        case "heel_medial":  return t("Heel (medial)", "Päta (mediálna)")
        case "heel_lateral": return t("Heel (lateral)", "Päta (laterálna)")
        case "forefoot":     return t("Forefoot", "Predonožie")
        case "midfoot":      return t("Midfoot", "Strednožie")
        case "hindfoot":     return t("Hindfoot", "Zadnožie")
        case "plantar_arch": return t("Plantar arch", "Plantárna klenba")
        default:
            let human = code.replacingOccurrences(of: "_", with: " ").capitalized
            return t(human, human)
        }
    }

    // Hand detail chips (fingers, wrist, dorsum/palm)
    static func handDetailLabel(_ code: String) -> String {
        switch code {
        case "palm":   return t("Palm", "Dlaň")
        case "thumb":  return t("Thumb", "Palec")
        case "index":  return t("Index finger", "Ukazovák")
        case "middle": return t("Middle finger", "Prostredník")
        case "ring":   return t("Ring finger", "Prstenník")
        case "pinky":  return t("Pinky", "Malíček")
        case "wrist":  return t("Wrist", "Zápästie")
        case "dorsum": return t("Back of hand", "Chrbát ruky")
        case "thenar": return t("Thenar", "Thenar")
        case "hypothenar": return t("Hypothenar", "Hypothenar")
        default:
            let human = code.replacingOccurrences(of: "_", with: " ").capitalized
            return t(human, human)
        }
    }
    
    
    // MARK: - Dressing Recommendation (UI)

    static var dressingSelectionTitle: String { t("Dressing Selection", "Výber krytia") }
    static var recommendedSizesLabel: String { t("Recommended Dressing Sizes", "Odporúčané veľkosti krytia") }
    static var woundDimensionsLabel: String { t("Wound dimensions", "Rozmery rany") }
    static var primaryDressingTitle: String { t("Primary Dressing", "Primárne krytie") }
    static var secondaryDressingTitle: String { t("Secondary Dressing", "Sekundárne krytie") }
    static var borderRetentionTitle: String { t("Border/Retention", "Okraj/Upevnenie") }
    static var primaryDressingLabel: String { t("Primary dressing", "Primárne krytie") }
    static var secondaryDressingLabel: String { t("Secondary dressing", "Sekundárne krytie") }
    static var borderIfNeededLabel: String { t("Border (if needed)", "Okraj (ak treba)") }
    static var marginsNote: String { t("Margins include 2–3cm overlap for adhesion and exudate management",
                                       "Veľkosti zahŕňajú presah 2–3 cm pre lepšiu adhéziu a manažment exsudátu") }

    static var applicationNotesTitle: String { t("Application Notes", "Poznámky k aplikácii") }
    static var dressingNoteCleanSaline: String { t("Clean wound bed with normal saline", "Vyčistite lôžko rany fyziologickým roztokom") }
    static var dressingNoteApplyPrimary: String { t("Apply primary dressing directly to wound", "Primárne krytie aplikujte priamo na ranu") }
    static var dressingNoteEnsureMargin: String { t("Ensure 2–3cm margin around wound edges", "Zabezpečte presah 2–3 cm okolo okrajov rany") }
    static var dressingNoteSecure: String { t("Secure with secondary dressing or border", "Zafixujte sekundárnym krytím alebo okrajom") }
    static var dressingNoteChangeFrequency: String { t("Change frequency: per product guidelines or when saturated",
                                                       "Frekvencia výmeny: podľa odporúčaní výrobcu alebo pri presýtení") }

    static var preferredTag: String { t("PREFERRED", "PREFEROVANÉ") }
    static var examplesPrefix: String { t("Examples:", "Príklady:") }
    static var exportCompleteReport: String { t("Export Complete Report", "Exportovať kompletnú správu") }

    // MARK: - PDF labels (reuse in HTML)

    static var completeReportTitle: String { t("Complete Wound Assessment & Dressing Report", "Kompletná správa o rane a krytí") }
    static var woundMeasurementsHeading: String { t("Wound Measurements", "Merania rany") }
    static var woundSizeLabel: String { t("Wound Size", "Veľkosť rany") }
    static var applicationGuidelinesTitle: String { t("Application Guidelines", "Pokyny na aplikáciu") }
    static var reportFooterNotice: String {
        t("This document supports clinical judgment and does not replace professional assessment",
          "Tento dokument podporuje klinické rozhodovanie a nenahrádza odborné vyšetrenie")
    }
    
    // MARK: - LocalizedStrings additions used by this file
    
        
        static var recommendedDressingSizesTitle: String { t("Recommended Dressing Sizes", "Odporúčané veľkosti krytia") }
        
        static var borderDressingTitle: String { t("Border/Retention", "Okrajové/upevnenie") }
       

        // Instruction card
       
        static var appNoteClean: String { t("Clean wound bed with normal saline", "Vyčistite lôžko rany fyziologickým roztokom") }
        static var appNoteApplyPrimary: String { t("Apply primary dressing directly to wound", "Aplikujte primárne krytie priamo na ranu") }
        static var appNoteMargin: String { t("Ensure 2–3 cm margin around wound edges", "Zabezpečte presah 2–3 cm okolo okrajov rany") }
        static var appNoteSecure: String { t("Secure with secondary dressing or border", "Zafixujte sekundárnym alebo okrajovým krytím") }
        static var appNoteChangeFrequency: String { t("Change frequency: per product guidelines or when saturated",
                                                      "Frekvencia výmeny: podľa odporúčaní výrobcu alebo pri presýtení") }

        // Product row
        
        // PDF text
        static var pdfReportTitle: String { t("Complete Wound Assessment & Dressing Report", "Kompletná správa o rane a krytí") }
        static var pdfWoundMeasurements: String { t("Wound Measurements", "Merania rany") }
        static var pdfWoundSize: String { t("Wound Size", "Veľkosť rany") }
        static var pdfPrimary: String { t("Primary Dressing", "Primárne krytie") }
        static var pdfSecondary: String { t("Secondary Dressing", "Sekundárne krytie") }
        static var pdfBorderIfNeeded: String { t("Border (if needed)", "Okrajové krytie (ak treba)") }
        static var pdfApplicationGuidelines: String { t("Application Guidelines", "Pokyny k aplikácii") }
        static var pdfFooterText: String {
            t("WoundPilot Report • This document supports clinical judgment and does not replace professional assessment",
              "WoundPilot • Tento dokument podporuje klinické rozhodovanie a nenahrádza odborné vyšetrenie")
        }

        // Product names & rationales (localized)
        static var dpHydrogelName: String { t("Hydrogel Sheet or Gel", "Hydrogélový kryt alebo gél") }
        static var dpHydrogelRationale: String { t("Promotes autolytic debridement of necrotic tissue",
                                                   "Podporuje autolytické odstraňovanie nekrotického tkaniva") }

        static var dpAlginateName: String { t("Calcium Alginate", "Vápnikový alginát") }
        static var dpAlginateRationale: String { t("High absorbency for sloughy wounds with heavy exudate",
                                                   "Vysoká absorpcia pre povlečené rany s výrazným exsudátom") }

        static var dpHydrocolloidHydrofiberName: String { t("Hydrocolloid or Hydrofiber", "Hydrokoloid alebo hydrofiber") }
        static var dpHydrocolloidHydrofiberRationale: String { t("Supports autolytic debridement while managing moderate exudate",
                                                                 "Podporuje autolýzu a zvláda stredný exsudát") }

        static var dpSilverFoamName: String { t("Silver Foam or Antimicrobial Dressing", "Strieborná pena alebo antimikrobiálne krytie") }
        static var dpSilverFoamRationale: String { t("Manages infection while supporting healing",
                                                     "Rieši infekciu a zároveň podporuje hojenie") }

        static var dpHydrogelSheetName: String { t("Hydrogel Sheet", "Hydrogélový kryt") }
        static var dpHydrogelSheetRationale: String { t("Maintains moist environment for dry granulating wounds",
                                                        "Udržiava vlhké prostredie pri suchých granulujúcich ranách") }

        static var dpThinFoamOrHydrocolloidName: String { t("Thin Foam or Hydrocolloid", "Tenká pena alebo hydrokoloid") }
        static var dpThinFoamOrHydrocolloidRationale: String { t("Low absorbency for minimal exudate",
                                                                 "Nižšia absorpcia pri minimálnom exsudáte") }

        static var dpFoamName: String { t("Foam Dressing", "Pórovité (penové) krytie") }
        static var dpFoamRationale: String { t("Balanced absorbency for moderate exudate",
                                               "Vyvážená absorpcia pri strednom exsudáte") }
        static var dpFoamRationaleGeneric: String { t("Versatile option for granulating wounds",
                                                      "Univerzálna voľba pri granulujúcich ranách") }

        static var dpSuperabsorbentOrAlginateName: String { t("Superabsorbent or Alginate", "Superabsorbent alebo alginát") }
        static var dpSuperabsorbentOrAlginateRationale: String { t("High absorbency for heavily exudating wounds",
                                                                   "Vysoká absorpcia pri výrazne exsudujúcich ranách") }

        static var dpAntimicrobialAltName: String { t("Antimicrobial Dressing (alternative)", "Antimikrobiálne krytie (alternatíva)") }
        static var dpAntimicrobialAltRationale: String { t("Consider if infection persists", "Zvážte pri pretrvávajúcej infekcii") }

        static var dpCompressionSystemName: String { t("Compression Bandage System", "Kompresný obväzový systém") }
        static var dpCompressionSystemRationale: String {
            t("Essential for venous ulcer management (ABI ≥ 0.8)", "Zásadné pri manažmente venóznych vredov (ABI ≥ 0,8)")
        }
        static var dpCompressionExample4Layer: String { t("4-layer bandage", "4-vrstvový obväz") }
        static var dpCompressionExampleShortStretch: String { t("Short-stretch compression", "Krátkotažná kompresia") }

        static var dpAbsorbentPadName: String { t("Absorbent Pad", "Absorpčný vankúšik") }
        static var dpAbsorbentPadRationale: String { t("Additional absorbency for high exudate", "Dodatočná absorpcia pri vysokom exsudáte") }

        static var dpFilmOrSiliconeBorderName: String { t("Film Dressing or Soft Silicone Border", "Fóliové krytie alebo mäkký silikónový okraj") }
        static var dpFilmOrSiliconeBorderRationale: String {
            t("Secures primary dressing while allowing visual inspection",
              "Fixuje primárne krytie a umožňuje vizuálnu kontrolu")
        }

        static var dpOffloadingDeviceName: String { t("Offloading Device", "Odľahčovacie zariadenie") }
        static var dpOffloadingDeviceRationale: String {
            t("Critical for diabetic foot ulcers – reduces pressure", "Kľúčové pri DFU – znižuje tlak")
        }
    
        static let ageShort = t("yrs", "r.")
        static let abbrevDM = "DM"               // diabetes badge
        static let abbrevPAD = "PAD"
    
    
    // Loading / empty
    static var loadingPatientsSubtitle: String { t("Fetching your patients…", "Načítavam zoznam pacientov…") }
    static var noSearchResults: String { t("No results match your search.", "Žiadne výsledky nezodpovedajú vyhľadávaniu.") }

    // Search scopes/tags
    static var scopeAll: String { t("All", "Všetko") }
    static var scopeDM: String { t("DM", "DM") }
    static var scopeSmoker: String { t("Smoker", "Fajčiar") }
    static var scopePAD: String { t("PAD", "PAD") }

    static var tagDM: String { t("DM", "DM") }
    static var tagSmoker: String { t("Smoker", "Fajčiar") }
    static var tagPAD: String { t("PAD", "PAD") }

    // Badges (short labels)
    static var badgeDM: String { t("DM", "DM") }
    static var badgeSmoker: String { t("Smoker", "Fajčiar") }
    static var badgePAD: String { t("PAD", "PAD") }
    static var secBoneDepth: String {
        t("Bone involvement", "Postihnutie kosti")
    }
        static var woundLabel: String { NSLocalizedString("wound_label", comment: "") }
       
        static var qHowLongPresent: String { NSLocalizedString("q_how_long_present", comment: "") }
        static var qPredominantTissue: String { NSLocalizedString("q_predominant_tissue", comment: "") }
        static var infectionClinicalSignsLabel: String { NSLocalizedString("infection_clinical_signs_label", comment: "") }
        static var signPurulentDischarge: String { NSLocalizedString("sign_purulent_discharge", comment: "") }
        static var signErythema2cm: String { NSLocalizedString("sign_erythema_2cm", comment: "") }
        static var signFeverSystemic: String { NSLocalizedString("sign_fever_systemic", comment: "") }
        static var infectionSelectOneHint: String { NSLocalizedString("infection_select_one_hint", comment: "") }
        
        static var exudateHighHint: String { NSLocalizedString("exudate_high_hint", comment: "") }
        static var woundEdgeAppearance: String { NSLocalizedString("wound_edge_appearance", comment: "") }
        static var perfusionAssessmentTitle: String { NSLocalizedString("perfusion_assessment_title", comment: "") }
        static var abiLabel: String { NSLocalizedString("abi_label", comment: "") }
        static var palpablePedalPulses: String { NSLocalizedString("palpable_pedal_pulses", comment: "") }
        static var boneDeepStructuresTitle: String { NSLocalizedString("bone_deep_structures_title", comment: "") }
    static var boneVisibleToggle: String {
        t("Bone visible", "Viditeľná kosť")
    }

    static var probeToBonePositiveToggle: String {
        t("Probe to bone positive", "Sonda dosiahne kosť (pozitívne)")
    }
    static var selectAllThatApplyOptional: String {
           t("Select all (optional)", "Vyberte všetko (voliteľné)")
       }
    static var anyConcerningSignsOptional: String {
            t("Any concerning signs (optional)", "Akékoľvek znepokojujúce príznaky (voliteľné)")
        }

        // Guardrails / banners
        static var guardrailUrgentAntibiotics: String { NSLocalizedString("guardrail_urgent_antibiotics", comment: "") }
        static var guardrailSevereIschemia: String { NSLocalizedString("guardrail_severe_ischemia", comment: "") }
        static var guardrailPossibleOsteo: String { NSLocalizedString("guardrail_possible_osteo", comment: "") }
        static var guardrailRedFlagsEscalate: String { NSLocalizedString("guardrail_redflags_escalate", comment: "") }
        static var urgentSystemicBanner: String { NSLocalizedString("urgent_systemic_banner", comment: "") }
        static var urgentSevereIschemiaBanner: String { NSLocalizedString("urgent_severe_ischemia_banner", comment: "") }

        // Footer controls
       
        static var next: String { NSLocalizedString("next", comment: "") }
    static var saveAndAnalyze: String {
            t("Save & Analyze", "Uložiť a analyzovať")
        }

        // Step indicator
        static func stepProgress(_ current: Int, _ total: Int, _ title: String) -> String {
            let fmt = NSLocalizedString("step_progress_format", comment: "")
            return String(format: fmt, current, total, title)
        }
    
    
    // Questionnaire – general / headers
    static var stepWord: String              { t("Step", "Krok") }
    static var ofWord: String                { t("of", "z") }

    // Duration / Tissue prompts
    static var qDurationPrompt: String       { t("How long has this wound been present?",
                                                 "Ako dlho je rana prítomná?") }
    static var qTissuePrompt: String         { t("Predominant tissue type in wound bed",
                                                 "Prevládajúci typ tkaniva v lôžku rany") }

    // Infection detail
    static var clinicalSignsPresent: String  { t("Clinical signs present:",
                                                 "Prítomné klinické príznaky:") }
    static var infSignPurulence: String      { t("Purulent discharge",
                                                 "Hnisavý sekrét") }
    static var infSignErythema: String       { t("Erythema >2 cm",
                                                 "Erytém >2 cm") }
    static var infSignSystemic: String       { t("Fever/systemic illness",
                                                 "Horúčka/systémové príznaky") }
    static var infSelectOneOrNone: String    { t("Please select at least one clinical sign or change to “None”.",
                                                 "Vyberte aspoň jeden klinický príznak alebo zmeňte na „Žiadne“.") }
    static var infUrgentAbxReferral: String  { t("Urgent: consider systemic antibiotics and specialist referral.",
                                                 "Urgentné: zvážte systémové antibiotiká a odoslanie k špecialistovi.") }

    // Moisture / Edge
    
    static var highExudateTip: String        { t("High exudate → superabsorbent dressing recommended",
                                                 "Vysoký exsudát → odporúčané superabsorpčné krytie") }
    static var edgeAppearance: String        { t("Wound edge appearance",
                                                 "Vzhľad okrajov rany") }

    // Perfusion
    static var abiTitle: String              { t("Ankle-Brachial Index (ABI)",
                                                 "Index členok–paža (ABI)") }
    static var palpablePulses: String        { t("Palpable pedal pulses",
                                                 "Hmatné periférne pulzy") }
    static var abiSevereIschemiaWarn: String { t("Severe ischemia – compression contraindicated; urgent vascular referral.",
                                                 "Závažná ischémia – kompresia je kontraindikovaná; urgentné odoslanie na cievnu chirurgiu.") }

    // Bone / depth
    static var boneVisible: String           { t("Bone visible in wound bed",
                                                 "Kosť viditeľná v lôžku rany") }
    static var probeToBonePositive: String   { t("Probe-to-bone positive",
                                                 "Pozitívny test „probe-to-bone“") }
    static var possibleOsteoWorkup: String   { t("Possible osteomyelitis – consider X-ray, MRI, or bone biopsy.",
                                                 "Možná osteomyelitída – zvážte RTG, MRI alebo biopsiu kosti.") }

    // Sections helper copy
    static var selectAllOptional: String     { t("Select all that apply (optional)",
                                                 "Vyberte všetko, čo platí (voliteľné)") }
    static var anyConcerningOptional: String { t("Any concerning signs? (optional)",
                                                 "Sú prítomné znepokojujúce príznaky? (voliteľné)") }
    static var redFlagsEscalateNow: String   { t("Red flags present – escalate to specialist immediately.",
                                                 "Prítomné varovné príznaky – okamžite eskalujte k špecialistovi.") }

    // Urgent banners
    static var urgentSystemicSigns: String   { t("⚠️ URGENT: Systemic signs – immediate medical attention required.",
                                                 "⚠️ URGENTNÉ: Systémové príznaky – potrebné okamžité lekárske vyšetrenie.") }
    static var severeIschemiaBanner: String  { t("⚠️ Severe ischemia detected – urgent vascular surgery referral.",
                                                 "⚠️ Zistená závažná ischémia – urgentné odoslanie na cievnu chirurgiu.") }
    static var infectionSignsHeader: String {
        t("Clinical signs present:", "Prítomné klinické príznaky:")
    }
    static var infectionSignPurulence: String {
        t("Purulent discharge", "Hnisavý výtok")
    }
    static var infectionSignErythema2cm: String {
        t("Erythema >2cm", "Erytém >2 cm")
    }
    static var infectionSignSystemicFever: String {
        t("Fever/systemic illness", "Horúčka / systémové príznaky")
    }
    static var infectionSelectAtLeastOne: String {
        t("Please select at least one clinical sign or change to 'None'",
          "Vyberte aspoň jeden klinický príznak alebo zmeňte na „Žiadne“")
    }
    static var infectionSystemicUrgentAdvice: String {
        t("⚠️ Urgent: Consider systemic antibiotics & specialist referral",
          "⚠️ Urgentné: Zvážte systémové antibiotiká a odporúčanie špecialistovi")
    }
    
    static var exudateLevelLabel: String {
        t("Exudate level", "Úroveň exsudátu")
    }
    static var highExudateHint: String {
        t("High exudate → superabsorbent dressing recommended",
          "Vysoký exsudát → odporúča sa superabsorpčné krytie")
    }
    static var woundEdgeAppearanceLabel: String {
        t("Wound edge appearance", "Vzhľad okrajov rany")
    }
    static var perfusionABIHeading: String {
        t("Ankle-Brachial Index (ABI)", "Členkovo-ramenný index (ABI)")
    }

    static var perfusionPulsesLabel: String {
        t("Palpable pedal pulses", "Hmatné periférne pulzy na nohe")
    }

    static var perfusionSevereIschemiaGuardrail: String {
        t("Severe ischemia - compression contraindicated, urgent vascular referral",
          "Ťažká ischémia - kompresia je kontraindikovaná, urgentná cievna konzultácia")
    }

    static var probeToBoneToggle: String {
        t("Probe to bone positive", "Sonda na kosť pozitívna")
    }

    static var boneOsteoGuardrail: String {
        t("Possible osteomyelitis – consider X-ray, MRI, or bone biopsy",
          "Možná osteomyelitída – zvážte RTG, MRI alebo biopsiu kosti")
    }
    
    static var redFlagsEscalateGuardrail: String {
        t("Red flags present – escalate to specialist immediately",
          "Prítomné varovné príznaky – okamžite eskalovať špecialistovi")
    }
    static var backAction: String {
        t("Back", "Späť")
    }
    static var nextAction: String {
        t("Next", "Ďalej")
    }
    static var urgentBannerSystemic: String {
        t("⚠️ URGENT: Systemic signs - immediate medical attention required",
          "⚠️ URGENTNÉ: Systémové príznaky – nutné okamžité lekárske vyšetrenie")
    }

    static var urgentBannerSevereIschemia: String {
        t("⚠️ Severe ischemia detected - urgent vascular surgery referral",
          "⚠️ Zistená ťažká ischémia – urgentné odoslanie na cievnu chirurgiu")
    }
    static func stepProgress(current: Int, total: Int, title: String) -> String {
            let pattern = t("Step %d of %d  •  %@", "Krok %d z %d  •  %@")
            return String(format: pattern, current, total, title)
        }
    
    static var arNotSupportedTitle: String {
            t("AR not supported on this device", "AR nie je podporované na tomto zariadení")
        }
        static var arNotSupportedMessage: String {
            t("This iPhone/iPad does not support AR world tracking.", "Tento iPhone/iPad nepodporuje AR sledovanie priestoru.")
        }
        

        // Measurement section
        static var latestMeasurementTitle: String {
            t("Latest Measurement", "Posledné meranie")
        }
        static var noMeasurementsYetHint: String {
            t("No measurements yet — tap Measure to start", "Zatiaľ žiadne meranie — klepnite na Meranie a začnite")
        }

        // Buttons
        static var measureButton: String {
            t("Measure", "Meranie")
        }
        static var remeasureButton: String {
            t("Remeasure", "Znova zmerať")
        }

        // Short labels (chips)
        static var lengthShort: String {
            t("L", "D") // Length / Dĺžka
        }
        static var widthShort: String {
            t("W", "Š") // Width / Šírka
        }
        static var areaShort: String {
            t("A", "P") // Area / Plocha
        }
    
        static var measureAbbrL: String { t("L", "L") }   // Length abbreviation
        static var measureAbbrW: String { t("W", "Š") }   // Width abbreviation (kept single-letter; use "Š" if you prefer Slovak)
        static var measureLabelArea: String { t("Area", "Plocha") }
        static var qualityLabel: String { t("Quality:", "Kvalita:") }

        // Buttons
        static var manualActionTitle: String { t("Manual", "Manuálne") }
        static var saveAction: String { t("Save", "Uložiť") }

        // Distance guidance
        static var distanceSuffixMoveBack: String { t("(move back)", "(odstúpte)") }
        static var distanceSuffixMoveCloser: String { t("(move closer)", "(priblížte sa)") }
        static var distanceSuffixOK: String { t("✓", "✓") }

        // AR tracking states
        static var arInitializing: String { t("AR: Initializing...", "AR: Inicializujem…") }
        static var arTrackingGood: String { t("AR: Good", "AR: Dobré") }
        static var arTrackingNotAvailable: String { t("AR: Not Available", "AR: Nedostupné") }
        static var arTrackingSlowDown: String { t("AR: Slow Down", "AR: Spomaľte") }
        static var arTrackingLowFeatures: String { t("AR: Low Features", "AR: Málo prvkov v scéne") }
        static var arTrackingRelocalizing: String { t("AR: Relocalizing", "AR: Relokalizujem") }
        static var arTrackingLimited: String { t("AR: Limited", "AR: Obmedzené") }
    
    

        // Screen / sections
        static var manualEntryTitle: String { t("Manual Entry", "Manuálny záznam") }
        static var manualMeasurementHeaderTitle: String { t("Manual Measurement", "Manuálne meranie") }
        static var manualPhotoSectionTitle: String { t("Photo", "Fotografia") }
        static var manualMeasurementsSectionTitle: String { t("Measurements", "Merania") }

        // Photo area
        static var manualPhotoAddOptional: String { t("Add Photo (Optional)", "Pridať fotografiu (voliteľné)") }
        static var manualPhotoHint: String {
            t("For best results, include a ruler or coin in the photo for reference",
              "Pre najlepšie výsledky priložte na fotografiu pravítko alebo mincu ako referenciu.")
        }

        // Fields / labels
        static var manualLengthLabel: String { t("Length", "Dĺžka") }
        static var manualWidthLabel: String { t("Width", "Šírka") }
        
        static var numericPlaceholderZero: String { t("0.0", "0,0") }

        // Info box
        static var manualArUnavailable: String { t("AR measurement unavailable", "Meranie AR nie je k dispozícii") }
        static var manualInfoText: String {
            t("Use a ruler to measure the wound's length (longest dimension) and width (widest perpendicular point). Optionally add a photo with a reference object visible.",
              "Na zmeranie dĺžky rany (najdlhší rozmer) a šírky (najširší kolmo vedený bod) použite pravítko. Voliteľne pridajte fotografiu s viditeľným referenčným predmetom.")
        }

        // Footer under measurements
        static var manualMeasurementsHint: String {
            t("Measure the longest axis for length and the widest perpendicular point for width",
              "Zmerajte najdlhší rozmer (dĺžku) a najširší kolmo vedený bod (šírku).")
        }


        // Alerts
        static var manualInvalidMeasurementsTitle: String { t("Invalid Measurements", "Neplatné merania") }
        static var manualInvalidMeasurementsMessage: String {
            t("Please enter valid measurements between 0.1 and 100 cm",
              "Zadajte platné hodnoty v rozsahu 0,1 až 100 cm")
        }
    static var savingWoundSpinner: String { t("Saving wound...", "Ukladám ranu...") }
    static var groupWoundImagesTitleBetter: String {
        t("Group wound images", "Zoskupte fotografie rany")
    }
    static var groupWoundImagesSubtitleBetter: String {
        t("Keep all photos of the same wound together so healing is clear and comparable.",
          "Majte všetky fotografie tej istej rany pokope, aby bol priebeh hojenia jasný a porovnateľný.")
    }
    static var groupWhyTrend: String {
        t("See the healing trend and area change over time.", "Sledujte trend hojenia a zmenu plochy v čase.")
    }
    static var groupWhyCompare: String {
        t("Compare measurements consistently between visits.", "Porovnávajte merania konzistentne medzi kontrolami.")
    }
    static var groupWhyFindFast: String {
        t("Find related photos quickly during follow-ups.", "Rýchlo nájdite súvisiace fotografie pri kontrolách.")
    }
    static var groupExamplesTitle: String {
        t("Examples", "Príklady")
    }
    static var groupNamePlaceholder: String {
        t("Name this wound group (e.g., Left Heel Ulcer)", "Pomenujte skupinu rán (napr. Ľavá päta – vred)")
    }
    static var groupNameHint: String {
        t("Tip: use Side + Location (e.g., “Left Heel”).", "Tip: použite Strana + Lokalita (napr. „Ľavá päta“).")
    }
  
    }


    

