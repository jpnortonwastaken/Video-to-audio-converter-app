# AppFast

A production-ready iOS template app built with SwiftUI and MVVM architecture. Designed for rapid duplication when starting new iOS projects.

## Features

- **Sign in with Apple** - Secure authentication with nonce-based flow
- **Supabase Backend** - PostgreSQL database with real-time capabilities
- **SSL Certificate Pinning** - Enhanced security for network requests
- **Onboarding Flow** - Polished multi-step user onboarding
- **Analytics** - Mixpanel integration for user tracking
- **Paywall** - Superwall integration for monetization
- **Haptic Feedback** - Pre-warmed haptics for instant response
- **Dark Mode** - Full support with user preference switching
- **Custom Animations** - Bounce button styles and smooth transitions

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Backend**: Supabase (Auth, Database, Functions)
- **Dependencies**: Swift Package Manager only
- **Minimum iOS Version**: 17.0

## Quick Start

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Supabase account and project
- Apple Developer account (for Sign in with Apple)

### Installation

1. Clone this repository
2. Open `AppFast.xcodeproj` in Xcode
3. Update configuration (see [Duplication Guide](#duplicating-this-template))
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
AppFast/
├── ViewModels/              # MVVM ViewModels
│   ├── AuthViewModel.swift
│   ├── OnboardingViewModel.swift
│   └── UserProfileViewModel.swift
├── Views/
│   ├── Screens/             # Main app screens
│   │   ├── HomeView.swift
│   │   ├── SettingsView.swift
│   │   └── LoginView.swift
│   ├── Onboarding/          # Onboarding flow screens
│   └── Components/          # Reusable UI components
├── Services/                # Business logic & integrations
│   ├── SupabaseService.swift
│   ├── MixpanelService.swift
│   └── NetworkSecurityManager.swift
├── Models/                  # Data models
│   ├── Profile.swift
│   └── OnboardingData.swift
├── Utilities/               # Helper utilities
│   ├── AppConstants.swift   # Centralized configuration
│   ├── HapticManager.swift
│   └── BounceButtonStyle.swift
└── Resources/
    └── Assets.xcassets/     # App icons and images
```

## Key Architecture Patterns

### Configuration Management

All configuration is centralized in two locations:

1. **`Info.plist`** - API keys and URLs
2. **`AppConstants.swift`** - App-specific constants

```swift
// Example usage
Text(AppConstants.appName)
let url = AppConstants.supabaseURL
let key = AppConstants.superwallAPIKey
```

### Reactive State Management

Uses Combine framework for reactive state propagation:

```swift
// Services publish state changes
@Published var isAuthenticated: Bool = false

// ViewModels observe via Combine
SupabaseService.shared.$isAuthenticated
    .assign(to: &$isAuthenticated)

// Views consume via @EnvironmentObject
@EnvironmentObject var authManager: AuthViewModel
```

### Async/Await + Combine Bridge

Modern async/await for API calls, Combine for UI updates:

```swift
Task {
    await performAsyncOperation()
    await MainActor.run {
        // Update UI on main thread
    }
}
```

## Duplicating This Template

When using this as a template for a new project, follow the [DUPLICATION_CHECKLIST.md](DUPLICATION_CHECKLIST.md) for step-by-step instructions.

### Quick Summary

**3 Files to Update:**

1. **`Info.plist`** - Update all API keys and URLs
   - SupabaseURL
   - SupabaseAnonKey
   - MixpanelToken
   - SuperwallAPIKey
   - PrivacyPolicyURL

2. **`AppConstants.swift`** - Change app name
   ```swift
   static let appName = "YourAppName"  // Line 17
   ```

3. **`.mcp.json`** - Update project-ref and access-token

**Additional Changes:**
- Update bundle identifier in Xcode project settings
- Replace app icons in Assets.xcassets
- Update Apple Sign in configuration in Supabase
- Configure NetworkSecurityManager certificate hashes (if needed)

See [DUPLICATION_CHECKLIST.md](DUPLICATION_CHECKLIST.md) for complete details.

## Authentication Flow

### Sign in with Apple

1. Generate cryptographically secure nonce
2. Hash nonce with SHA-256
3. Request Apple ID credential
4. Exchange identity token with Supabase
5. Database trigger creates user profile
6. UI updates via reactive state

### Security Features

- **Nonce-based flow** prevents replay attacks
- **SSL certificate pinning** for Supabase (Let's Encrypt certificates)
- **Automatic token refresh** via Supabase implicit auth flow

## Analytics & Monitoring

### Mixpanel Integration

Track user events and behavior:

```swift
MixpanelService.shared.track(event: "button_clicked", properties: [
    "screen": "home",
    "button": "sign_out"
])
```

Configure in `Info.plist`:
```xml
<key>MixpanelToken</key>
<string>YOUR_TOKEN</string>
```

### Superwall Paywall

Monetization via subscription paywall:

```swift
// Configured in AppFastApp.swift
Superwall.configure(apiKey: AppConstants.superwallAPIKey)
```

## UX Best Practices

### Haptic Feedback

**All buttons use soft haptic feedback:**

```swift
Button(action: {
    HapticManager.shared.softImpact()
    // button action
}) {
    // button content
}
```

Pre-warmed in `AppFastApp.init()` to eliminate first-tap delay.

### Custom Button Styles

```swift
// Bounce animation on tap
Button("Tap Me") { }
    .buttonStyle(BounceButtonStyle())
```

### Loading States

Consistent loading indicators and error handling across all async operations.

## Development

### MCP Server Integration

Project uses 3 MCP servers (configured in `.mcp.json`):

- **context7**: Documentation search for Swift/iOS APIs
- **XcodeBuildMCP**: Build automation and simulator management
- **supabase**: Backend operations

### Code Style

- **Naming**: ViewModels end in `ViewModel`, Services in `Service`
- **State Management**: Use `@Published` in ViewModels, `@StateObject` for initialization
- **UI Updates**: Always use `@MainActor` for main-thread operations
- **Error Handling**: Custom error enums with `LocalizedError` conformance

## Troubleshooting

### Build Failures

- Clean derived data: `Product > Clean Build Folder`
- Verify iOS 17.0+ deployment target
- Check Swift Package dependencies are resolved

### Authentication Issues

- Verify Info.plist has correct Supabase credentials
- Ensure Apple Sign in is enabled in Supabase project
- Check bundle identifier matches Apple Sign in configuration
- Verify AppFast.entitlements includes Sign in with Apple capability

### Certificate Pinning Failures

If Supabase rotates certificates, update `NetworkSecurityManager`:

```bash
# Get new certificate hash
echo | openssl s_client -servername YOUR_PROJECT.supabase.co \
  -connect YOUR_PROJECT.supabase.co:443 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform der | \
  openssl dgst -sha256 -binary | \
  openssl enc -base64
```

## Contributing

This is a personal template project. Feel free to fork and customize for your own use.

## License

Copyright 2025 JP Norton. All rights reserved.

## Support

For issues or questions, refer to the [CLAUDE.md](CLAUDE.md) for detailed technical documentation.
