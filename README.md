# 🔴 DROP - Your Smart Savings Companion in Jordan

**Drop** is a cutting-edge Flutter application designed to bridge the gap between savvy shoppers and local merchants in Jordan. It leverages Artificial Intelligence, Location-Based Services, and a highly customizable UI to ensure users save smarter every day.

---

## 🚀 Key Features

### 👤 For Savers (Users)
- **Dynamic Theming Engine:** Choose from 5 beautiful themes (Light, Dark, Midnight Blue, Emerald Forest, and Purple Velvet). Custom branding ensures icons like "Favorites" stay recognizable in red while the UI adapts to your style. 🎨
- **Real-time Follower Alerts:** Get instant notifications the second a store you follow publishes a new deal. 🔥
- **Smart Savings Tracker:** Track how much you've saved with a built-in wallet summary. Includes a **Reset Savings** feature to restart your tracking daily or weekly. 💰
- **Drop AI Assistant:** A smart, friendly AI guide (powered by Gemini 1.5 Flash) that helps you find the best deals using natural Jordanian dialect.
- **Proximity-Based Discovery:** Explore deals on an interactive map or filter them by distance.
- **Auto-Clean Feed:** Expired deals are automatically hidden, keeping the feed fresh and relevant.

### 🏪 For Merchants (Store Owners)
- **Instant Reach:** Every deal you publish instantly triggers notifications to all your followers.
- **Merchant Dashboard:** A professional suite to publish, edit, and track active discounts and analytics.
- **Deal Lifecycle Management:** Set expiry times for deals. Expired deals are archived for easy re-activation.
- **Subscription System:** Built-in membership management with premium feature toggles.

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Multi-platform UI)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Backend:** [Firebase](https://firebase.google.com/) (Firestore, Auth, Storage, FCM)
- **Local Storage:** [Shared Preferences](https://pub.dev/packages/shared_preferences) (for theme persistence)
- **Artificial Intelligence:** [Google Generative AI](https://ai.google.dev/) (Gemini 1.5 Flash Model)
- **Maps:** [Flutter Map](https://pub.dev/packages/flutter_map) (OpenStreetMap based)
- **Localization:** [Easy Localization](https://pub.dev/packages/easy_localization) (Full AR/EN support)

---

## 🏗 Project Structure

```text
lib/
├── app_colors.dart         # Centralized Theming Engine & Multi-Theme Definitions
├── main.dart               # App entry, ThemeProvider, & Firebase initialization
├── home.dart               # Smart deals feed & Savings tracker (with Reset logic)
├── account.dart            # User profile, Order history, & Action center
├── setting.dart            # Multi-Theme selector & App preferences
├── map.dart                # Interactive location discovery & Store Markers
├── store_home.dart         # Merchant dashboard & Deal management
└── ai_guide_screen.dart    # AI Chat interface powered by Gemini
```

---

## 👩‍💻 Developed By
- **Ayat Jaradat**
- **Aya Shnnaq**

*Made with ❤️ in Jordan to help people save smarter.*
