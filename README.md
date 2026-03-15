# 🔴 DROP - Your Smart Savings Companion in Jordan

**Drop** is a cutting-edge Flutter application designed to bridge the gap between savvy shoppers and local merchants in Jordan. It leverages Artificial Intelligence and Location-Based Services to ensure users never miss a deal that fits their budget and proximity.

---

## 🚀 Key Features

### 👤 For Savers (Users)
- **Real-time Follower Alerts:** Get instant notifications the second a store you follow publishes a new deal. 🔥
- **Auto-Clean Feed:** The home screen and map automatically hide expired deals, keeping your experience fresh and relevant.
- **Drop AI Assistant:** A smart, friendly AI guide (powered by Gemini 1.5 Flash) that helps you find the best deals using natural Jordanian dialect.
- **Proximity-Based Discovery:** Explore deals on an interactive map or filter them by distance (from 0 to 20km).
- **Smart Notifications:** Customize alerts based on your interests (Food, Fashion, Cafes, etc.) and your current location.

### 🏪 For Merchants (Store Owners)
- **Instant Reach:** Every deal you publish or update instantly triggers notifications to all your followers.
- **Deal Lifecycle Management:** Publish deals with custom expiry times. Expired deals are hidden from users but kept in your dashboard for easy re-activation.
- **Merchant Dashboard:** A professional suite to publish, edit, and track active discounts.
- **Subscription Management:** Built-in system to track and renew store membership status with localized payment support.

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Multi-platform UI)
- **Backend:** [Firebase](https://firebase.google.com/)
    - **Firestore:** Real-time NoSQL database for deals, users, and chats.
    - **Authentication:** Secure Email/Password login.
    - **Cloud Messaging (FCM):** For push notifications.
- **Artificial Intelligence:** [Google Generative AI](https://ai.google.dev/) (Gemini 1.5 Flash Model).
- **Maps:** [Flutter Map](https://pub.dev/packages/flutter_map) (OpenStreetMap based).
- **Localization:** [Easy Localization](https://pub.dev/packages/easy_localization) (Full AR/EN support).

---

## 🏗 Project Structure

```text
lib/
├── main.dart               # App entry, Firebase init & Global Notification Listener
├── home.dart               # Smart search & deals feed (with Auto-Expiry filter)
├── map.dart                # Interactive location discovery & Store Markers
├── store_home.dart         # Merchant control panel & Deal publishing logic
├── notifications_screen.dart# Range & Category filter settings
├── ai_guide_screen.dart    # AI Chat interface & logic
├── saved_stores.dart       # User favorites list
└── database_service.dart   # Centralized Firestore logic
```

---

## 👩‍💻 Developed By
- **Ayat Jaradat**
- **Aya Shnnaq**

*Made with ❤️ in Jordan to help people save smarter.*
