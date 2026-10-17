![Nirmal, Digital Safai Mitra](https://raw.githubusercontent.com/sonubiswal/nirmal-digital-safai-mitra/main/assets/banner.svg)

[![Download APK](https://img.shields.io/badge/Download-Android_APK-3DDC84?style=flat-square&logo=android&logoColor=white)](https://github.com/sonubiswal/nirmal-digital-safai-mitra/releases/latest) [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev) [![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev) [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com) [![Google Maps](https://img.shields.io/badge/Google_Maps-4285F4?style=flat-square&logo=googlemaps&logoColor=white)](https://developers.google.com/maps) [![License: MIT](https://img.shields.io/badge/License-MIT-12a56b?style=flat-square)](https://opensource.org/licenses/MIT)

**[Problem](#the-problem-and-solution)** | **[How it works](#how-it-works)** | **[Screenshots](#app-screenshots)** | **[Features](#key-features)** | **[Tech stack](#tech-stack)** | **[Setup](#local-setup)**

> **Nirmal** (*Digital Safai Mitra*) is a cross-platform waste management ecosystem that replaces manual municipal tracking with a real-time, closed-loop platform for citizens and administrators.

---

## The problem and solution

| The problem | The solution |
|:--|:--|
| Municipal waste tracking is largely manual, which leads to **missed pickups**, **slow complaint resolution** and **inefficient routing**. | Nirmal gives residents and administrators one shared, real-time platform. |
| Citizens have no visibility into where the truck is. | Residents **track the truck live** and see their walking distance and ETA. |
| Citizens don't know where the nearest public dustbin is, which leads to littering and illegal dumping. | Users can **find nearby bins** on the map, see the walking distance and ETA, and get **walking directions** to the nearest one. |
| Administrators lack the data to manage fleets and issues. | Admins get a **live dashboard** to manage fleets and resolve complaints instantly. |

### The project in 30 seconds

> Nirmal solves the inefficiency of manual waste management. Citizens miss the garbage truck, don't know where the nearest public bin is, and have no easy way to report overflowing trash. It is a dual-sided Flutter app: citizens get live GPS tracking of the truck, push notifications when it is nearby, and a locator that finds the closest dustbin with walking directions. Admins get a real-time dashboard to track routes and resolve photo-based complaints instantly. It is built with Firebase for real-time sync and FCM for background alerts.

---

## How it works

![The closed loop: citizen, Firestore, admin, resolution, push notification](https://raw.githubusercontent.com/sonubiswal/nirmal-digital-safai-mitra/main/assets/workflow.svg)

| Role | What they can do |
|:--|:--|
| **Citizen** | Track the collection vehicle live, get alerted when it is close, find the nearest dustbin with walking directions, and file complaints in one tap. |
| **Municipal admin** | Monitor active routes and trucks, review incoming complaints, and mark them resolved. |

---

## App screenshots

| Live dashboard | Walking directions | Submit complaint | Push notification |
|:--:|:--:|:--:|:--:|
| ![Live Dashboard](https://raw.githubusercontent.com/sonubiswal/nirmal-digital-safai-mitra/main/assets/screenshots/dashboard.jpeg) | ![Walking Directions](https://raw.githubusercontent.com/sonubiswal/nirmal-digital-safai-mitra/main/assets/screenshots/directions.jpeg) | ![Submit Complaint](https://raw.githubusercontent.com/sonubiswal/nirmal-digital-safai-mitra/main/assets/screenshots/complaint.jpeg) | ![Push Notifications](https://raw.githubusercontent.com/sonubiswal/nirmal-digital-safai-mitra/main/assets/screenshots/notification.jpeg) |

> [!TIP]
> **Want to try it first?** [**⬇️ Download the latest Android APK**](https://github.com/sonubiswal/nirmal-digital-safai-mitra/releases/latest)

---

## Key features

### 📱 For Citizens

| Feature | Description |
|:--|:--|
| **Live Truck Tracking** | Watch the garbage truck move on a real-time map. See exactly where it is and get an accurate walking distance and ETA. |
| **Proximity Alerts** | Never miss a pickup again. Firebase Cloud Messaging (FCM) sends a push notification to your phone when the truck is within a 2-minute radius. |
| **Smart Bin Locator** | Need to throw something away right now? Find the nearest public dustbin on the map and get instant walking directions to it. |
| **One-Tap Complaints** | Report overflowing bins or missed pickups instantly. Attach photos, tag the exact GPS location, and set the priority level (Low, Medium, High). |
| **Dual-Language Support** | Access the app in multiple local languages for better accessibility. |

### 🖥️ For Municipal Admins

| Feature | Description |
|:--|:--|
| **Live Operations Dashboard** | A centralized command center showing real-time fleet stats: total trucks, active routes, and completed deliveries. |
| **Complaint Management** | View incoming photo-based complaints, track their status, and mark them as resolved with a single tap. |
| **Role-Based Access** | Secure, Firebase-authenticated admin panel to ensure only authorized municipal staff can manage fleet operations. |

### ⚙️ Under the Hood

| Feature | Description |
|:--|:--|
| **Real-Time Database Sync** | Powered by Cloud Firestore and Firebase Realtime Database for zero-latency updates between the citizen app and admin dashboard. |
| **Robust Routing** | Integrated with Google Maps API and OSRM to calculate actual road-network walking paths, not just straight lines. |
| **Secure Architecture** | API keys and sensitive configurations are completely stripped from the public repository. |

---

## Tech stack

| Layer | Technology |
|:--|:--|
| **Frontend** | Flutter, Dart, Material Design 3 |
| **Backend and auth** | Firebase Authentication, Cloud Firestore, Firebase Realtime Database |
| **Notifications** | Firebase Cloud Messaging (FCM) |
| **Maps and routing** | Google Maps API, Geolocator, OSRM (walking routes) |
| **State management** | Provider / GetX |

---

## Local setup

> 🔒 **Security note:** this repository does not include `google-services.json` or `GoogleService-Info.plist`, which keeps API keys from leaking. To run the app locally, connect it to **your own Firebase project**.

**Prerequisites**

- [Flutter SDK](https://docs.flutter.dev/get-started/install) and an Android or iOS device or emulator
- A Firebase project with Authentication, Cloud Firestore, Realtime Database and Cloud Messaging enabled
- A Google Maps API key

```bash
# 1. Clone the repository
git clone https://github.com/sonubiswal/nirmal-digital-safai-mitra.git
cd nirmal-digital-safai-mitra

# 2. Get Flutter packages
flutter pub get

# 3. Add your Firebase configuration
#    Create a project in the Firebase Console, then download your own files:
#    - place google-services.json in android/app/
#    - place GoogleService-Info.plist in ios/Runner/

# 4. Run the app
flutter run
```

---

<div align="center">

## Sumit Kumar Biswal

<a href="https://github.com/sonubiswal">
  <img src="https://img.shields.io/badge/GitHub-@sonubiswal-181717?style=for-the-badge&logo=github&logoColor=white" alt="sonubiswal on GitHub">
</a>

</div>
