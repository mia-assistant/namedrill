# NameDrill

**Learn names fast with spaced repetition flashcards.**

A Flutter app designed for teachers to learn and remember student names using proven spaced repetition techniques.

## Features

- 📸 **Photo-based flashcards** - Add student photos with names and notes
- 🎯 **Learn Mode** - Flashcard-style practice with face→name and name→face cards
- ⏱️ **Quiz Mode** - Timed multiple-choice challenges (60 seconds)
- 📊 **Progress Tracking** - Track learning progress, streaks, and weak spots
- 🌙 **Dark Mode** - System default or manual toggle
- 🔒 **Privacy First** - All data stored locally on device (no cloud)
- 📦 **Groups** - Organize students by class/period

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter 3.24.0 or higher
- Android SDK 34+
- iOS 13+ (for iOS builds)

### Installation

```bash
# Clone the repository
git clone https://github.com/mia-assistant/namedrill.git

# Navigate to the app directory
cd namedrill/app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Architecture

- **State Management:** Riverpod
- **Database:** SQLite (sqflite)
- **Spaced Repetition:** SM-2 algorithm

### Folder Structure

```
lib/
├── core/
│   ├── constants/    # App constants (limits, durations)
│   ├── theme/        # App theme (light/dark)
│   └── utils/        # Spaced repetition algorithm
├── data/
│   ├── database/     # SQLite database helper
│   ├── models/       # Data models
│   └── repositories/ # Data access layer
└── presentation/
    ├── providers/    # Riverpod providers
    ├── screens/      # All app screens
    └── widgets/      # Reusable widgets
```

## Pricing

| Tier | Price | Limits |
|------|-------|--------|
| Free | $0 | 2 groups, 25 people/group |
| Premium | $4.99 (one-time) | Unlimited |

## RevenueCat Setup (In-App Purchases)

NameDrill uses [RevenueCat](https://www.revenuecat.com/) for managing in-app purchases. To set up purchases:

### 1. Create RevenueCat Project

1. Sign up at [app.revenuecat.com](https://app.revenuecat.com)
2. Create a new project for NameDrill

### 2. Configure App Stores

**App Store Connect (iOS):**
- Create an in-app purchase: Product ID `namedrill_premium`
- Type: Non-consumable
- Price: $4.99
- Add App Store shared secret to RevenueCat

**Google Play Console (Android):**
- Create an in-app product: Product ID `namedrill_premium`
- Type: One-time purchase
- Price: $4.99
- Link Google Play service credentials to RevenueCat

### 3. RevenueCat Configuration

In the RevenueCat dashboard:
1. **Product:** Create `namedrill_premium` and map to both store products
2. **Entitlement:** Create `premium` entitlement
3. **Offering:** Create `default` offering with the premium product (as Lifetime package)

### 4. Add API Keys

Get your API keys from RevenueCat → Project Settings → API Keys

Edit `lib/core/services/purchase_service.dart`:
```dart
static const String _appleApiKey = 'YOUR_REVENUECAT_APPLE_API_KEY';
static const String _googleApiKey = 'YOUR_REVENUECAT_GOOGLE_API_KEY';
```

**⚠️ Important:** Do not commit real API keys to version control. Consider using environment variables or a secrets management solution for production.

## Roadmap

- [ ] Widget for home screen
- [ ] iCloud/Google Drive backup
- [ ] More languages (Spanish, German, French)
- [ ] Team sync for departments

## License

This project is proprietary. See PRD.md for details.

## Author

Built by [Mia](https://github.com/mia-assistant) 🤖
