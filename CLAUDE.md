# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AppFast is a production-ready iOS template app built with SwiftUI and MVVM architecture. It's designed for rapid duplication when starting new iOS projects, featuring Sign in with Apple authentication backed by Supabase, SSL certificate pinning, and polished UX details.

## Build & Run

### Building the Project
```bash
# Build for simulator (iPhone 16, iOS 18.5)
xcodebuild -project AppFast.xcodeproj -scheme AppFast \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build
xcodebuild -project AppFast.xcodeproj -scheme AppFast clean
```

### Running Tests
No test infrastructure is currently configured. When adding tests, use:
```bash
xcodebuild test -project AppFast.xcodeproj -scheme AppFast \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### MCP Integration
The project is configured with three MCP servers in `.mcp.json`:
- **context7**: Documentation search for Swift/iOS APIs
- **XcodeBuildMCP**: Build automation and simulator management
- **supabase**: Backend operations (project: crypgmbxcoemieblmkxt)

## Architecture

### MVVM Structure
```
ViewModels/
  └── AuthViewModel.swift        # Authentication state & Sign in with Apple flow
Views/
  ├── Screens/
  │   ├── LoginView.swift       # Sign in with Apple screen
  │   └── HomeView.swift        # Post-authentication home
  └── Components/               # Ready for reusable UI components
Services/
  ├── SupabaseService.swift     # Backend integration singleton
  └── NetworkSecurityManager.swift  # SSL certificate pinning
Models/
  └── Profile.swift             # User profile (maps to Supabase profiles table)
Utilities/
  ├── HapticManager.swift       # Pre-warmed haptic feedback
  └── BounceButtonStyle.swift  # Custom button animation
```

### Key Architectural Patterns

**Singleton Services**: `SupabaseService.shared`, `HapticManager.shared`, `NetworkSecurityManager.shared` provide single sources of truth with app-lifetime scoping.

**Reactive State Management**: Combine framework propagates state changes. `SupabaseService` publishes `isAuthenticated`, which `AuthViewModel` observes via `.assign(to:on:)`, and views consume via `@EnvironmentObject`.

**Async/Await + Combine Bridge**: Modern async/await for API calls, Combine for reactive observation. Bridge via `Task { @MainActor in }` for main-thread updates.

**Coordinator Pattern**: `AppleSignInCoordinator` wraps ASAuthorizationController delegate callbacks, using `CheckedContinuation` to bridge to async/await.

## Configuration Management

### Info.plist (Primary Configuration)
All project-specific configuration lives in `Info.plist`, NOT hardcoded in Swift:

```xml
<key>SupabaseURL</key>
<string>https://YOUR_PROJECT.supabase.co</string>

<key>SupabaseAnonKey</key>
<string>YOUR_ANON_KEY</string>
```

**When duplicating this template:**
1. Update `Info.plist` with new Supabase credentials
2. Update `.mcp.json` with new project-ref and access token
3. Update `NetworkSecurityManager` pinned domains if needed

### Entitlements
`AppFast.entitlements` enables Sign in with Apple:
```xml
<key>com.apple.developer.applesignin</key>
<array><string>Default</string></array>
```

## Authentication Flow

### Sign in with Apple Implementation

**Complete Flow** (AuthViewModel → SupabaseService):
1. Generate cryptographically secure 32-char nonce via `SecRandomCopyBytes`
2. Hash nonce with SHA-256 for Apple request
3. Create `ASAuthorizationAppleIDRequest` with hashed nonce
4. Use `AppleSignInCoordinator` for async/await delegate handling
5. Extract identity token from `ASAuthorizationAppleIDCredential`
6. Call `client.auth.signInWithIdToken()` with **original unhashed nonce**
7. Supabase validates nonce matches Apple's embedded hash
8. Database trigger creates profile in `profiles` table
9. Update `isAuthenticated` state, UI reacts via Combine

**Error Handling**: `AuthViewModel` silently handles user cancellation (ASAuthorizationError.canceled) without showing error messages. All other errors display user-friendly messages via custom `AuthError` enum.

### SupabaseService Architecture

**Initialization** (runs once at app launch):
```swift
private init() {
    // Read from Info.plist
    guard let urlString = Bundle.main.infoDictionary?["SupabaseURL"] as? String,
          let url = URL(string: urlString) else {
        fatalError("Invalid or missing Supabase URL in Info.plist")
    }
    // ... initialize client with implicit auth flow
    // Check initial auth state asynchronously
}
```

**Client Configuration**:
- Uses implicit auth flow (tokens managed automatically)
- No custom URLSession (NetworkSecurityManager prepared but not actively used)
- Reads config from Info.plist, never hardcoded

**State Management**: Published `isAuthenticated` property synchronizes with auth state. Views observe via AuthViewModel which subscribes with Combine.

## Security Features

### SSL Certificate Pinning (NetworkSecurityManager)
Implements public key pinning for `supabase.co` and project subdomain:
- Validates SHA-256 hashes of public keys in certificate chain
- Pins Let's Encrypt certificates: R3, E1, ISRG Root X1
- Falls back to default validation for non-pinned domains

**Updating Certificate Hashes** (if Supabase rotates certificates):
```bash
echo | openssl s_client -servername YOUR_PROJECT.supabase.co \
  -connect YOUR_PROJECT.supabase.co:443 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform der | \
  openssl dgst -sha256 -binary | \
  openssl enc -base64
