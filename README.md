<div align="center">

# 🚛 Nirmal — Digital Safai Mitra

**A cross-platform waste management ecosystem replacing manual municipal tracking with a real-time, closed-loop platform.**

[![Download APK](https://img.shields.io/badge/📱_Download-Android_APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/sonubiswal/nirmal-digital-safai-mitra/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)

</div>

---

## 📌 The Problem
Municipal waste tracking is often manual, leading to missed pickups, delayed complaint resolution, and inefficient routing. Citizens lack visibility, and administrators lack data.

## 💡 The Solution
**Nirmal** bridges the citizen-municipality gap by providing a dual-interface platform:
- **Resident App:** Live GPS tracking of the waste truck, geofenced proximity alerts, and one-tap complaint logging.
- **Admin App:** Real-time fleet tracking, automated complaint redressal, and data-driven operational intelligence for sanitation planning.

## ✨ Key Features
- **Real-time Sync:** Built with Firebase Realtime Database (RTDB) and FCM for low-latency updates and push notifications.
- **Live GPS Tracking:** Tracks the collection vehicle and notifies residents when the truck is nearby.
- **Dual Interface:** Secure role-based access for both citizens and municipal admins.
- **Automated Workflows:** Complaint logging that automatically routes to the nearest admin and tracks resolution time.

## 📱 Try the App
You can download the latest Android APK directly from the **Releases** section to test the app on your phone.

👉 **[Download the APK here](https://github.com/sonubiswal/nirmal-digital-safai-mitra/releases/latest)**

## 🛠 Tech Stack
- **Frontend:** Flutter, Dart
- **Backend / Cloud:** Firebase Auth, Firebase RTDB, Firebase Cloud Messaging (FCM)
- **Maps & Location:** Google Maps API, Geolocator

## 🚀 Setup & Run (Local Development)

> ⚠️ **Security Note:** This repository does not include `google-services.json` or `GoogleService-Info.plist` for security reasons. To run the app locally, you must connect it to your own Firebase project.

```bash
# 1. Clone the repo
git clone https://github.com/sonubiswal/nirmal-digital-safai-mitra.git
cd nirmal-digital-safai-mitra

# 2. Get packages
flutter pub get

# 3. Add Firebase config
# Create a Firebase project and download your own configuration files:
# - Place google-services.json in android/app/
# - Place GoogleService-Info.plist in ios/Runner/

# 4. Run the app
flutter run