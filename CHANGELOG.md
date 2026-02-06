# Changelog

All notable changes to Wasup Chuck's will be documented in this file.

## [1.2.0] - 2026-02-06

### Added
- **Favorites System**: Mark and track your favorite menu items
  - Tap star icons on menu items to save favorites
  - Add keyword-based favorites (e.g., "pizza", "fish") to auto-match items
  - Visual highlighting with orange stars and backgrounds
  - Persistent storage across app restarts
  - Favorites manager sheet for easy organization
- **Smart Notifications**: Get notified when your favorites are available
  - Alerts sent 1 hour before meals with favorite items
  - Shows up to 3 items with count for additional matches
  - Automatic rescheduling when favorites or menus change
  - Works with both individual items and keyword matches
- **Multi-Day View**: Plan ahead with future menu access
  - Swipe through multiple days of upcoming menus
  - Navigate with arrow buttons or swipe gestures
  - Select different meals (Breakfast, Lunch, Dinner) for each day
  - Clear date labels: "Today", "Tomorrow", and day-of-week names
- **GitHub Actions**: Automated APK builds on release

### Changed
- Android UI enhanced with star buttons and favorite highlighting
- Improved venue cards with favorite item backgrounds
- Better navigation experience between days

### Technical
- FavoritesRepository with DataStore for Android
- NotificationScheduler using WorkManager
- POST_NOTIFICATIONS permission added for Android
- Updated VenueCard, HomeScreen, HomeViewModel components

**Full Changelog**: https://github.com/taciturnaxolotl/wasup-chucks/compare/v1.1.0...v1.2.0

## [1.1.0] - 2025-01-30

### Added
- **Android App**
  - Native Android app with Material Design 3
  - Home screen with status cards and meal schedules
  - Venue cards with expandable menu items
  - Allergen badges for dietary information
  - Pull-to-refresh functionality
  - Responsive layout for tablets and phones
  
- **Android Widgets**
  - Small widget showing current status
  - Medium widget with status and next meal
  - Large widget with full meal menu
  - Glance-based widgets with Material 3 styling
  - Auto-refresh every 30 minutes

- **iOS Multi-Day Support**
  - View menus for multiple days
  - Tab-based navigation between days
  - Support for different schedules (weekday, Saturday, Sunday)

- **Improved Caching**
  - 12-hour cache expiration (iOS & Android)
  - App Group sharing for iOS widgets
  - Persistent disk cache for Android
  - Stale-while-revalidate pattern

### Changed
- Better Material Theme implementation on Android
- Improved icon and app branding
- More polished UI across both platforms

## [1.0.0] - 2025-01-15

### Added
- **iOS App**
  - Real-time Chuck's dining hall status
  - Current meal phase display (Breakfast, Lunch, Dinner, Closed)
  - Countdown timer until meal ends or next meal starts
  - Today's meal schedule with tap-to-view menu details
  - Venue-organized menu display
  - Allergen information badges
  - Pull-to-refresh functionality
  - Error handling with retry
  - Responsive design for iPhone and iPad
  - iOS 16+ support

- **iOS Widgets**
  - Lock screen widgets (circular and rectangular)
  - Home screen widgets
  - Real-time status updates
  - Glanceable meal information

- **Siri Integration**
  - App Intents for Siri commands
  - Ask Siri about Chuck's status
  - Voice queries for current menu

- **Core Features**
  - Timezone-aware (America/New_York)
  - Schedule-aware (different hours for weekdays, Saturday, Sunday)
  - Chuck's API integration
  - Menu caching
  - Privacy-focused (no data collection)

### Technical
- SwiftUI for iOS
- Jetpack Compose for Android
- Hilt for Android dependency injection
- Retrofit for networking
- DataStore for Android preferences
- WorkManager for Android background tasks
- Glance for Android widgets

---

**Note:** Version 1.2.0 brings feature parity between iOS and Android with the addition of favorites, notifications, and multi-day views to both platforms.
