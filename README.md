#  Chat Connect - Real-Time Flutter Messaging App

Chat Connect is a robust, cross platform messaging application built with **Flutter** and **Firebase**. This guide provides a comprehensive setup and installation walkthrough to get the project running on your local machine.

---


##  Project Overview
This application serves as a real time communication tool, featuring instant message delivery, user authentication, and a modern UI. It follows best practices in state management and cloud integration.

### Core Features:
* **Real-Time Sync:** Powered by Firebase Firestore Streams.
* **Authentication:** Secure Signup/Login via Firebase Auth.
* **Modern UI:** Responsive design for Android, iOS, and Web.
* **Profile Management:** Personalized user settings and data storage.

---

##  Prerequisites
Before proceeding, ensure you have the following installed:
* **Flutter SDK:** [Download Flutter](https://docs.flutter.dev/get-started/install)
* **Dart SDK:** Included with Flutter.
* **Firebase Account:** To set up the backend database.
* **IDE:** Android Studio or VS Code with Flutter/Dart plugins.

---

##  Installation Guide

### 1. Clone the Repository
Open your terminal and run:
`git clone https://github.com/aleenamushtaq/chat-connect.git`
`cd chat-connect`

### 2. Install Dependencies
`flutter pub get`

### 3. Firebase Configuration
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new project and add Android/iOS apps.
3. Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place them in their respective directories.
4. Update `lib/firebase_options.dart` with your actual project credentials.

---
##  Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Firebase has not been initialized** | Ensure you have called `Firebase.initializeApp()` in `main.dart` and your `firebase_options.dart` is correctly configured. |
| **Target of URI doesn't exist** | Run `flutter pub get` again to ensure all packages are downloaded. |
| **Execution failed for task ':app:processDebugResources'** | Run `flutter clean` and then try building the app again. |

##  Developer
**Aleena Mushtaq** 
*Flutter Developer*