```

### Nonce-Based Authentication
- Cryptographically secure nonce generation prevents replay attacks
- SHA-256 hashing for Apple request, original nonce for Supabase validation
- Apple embeds nonce hash in identity token for verification

## UX Polish Details

### HapticManager Pre-Warming
**Critical Performance Optimization**: `HapticManager.shared` is accessed in `AppFastApp.init()` to eliminate first-tap delay:
```swift
init() {
    _ = HapticManager.shared  // Warm up haptics early
}
```
On first access, fires silent 0.1-intensity haptic to initialize Taptic Engine.

### BounceButtonStyle
Custom ButtonStyle with natural spring animations:
- Press: `.spring(response: 0.3, dampingFraction: 0.6)`
- Release: `.spring(response: 0.4, dampingFraction: 0.8)`
- Configurable scale amount (default 0.95)
- Applied to Sign in with Apple and Sign Out buttons

## Template Duplication Workflow

When using this as a template for a new project, follow this comprehensive checklist:

### Core Configuration (Required)

**1. Update `AppConstants.swift`** (Line 17):
```swift
static let appName = "YourNewAppName"  // Single line change!
```
This automatically updates all UI references throughout the app.

**2. Update `Info.plist`** (7 keys to update):
```xml
<key>SupabaseURL</key>
<string>https://YOUR_NEW_PROJECT.supabase.co</string>

<key>SupabaseAnonKey</key>
<string>YOUR_NEW_ANON_KEY</string>

<key>MixpanelToken</key>
<string>YOUR_NEW_MIXPANEL_TOKEN</string>

<key>SuperwallAPIKey</key>
<string>YOUR_NEW_SUPERWALL_KEY</string>

<key>PrivacyPolicyURL</key>
<string>https://yourwebsite.com/privacy</string>

