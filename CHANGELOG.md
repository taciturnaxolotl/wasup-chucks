# Changelog

All notable changes to Wasup Chuck's will be documented in this file.

## [1.2.0] - 2026-02-06

### Added
- **Favorites System** (iOS & Android)
  - Mark individual menu items as favorites
  - Add keyword-based favorites (e.g., "pizza", "fish")
  - Visual highlighting of favorite items with star icons
  - Favorites manager sheet for managing items and keywords
  - Persistent storage across app launches
  
- **Notifications** (iOS & Android)
  - Receive notifications 1 hour before meals when favorites are available
  - Smart notification content showing up to 3 items with count for additional matches
  - Automatic rescheduling when favorites or menus change
  - Works with both individual items and keyword-based favorites

- **Future Day View** (iOS & Android)
  - Swipe through multiple days of menus
  - Navigate with left/right arrows
  - View schedules for upcoming days
  - Select different meals for future days
  - Displays dates (Today, Tomorrow, day names)

- **GitHub Actions**
  - Automated APK builds on release

### Changed
- Updated Android UI to support favorites with star buttons
- Enhanced venue cards with favorite item highlighting
- Improved navigation between days

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
