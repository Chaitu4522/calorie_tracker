# Calorie Tracker

A minimal, functional Android app for tracking daily calorie intake with AI-powered estimation using Google Gemini.

## Features

- **AI-Powered Calorie Estimation**: Take a photo of your food and get instant calorie estimates using Google Gemini Vision API
- **Manual Entry**: Alternatively, log calories manually
- **Daily Tracking**: View today's entries with a progress bar showing your goal completion
- **Weekly Summary**: See your weekly trends with an interactive bar chart
- **All-Time Statistics**: Track your total entries, calories, daily averages, and streaks
- **Data Export**: Export your data as CSV for backup or analysis
- **Secure API Key Storage**: Your Gemini API key is stored securely using encrypted storage

## Screenshots

The app includes:
1. Setup screen for initial configuration
2. Daily view with calorie progress
3. Add entry screen with AI estimation
4. Weekly summary with charts
5. All-time statistics
6. Settings for profile and data management

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code with Flutter extension
- Android device or emulator (API 21+)
- Google Gemini API key (free tier available)

### How to Get a Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key
5. The free tier allows 1,500 requests/day

### Installation

1. Clone or download this repository:
   ```bash
   cd calorie_tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building APK

To build a release APK:

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── entry.dart           # Calorie entry model
│   ├── user.dart            # User profile model
│   └── models.dart          # Barrel file
├── providers/
│   ├── app_provider.dart    # Main state management
│   └── providers.dart       # Barrel file
├── services/
│   ├── database_service.dart      # SQLite operations
│   ├── secure_storage_service.dart # API key storage
│   ├── gemini_service.dart        # Gemini API integration
│   └── services.dart              # Barrel file
├── screens/
│   ├── setup_screen.dart    # Initial setup
│   ├── home_screen.dart     # Daily view
│   ├── add_entry_screen.dart # Add/edit entries
│   ├── weekly_screen.dart   # Weekly summary
│   ├── stats_screen.dart    # All-time statistics
│   ├── settings_screen.dart # App settings
│   └── screens.dart         # Barrel file
└── widgets/                  # (Future: reusable widgets)
```

## Dependencies

| Package | Purpose |
|---------|---------|
| sqflite | Local SQLite database |
| flutter_secure_storage | Encrypted API key storage |
| provider | State management |
| image_picker | Camera and gallery access |
| http | HTTP requests to Gemini API |
| fl_chart | Weekly chart visualization |
| intl | Date formatting |
| url_launcher | Opening API key setup link |
| share_plus | CSV export sharing |
| path_provider | File system paths |

## Data Storage

- **User Profile**: Stored in SQLite (name, daily goal, creation date)
- **Entries**: Stored in SQLite (description, calories, timestamp)
- **API Key**: Stored in encrypted secure storage
- **Photos**: NOT stored - only used temporarily for AI estimation

## Security

- API key is encrypted at rest using `flutter_secure_storage`
- No API key in source code
- API key never logged or displayed in plain text
- All network traffic to Gemini API uses HTTPS

## Offline Support

The app works offline except for the AI estimation feature:
- Manual entry always works
- Viewing entries and statistics works offline
- AI estimation requires internet connection

## Known Limitations

- Single user only (no accounts)
- Data stored locally only (no cloud backup)
- Re-installing the app clears all data
- Photos used for estimation are not saved

## Customization

To change the app's accent color, modify the `colorScheme` in `main.dart`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,  // Change this color
    brightness: Brightness.light,
  ),
  // ...
),
```

## Troubleshooting

**"API key invalid" error**
- Verify your API key at Google AI Studio
- Make sure you copied the entire key
- Check that the key doesn't have extra spaces

**"Rate limit exceeded" error**
- Free tier allows 1,500 requests/day
- Wait until the next day or upgrade your API plan

**Camera not working**
- Grant camera permission in device settings
- Restart the app after granting permissions

**App crashes on launch**
- Run `flutter clean` then `flutter pub get`
- Ensure minimum SDK is 21 or higher

## License

This project is provided as-is for personal use.

## Version

1.0.0
