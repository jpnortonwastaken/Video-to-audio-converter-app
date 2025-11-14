# AppFast Template Duplication Checklist

This checklist provides step-by-step instructions for duplicating AppFast as a template for new iOS projects.

## Prerequisites

- [ ] Xcode 15.0+ installed
- [ ] Apple Developer account
- [ ] New Supabase project created
- [ ] New Mixpanel project created (optional)
- [ ] New Superwall app created (optional)

---

## Phase 1: Core Configuration (Required)

### 1. Update App Name

- [ ] Open `AppFast/Utilities/AppConstants.swift`
- [ ] Change line 17: `static let appName = "YourNewAppName"`
- [ ] **Result**: All UI text automatically updates throughout the app

### 2. Update Info.plist

- [ ] Open `AppFast/Info.plist`
- [ ] Update these 7 keys:

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

**Where to find these values:**
- Supabase URL/Key: Supabase Dashboard → Project Settings → API
- Mixpanel Token: Mixpanel → Project Settings → Project Token
- Superwall Key: Superwall Dashboard → Settings → API Keys

### 3. Update .mcp.json (for Claude Code integration)

- [ ] Copy `.mcp.json` to your new project directory
- [ ] Open `.mcp.json`
- [ ] Update `project-ref` to your new Supabase project ID (short alphanumeric code)
- [ ] Update `access-token` (generate from Supabase Dashboard → Settings → Access Tokens)

### 4. Update Xcode Project Settings

- [ ] Open `AppFast.xcodeproj` in Xcode
- [ ] Select project in navigator → Select target → General tab
- [ ] Update:
  - [ ] **Display Name**: Your App Name
  - [ ] **Bundle Identifier**: `com.yourcompany.yourapp`
  - [ ] **Version**: 1.0 (or your starting version)
  - [ ] **Build**: 1
- [ ] Go to Signing & Capabilities tab
- [ ] Update **Team**: Select your Apple Developer Team

### 5. Replace App Icons

- [ ] Open `Assets.xcassets`
- [ ] Replace these icon sets:
  - [ ] **AppIcon** - All sizes (drag 1024x1024 into App Store slot, Xcode generates others)
  - [ ] **WelcomeScreenAppIcon** - 60x60 icon for onboarding
  - [ ] **LaunchscreenAppIcon** - Launch screen icon

