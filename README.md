# 🔴 DROP - Your Smart Savings Companion in Jordan

**Drop** is a cutting-edge Flutter application designed to bridge the gap between savvy shoppers and local merchants in Jordan. It leverages Artificial Intelligence and Location-Based Services to ensure users never miss a deal that fits their budget and proximity.

---

## 🚀 Key Features

### 👤 For Savers (Users)
- **Drop AI Assistant:** A smart, friendly AI guide (powered by Gemini 1.5 Flash) that helps you find the best deals using natural Jordanian dialect.
- **Proximity-Based Discovery:** Explore deals on an interactive map or filter them by distance (from 0 to 20km).
- **Smart Notifications:** Customize alerts based on your interests (Food, Fashion, Cafes, etc.) and your current location.
- **Real-time Search:** A dual-search system—one for AI suggestions and another for direct store/product lookups.
- **Favorites Gallery:** Save your favorite deals with a single tap and access them anytime, even offline-ready.
- **Countdown Timers:** Smart expiry labels that show days remaining, or switch to hours for deals ending within 24h.

### 🏪 For Merchants (Store Owners)
- **Merchant Dashboard:** A professional suite to publish, edit, and track active discounts.
- **Custom Expiry (Alarm Style):** Complete freedom to set deal endings using an intuitive Date & Time picker.
- **Category Targeting:** List stores under specific categories to reach the most interested customers.
- **Subscription Management:** Built-in system to track and renew store membership status.

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
├── ai_guide_screen.dart    # AI Chat interface & logic
├── home.dart               # Smart search & deals feed
├── map.dart                # Interactive location discovery
├── notifications_screen.dart# Range & Category filter settings
├── store_home.dart         # Merchant control panel
├── saved_stores.dart       # User favorites list
├── database_service.dart   # Centralized Firestore logic
└── main.dart               # App entry & Firebase init
```

---

## ⚙️ Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/ayatdrop.git
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Firebase Configuration:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
   - Enable Firestore and Authentication in the Firebase Console.
4. **AI API Key:**
   - Replace the API key in `lib/ai_guide_screen.dart` with your own from [Google AI Studio](https://aistudio.google.com/).
5. **Run the app:**
   ```bash
   flutter run
   ```

---

## 👩‍💻 Developed By
- **Ayat Jaradat**
- **Aya Shnnaq**

*Made with ❤️ in Jordan to help people save smarter.*
