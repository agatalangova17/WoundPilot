# WoundPilot – Smart Wound Analysis for Clinicians  
*A mobile wound assessment and management application for healthcare professionals, built with Swift and Firebase.*

---

## Overview

WoundPilot is an iOS application that uses AR/LiDAR technology to measure chronic wounds and provides evidence-based treatment recommendations using the TIME framework. The app supports both individual patient tracking and quick assessment modes.

> ⚠️ Currently under active development

---

## Key Features

**Core Functionality**

- AR Wound Measurement: Uses iPhone LiDAR to measure wound dimensions (length, width, area)
- Clinical Assessment: TIME framework-based questionnaire (Tissue, Infection, Moisture, Edge)
- Treatment Recommendations: Algorithm-driven suggestions for dressing selection and wound management
- Patient Management: Track multiple patients and wound groups over time
- Healing Analytics: Visual charts showing wound progression
- Bilingual Support: English and Slovak localization

**Key Workflows**

- **Patient Flow:** Patient → Wound → AR Measurement → Assessment → Report → Dressing Recommendations
- **Quick Scan:** Anonymous assessment without patient records (for teaching/consultation)

---

## Tech Stack

- **Language:** Swift 5.9
- **Framework:** SwiftUI
- **Backend:** Firebase (Firestore, Storage, Auth)
- **AR:** ARKit, RealityKit
- **Minimum iOS:** 17.0
- **Device Requirements:** iPhone with LiDAR (iPhone 12 Pro and newer)

---

## Current Architecture (simplified)

```
WoundPilot/
├── Models/
│   ├── Patient.swift
│   ├── Wound.swift
│   └── WoundMeasurementResult.swift
├── Features/
│   ├── Patients/
│   ├── Wounds/
│   ├── Measurement/
│   │   └── ARMeasureView.swift
│   ├── Questionnaire/
│   │   └── QuestionnaireView.swift
│   └── Dressing/
│       └── DressingRecommendationView.swift
├── Language/
│   └── LocalizationManager.swift
└── Services/
    └── WoundService.swift
```

---
## Clinical Decision Support

The app implements evidence-based algorithms for:

- **Venous Ulcers:** Compression therapy recommendations based on ABI
- **Arterial Ulcers:** Vascular referral triggers, debridement contraindications
- **Diabetic Foot Ulcers:** Offloading, infection management, osteomyelitis screening
- **Pressure Ulcers:** Pressure redistribution guidance
- **Dressing Selection:** Moisture management, antimicrobial dressings, sizing calculations

## Privacy & Security

WoundPilot stores all sensitive data using Firebase with the following practices:

- **Authentication** via secure Firebase Auth  
- **No local storage of medical images** (stored only in Firebase Storage)  
- **Realtime Firestore database rules** restrict access to user-owned data  
- **No 3rd-party analytics or tracking** included  
- **HIPAA compliance goals** in progress 

---

## Known Issues

- PDF export generates file but renders blank (HTML/CSS parsing issue)
- AR measurements are currently not very accurate


---

## Author
**[@agatalangova17](https://github.com/agatalangova17)**  
Aspiring mobile developer, passionate about clinical technology, privacy, and design.

---

## Contact

Feel free to reach out if you're interested in collaboration, internships, or feedback!

Email: agata.langova17@gmail.com
GitHub: [github.com/agatalangova17](https://github.com/agatalangova17)

---

## Contributing

This is an academic project. For questions or suggestions, contact agata.langova17@gmail.com.

---

## License

© 2025 WoundPilot. All rights reserved.

Note: This application is intended for educational and clinical decision support purposes. It does not replace professional medical judgment. All treatment decisions should be made by qualified healthcare professionals. Do not reproduce, redistribute, or deploy without permission.