<key>AppDisplayName</key>
<string>Your App Display Name</string>
```

**3. Update `.mcp.json`**:
- Copy `.mcp.json` to new project
- Change `project-ref` to new Supabase project ID
- Generate new `access-token` from Supabase dashboard

**4. Update Xcode Project Settings**:
- **Bundle Identifier**: `com.yourcompany.yourapp`
- **Development Team**: Your Apple Developer Team
- **Display Name**: Your App Name
- **Marketing Version**: 1.0 (or your starting version)
- **Build Number**: 1

**5. Replace Assets** in `Assets.xcassets`:
- `AppIcon` - Main app icon (1024x1024 and all sizes)
- `WelcomeScreenAppIcon` - Onboarding screen icon
- `LaunchscreenAppIcon` - Launch screen icon

### Backend Configuration

**6. Configure Supabase Backend**:

a. **Enable Apple Sign In Provider**:
   - Go to Authentication > Providers > Apple
   - Add your Apple Service ID
   - Add Apple Team ID and Key ID
   - Upload Apple Sign In private key

b. **Set up Database**:
   ```sql
   -- Create profiles table
   create table profiles (
     id uuid references auth.users primary key,
     display_name text,
     created_at timestamp with time zone default now(),
     updated_at timestamp with time zone default now()
   );

   -- Auto-create profile trigger
   create or replace function handle_new_user()
   returns trigger as $$
   begin
     insert into public.profiles (id)
     values (new.id);
     return new;
   end;
   $$ language plpgsql security definer;

   create trigger on_auth_user_created
     after insert on auth.users
     for each row execute function handle_new_user();

   -- Row Level Security
   alter table profiles enable row level security;

   create policy "Users can view own profile"
     on profiles for select
     using (auth.uid() = id);

   create policy "Users can update own profile"
     on profiles for update
     using (auth.uid() = id);
   ```

c. **Configure RLS Policies** for additional tables as needed

**7. Configure NetworkSecurityManager** (if using SSL pinning):
- Domains are now auto-configured from AppConstants.supabaseURL
- Update certificate hashes if Supabase rotates certificates
- Or remove SSL pinning code if not needed

### Third-Party Services

**8. Set up Mixpanel**:
- Create new Mixpanel project at mixpanel.com
- Copy project token to Info.plist `MixpanelToken`
- Analytics events will start tracking automatically

**9. Set up Superwall** (for monetization):
- Create account at superwall.com
- Create new app and get API key
- Add API key to Info.plist `SuperwallAPIKey`
- Configure paywall campaigns in Superwall dashboard

### Verification Steps

**10. Build & Test**:
```bash
# Clean build
xcodebuild -project YourApp.xcodeproj -scheme YourApp clean

# Build for simulator
xcodebuild -project YourApp.xcodeproj -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**11. Test Checklist**:
- [ ] App launches without crashes
- [ ] Sign in with Apple works
- [ ] User profile created in Supabase
- [ ] App name displays correctly throughout UI
- [ ] Settings privacy policy URL opens correctly
- [ ] Mixpanel events are tracked (check Mixpanel dashboard)
- [ ] Superwall paywall displays (if configured)
- [ ] Dark mode switches correctly
- [ ] Haptic feedback works on button taps

### Optional Customization

**12. Customize Onboarding Flow** (optional):
- Modify `OnboardingContentViews.swift` for your app's specific onboarding
- Update `OnboardingStep` enum in `OnboardingViewModel.swift`
- Adjust copy and imagery to match your brand

**13. Update App Features**:
- Replace `HomeView.swift` content with your main features
- Add your app-specific screens to `Views/Screens/`
- Create reusable components in `Views/Components/`

## Analytics Integration

### Mixpanel

**Overview**: Mixpanel is integrated for user analytics and event tracking.

**Configuration**:
```xml
<!-- Info.plist -->
<key>MixpanelToken</key>
<string>YOUR_MIXPANEL_TOKEN</string>
```

**Service Architecture**:
```swift
// Singleton service initialized in AppFastApp.init()
_ = MixpanelService.shared

// Track events anywhere in the app
MixpanelService.shared.track(event: "button_tapped", properties: [
    "screen": "home",
    "button_name": "sign_out"
])

// Identify users
MixpanelService.shared.identify(userId: user.id)

// Set user properties
MixpanelService.shared.setUserProperty("subscription_tier", value: "premium")
```

**Current Tracked Events**:
- Screen views throughout onboarding flow
- Onboarding completion
- Authentication events
- Button interactions
- User property changes

**Adding New Events**:
```swift
// In your view or view model
MixpanelService.shared.track(event: "feature_used", properties: [
    "feature_name": "export_data",
    "item_count": 5,
    "format": "pdf"
])
```

**Best Practices**:
- Use consistent event naming (snake_case)
- Include contextual properties (screen, user_id, etc.)
- Track user journeys, not just page views
- Set user properties for segmentation

## Monetization Integration

### Superwall

**Overview**: Superwall provides paywall infrastructure and A/B testing for subscription monetization.