**Tip**: Use a tool like [App Icon Generator](https://www.appicon.co/) to generate all sizes

---

## Phase 2: Backend Configuration

### 6. Configure Supabase

#### 6a. Enable Apple Sign In

- [ ] Go to Supabase Dashboard → Authentication → Providers
- [ ] Enable **Apple** provider
- [ ] Fill in:
  - [ ] **Service ID**: Your Apple Service ID (e.g., `com.yourcompany.yourapp.signin`)
  - [ ] **Team ID**: Your Apple Developer Team ID (10 characters)
  - [ ] **Key ID**: Apple Sign In Key ID from Apple Developer
  - [ ] **Private Key**: Upload `.p8` file from Apple Developer

**Getting Apple Credentials:**
1. Go to developer.apple.com → Certificates, IDs & Profiles
2. Create new Service ID
3. Create new Sign in with Apple Key
4. Download the `.p8` file
5. Note the Key ID (10 characters)
6. Your Team ID is in the top-right of Apple Developer portal

#### 6b. Set up Database

- [ ] Go to Supabase Dashboard → SQL Editor
- [ ] Run this SQL to create profiles table:

```sql
-- Create profiles table
create table profiles (
  id uuid references auth.users primary key,
  display_name text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Auto-create profile on user signup
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

-- Enable Row Level Security
alter table profiles enable row level security;

-- Users can view their own profile
create policy "Users can view own profile"
  on profiles for select
  using (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id);
```

- [ ] Verify table created successfully in Table Editor

### 7. SSL Certificate Pinning (Optional)

**Note**: NetworkSecurityManager automatically uses your Supabase domain from AppConstants.

- [ ] If you want to disable SSL pinning: Delete or comment out NetworkSecurityManager code
- [ ] If keeping SSL pinning: Certificate hashes are already configured for Let's Encrypt (Supabase uses this)
- [ ] If Supabase changes certificates later, update hashes in `NetworkSecurityManager.swift`

---

## Phase 3: Third-Party Services (Optional)

### 8. Set up Mixpanel Analytics

- [ ] Create account at [mixpanel.com](https://mixpanel.com)
- [ ] Create new project
- [ ] Copy Project Token
- [ ] Paste token into `Info.plist` under `MixpanelToken`
- [ ] **Result**: Analytics will automatically track events when app runs

**Testing Mixpanel:**
- [ ] Run app in simulator
- [ ] Sign in with Apple
- [ ] Go to Mixpanel Dashboard → Live View
- [ ] Verify events are appearing

### 9. Set up Superwall Paywall (Optional)

- [ ] Create account at [superwall.com](https://superwall.com)
- [ ] Create new app
- [ ] Copy API Key
- [ ] Paste key into `Info.plist` under `SuperwallAPIKey`

**Setting up subscriptions:**
- [ ] Create subscription products in App Store Connect
- [ ] Link products in Superwall dashboard
- [ ] Create paywall campaign
- [ ] Configure trigger rules (when to show paywall)

**Alternative**: Replace with RevenueCat if preferred
- [ ] Remove SuperwallKit from Swift Package Manager
- [ ] Add RevenueCat SDK
- [ ] Update `AppFastApp.swift` to configure RevenueCat instead

---

## Phase 4: Verification & Testing

### 10. Build Project

- [ ] Open Terminal
- [ ] Navigate to project directory
- [ ] Run clean build:

```bash
# Clean build
xcodebuild -project YourApp.xcodeproj -scheme YourApp clean

# Build for simulator
xcodebuild -project YourApp.xcodeproj -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

- [ ] Fix any build errors that appear
- [ ] Verify build succeeds

### 11. Test in Simulator

- [ ] Launch app in Xcode (Cmd+R)
- [ ] **Test checklist**:
  - [ ] App launches without crashes
  - [ ] App name displays correctly on all screens
  - [ ] Onboarding flow works
  - [ ] Sign in with Apple button appears
  - [ ] Click Sign in with Apple (test with sandbox account)
  - [ ] Authentication succeeds
  - [ ] User profile created in Supabase (check Table Editor)
  - [ ] Home screen loads
  - [ ] Navigate to Settings
  - [ ] Privacy Policy URL opens correctly in Safari
  - [ ] App version displays correctly in Settings
  - [ ] Sign out works
  - [ ] Dark mode toggle works
  - [ ] Haptic feedback works on button taps (if testing on device)

### 12. Verify Analytics (if using Mixpanel)

- [ ] Run app
- [ ] Complete onboarding
- [ ] Go to Mixpanel Dashboard
- [ ] Check Live View for events
- [ ] Verify these events tracked:
  - [ ] `onboarding_screen_1`
  - [ ] `onboarding_completed`
  - [ ] `user_signed_in`

### 13. Verify Paywall (if using Superwall)

- [ ] Run app
- [ ] Navigate to area where paywall should trigger
- [ ] Verify paywall displays correctly
- [ ] Test dismissing paywall
- [ ] Test subscription flow with sandbox account

---

## Phase 5: Optional Customization

### 14. Customize Onboarding Flow

- [ ] Open `OnboardingContentViews.swift`
- [ ] Modify content for your app's specific onboarding
- [ ] Update `OnboardingStep` enum in `OnboardingViewModel.swift`
- [ ] Adjust copy and images to match your brand
- [ ] Test onboarding flow end-to-end

### 15. Build Your App Features

- [ ] Replace `HomeView.swift` content with your main features
- [ ] Add new screens to `Views/Screens/`
- [ ] Create reusable components in `Views/Components/`
- [ ] Add new ViewModels to `ViewModels/`
- [ ] Add business logic Services to `Services/`

### 16. Update Privacy Policy

- [ ] Write privacy policy for your app
- [ ] Host it on your website
- [ ] Update `PrivacyPolicyURL` in Info.plist to point to it

---

## Phase 6: Prepare for App Store

### 17. Configure App Store Connect

- [ ] Create new app in App Store Connect
- [ ] Match bundle identifier
- [ ] Upload screenshots (use iPhone 15 Pro Max size)
- [ ] Write app description
- [ ] Set pricing & availability
- [ ] Configure in-app purchases (if using Superwall)
- [ ] Set age rating
- [ ] Add support URL
- [ ] Add marketing URL

### 18. Final Build & Archive

- [ ] Update version number in Xcode
- [ ] Select "Any iOS Device" as destination
- [ ] Product → Archive
- [ ] Upload to App Store Connect
- [ ] Submit for review

---

## Quick Reference Commands

### Find/Replace (if renaming files)

```bash
# Find all references to "AppFast" in Swift files
grep -r "AppFast" --include="*.swift" .

# Replace in all files (use with caution!)
find . -name "*.swift" -exec sed -i '' 's/AppFast/YourAppName/g' {} +
```

### Useful Xcode Commands

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset simulators
xcrun simctl erase all

# List available simulators
xcrun simctl list devices
```

### Git Commands (after duplication)

```bash
# Initialize new git repo
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit from AppFast template"

# Add remote
git remote add origin https://github.com/yourusername/yourapp.git

# Push to main
git push -u origin main
```

---

## Troubleshooting

### "SupabaseURL not found in Info.plist"
- Check Info.plist has `SupabaseURL` key with valid URL
- Clean build folder and rebuild

### "Apple Sign In fails"
- Verify bundle identifier matches in:
  - Xcode project settings
  - Apple Developer portal Service ID
  - Supabase Apple provider settings
- Check `.entitlements` file includes Sign in with Apple capability

### "Mixpanel events not tracking"
- Verify `MixpanelToken` in Info.plist is correct
- Check Mixpanel dashboard for project status
- Check Xcode console for Mixpanel initialization logs

### "Build errors with Swift Packages"
- File → Packages → Reset Package Caches
- File → Packages → Update to Latest Package Versions
- Clean build folder (Cmd+Shift+K)

### "App crashes on launch"
- Check all required Info.plist keys are filled
- Verify no placeholder values remain (YOUR_TOKEN, etc.)
- Check Xcode console for fatalError messages

---

## Completion Checklist

Final verification before shipping:

- [ ] App name correct everywhere
- [ ] All API keys configured
- [ ] Bundle identifier unique and correct
- [ ] App icons replaced
- [ ] Sign in with Apple works
- [ ] Database schema created
- [ ] Analytics tracking works
- [ ] Privacy policy accessible
- [ ] Dark mode works
- [ ] Builds without warnings
- [ ] All features tested on device
- [ ] App Store Connect configured
- [ ] Screenshots captured
- [ ] Ready for App Store submission

---

**Congratulations! Your new app is ready.** 🎉

For detailed technical documentation, see [CLAUDE.md](CLAUDE.md).
