# 📘 WoundPilot Devlog

## June 10, 2025
- Firebase project created, including Authentication, Firestore, and Storage
- SwiftUI app initialized with Firebase Core integration
- Implemented registration, login, and logout using FirebaseAuth
- Navigation switches between login and home views based on auth state
- Built core views: ContentView, HomeView, RegisterView, LoginView
- Added CaptureWoundView to take photos and upload them
- Implemented ImagePicker with UIKit integration
- Wound images stored in Firebase Storage
- Wound metadata saved to Firestore with timestamp and user ID
- GitHub repository initialized
- Added Wound History View Integration
- Modified: `HomeView.swift`  
  - Added a new `NavigationLink` button: **"🧾 View My Wounds"**
  - This button routes the user to the upcoming `WoundListView`, which will display all previously uploaded wound photos.
- Purpose:  
  - Allow the doctor to view a list of their uploaded wounds for tracking and review.
  - First step toward building a full patient wound history system.

---