**Configuration**:
```xml
<!-- Info.plist -->
<key>SuperwallAPIKey</key>
<string>YOUR_SUPERWALL_API_KEY</string>
```

**Initialization**:
```swift
// Configured in AppFastApp.init()
Superwall.configure(apiKey: AppConstants.superwallAPIKey)
```

**Usage**:
```swift
// Show paywall at strategic moments
Superwall.shared.register(event: "feature_gated") { paywallInfo in
    // User dismissed paywall
}

// Check subscription status
let isSubscribed = Superwall.shared.isUserSubscribed
```

**Integration Points**:
- Currently initialized at app launch
- Ready to gate premium features
- Supports multiple paywall variants for A/B testing
- Integrates with StoreKit for subscriptions

**Setting Up Paywalls**:
1. Create paywall in Superwall dashboard
2. Configure products in App Store Connect
3. Link products in Superwall
4. Create campaign rules (when to show paywall)
5. Test with sandbox accounts

**Revenue Cat Alternative**:
If you prefer Revenue Cat, replace Superwall with:
```swift
// Remove SuperwallKit dependency
// Add RevenueCat dependency
// Update AppFastApp.init() to configure Revenue Cat
```

## Dependencies

**Swift Package Manager** (only dependency manager):
- `supabase-swift` (v2.5.1+)
  - Provides: Auth, Functions, PostgREST, Realtime, Storage

**iOS Frameworks**:
- SwiftUI (UI)
- AuthenticationServices (Sign in with Apple)
- Combine (reactive state)
- CryptoKit (SHA-256)

**Deployment Target**: iOS 17.0+

## Common Issues & Solutions

### Build Failures
- Ensure MCP server `XcodeBuildMCP` is available for build automation
- Clean derived data if encountering stale build artifacts
- Verify iOS 17.0+ deployment target matches simulator version

### Authentication Not Working
- Check Info.plist has valid SupabaseURL and SupabaseAnonKey
- Verify Supabase project has Apple auth provider enabled
- Ensure bundle identifier matches Supabase Apple auth configuration
- Check AppFast.entitlements includes Sign in with Apple capability

### Certificate Pinning Failures
- Update `NetworkSecurityManager` certificate hashes if Supabase rotates certificates
- Check `pinnedDomains` includes your project subdomain
- Review Xcode console for detailed pinning failure logs

## Code Style & Conventions

### Naming Patterns
- ViewModels: `*ViewModel` (e.g., `AuthViewModel`)
- Services: `*Service` (e.g., `SupabaseService`)
- Managers: `*Manager` (e.g., `HapticManager`, `NetworkSecurityManager`)

### State Management
- Use `@Published` in ViewModels/Services for reactive state
- Use `@StateObject` for ViewModel initialization
- Use `@EnvironmentObject` for ViewModel injection into views
- All UI updates via `@MainActor` or `Task { @MainActor in }`

### Error Handling
- Custom error enums with `LocalizedError` conformance
- User-friendly error messages (not raw technical errors)
- Silent handling of user-initiated cancellations
- Comprehensive debug logging with emoji indicators (✅, ❌, 🔐, etc.)

### UX & Haptic Feedback
- **ALL buttons must use soft haptic feedback**: Call `HapticManager.shared.softImpact()` in button action handlers
- This creates consistent, polished feel across the entire app
- Example:
```swift
Button(action: {
    HapticManager.shared.softImpact()
    // button action
}) {
    // button content
}
```

## Architecture Decisions

### Why No Separate SupabaseConfig?
Previously had `SupabaseConfig.swift`, but consolidated into `SupabaseService.init()` to match cleaner pattern. Config still externalized to Info.plist for easy template duplication.

### Why Keep NetworkSecurityManager?
SSL pinning prepared but not actively enforcing. Ready to enable for production apps requiring additional security. Can be removed if not needed.

### Why HapticManager Pre-Warming?
iOS Taptic Engine has ~100ms initialization delay on first use. Pre-warming in app init eliminates this delay for better first-impression UX.

### Why Implicit Auth Flow?
Supabase handles token refresh automatically with implicit flow. No manual token management needed, reducing complexity and potential auth bugs.
