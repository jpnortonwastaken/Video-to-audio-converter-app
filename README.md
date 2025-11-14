# HEIC to JPG

An iOS app for converting HEIC images to JPG and other formats. Simple, fast, and easy to use.

## Features

- **HEIC to JPG Conversion** - Convert Apple's HEIC photos to universal JPG format
- **Multiple Format Support** - Convert between JPG, PNG, HEIF, and other image formats
- **Conversion History** - Track all your conversions in one place
- **Onboarding Flow** - Smooth introduction to app features
- **Paywall Integration** - Superwall-powered monetization
- **Haptic Feedback** - Polished UX with haptic responses
- **Dark Mode** - Full support for light and dark appearance

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Monetization**: Superwall
- **Dependencies**: Swift Package Manager
- **Minimum iOS Version**: 17.0

## Quick Start

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Superwall account (for paywall functionality)

### Installation

1. Clone this repository
2. Open `AppFast.xcodeproj` in Xcode
3. Update `Info.plist` with your Superwall API key
4. Build and run

### Building the Project

```bash
# Build for simulator (iPhone 16)
xcodebuild -project AppFast.xcodeproj -scheme AppFast \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build
xcodebuild -project AppFast.xcodeproj -scheme AppFast clean
```

## Project Structure

```
HEICtoJPG/
├── ViewModels/              # MVVM ViewModels
│   ├── OnboardingViewModel.swift
│   └── UserProfileViewModel.swift
├── Views/
│   ├── Screens/             # Main app screens
│   │   ├── HomeView.swift   # Conversion interface
│   │   ├── ProgressView.swift
│   │   └── SettingsView.swift
│   ├── Onboarding/          # 5-slide onboarding flow
│   └── Components/          # Reusable UI components
├── Services/                # Business logic
│   ├── OnboardingDataStorage.swift
│   └── ProfileService.swift
├── Models/                  # Data models
│   ├── OnboardingData.swift
│   └── Profile.swift
├── Utilities/               # Helper utilities
│   ├── AppConstants.swift   # Centralized configuration
│   ├── HapticManager.swift
│   └── BounceButtonStyle.swift
└── Resources/
    └── Assets.xcassets/     # App icons and images
```

## Configuration

### Info.plist

Update the following keys:

```xml
<key>SuperwallAPIKey</key>
<string>YOUR_SUPERWALL_API_KEY</string>

<key>PrivacyPolicyURL</key>
<string>https://yourwebsite.com/privacy</string>

<key>AppDisplayName</key>
<string>HEICJPG</string>
```

### AppConstants.swift

The app name is centralized in `HEICtoJPG/Utilities/AppConstants.swift`:

```swift
static let appName = "HEIC to JPG"  // Line 17
```

## Onboarding Flow

The app features a 5-slide onboarding experience:

1. **HEIC to JPG** - Main feature introduction
2. **Multiple Formats** - Additional conversion capabilities
3. **Conversion History** - Track all conversions
4. **App Store Review** - StoreKit review request
5. **Paywall** - Superwall monetization screen

## Development

### MCP Server Integration

Project configured with MCP servers in `.mcp.json`:
- **context7**: Documentation search for Swift/iOS APIs
- **XcodeBuildMCP**: Build automation and simulator management
- **superwall-docs**: Superwall documentation access

### Code Conventions

- ViewModels end in `ViewModel`
- Services end in `Service`
- Use `@Published` for reactive state
- All UI updates via `@MainActor`

## UX Details

### Haptic Feedback

All buttons use soft haptic feedback for a polished feel:

```swift
Button(action: {
    HapticManager.shared.softImpact()
    // button action
}) { }
```

HapticManager is pre-warmed at app launch to eliminate first-tap delay.

## License

Copyright 2025 JP Norton. All rights reserved.

## Documentation

For detailed technical documentation, see [CLAUDE.md](CLAUDE.md).
