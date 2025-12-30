# iOS Widget Setup Instructions

The Flutter code and Swift widget files have been created. You need to complete the Xcode setup manually (one-time setup).

## Quick Setup in Xcode (5 minutes)

### Step 1: Open Xcode Project

```bash
cd /Users/brett/Desktop/PepCursor/pep-io/ios
open Runner.xcworkspace
```

### Step 2: Add Widget Extension Target

1. In Xcode, click **File → New → Target**
2. Search for **"Widget Extension"**
3. Click **Next**
4. Configure:
   - **Product Name:** `PepIOWidget`
   - **Team:** Select your team
   - **Bundle Identifier:** `com.pepio.app.PepIOWidget` (should auto-fill)
   - **Include Live Activity:** ❌ Uncheck
   - **Include Configuration App Intent:** ✅ Check
5. Click **Finish**
6. If asked "Activate scheme?", click **Activate**

### Step 3: Replace Generated Files

Xcode created placeholder widget files. Replace them with our custom ones:

1. In Xcode's Project Navigator, find the **PepIOWidget** folder
2. **Delete** all the auto-generated `.swift` files (select and press Delete, choose "Move to Trash")
3. Right-click on **PepIOWidget** folder → **Add Files to "Runner"**
4. Navigate to `ios/PepIOWidget/` and add:
   - `PepIOWidget.swift`
   - `PepIOWidgetBundle.swift`
5. Make sure **"Copy items if needed"** is ❌ **unchecked**
6. Make sure **Target Membership** shows `PepIOWidget` ✅ checked

### Step 4: Configure App Groups

Both the main app and widget need to share data via App Groups.

**For the Runner (main app):**
1. Select **Runner** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click the **+** under App Groups
6. Add: `group.com.pepio.app`

**For the Widget:**
1. Select **PepIOWidgetExtension** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Add the same group: `group.com.pepio.app`

### Step 5: Set Deployment Target

1. Select **PepIOWidgetExtension** target
2. Go to **General** tab
3. Set **Minimum Deployments → iOS** to `17.0`

### Step 6: Build & Run

1. Select your simulator from the device dropdown
2. Press **Cmd + R** to build and run
3. The app should launch with widget support!

## Testing the Widget

1. Run the app in simulator
2. Create or view a protocol (this updates widget data)
3. Go to simulator home screen
4. Long-press → tap **+** → search "pep.io"
5. Add the widget!

## Troubleshooting

### "No such module 'WidgetKit'"
- Make sure the widget target's deployment target is iOS 14.0+

### Widget shows placeholder data
- Open the app first to populate data
- Pull-to-refresh on home screen

### App Group error
- Verify both targets have the same App Group ID
- The ID must exactly match: `group.com.pepio.app`

### Widget not appearing in picker
- Clean build folder: **Product → Clean Build Folder**
- Delete app from simulator and rebuild

## Files Created

```
ios/
├── PepIOWidget/
│   ├── PepIOWidget.swift          # Main widget code
│   ├── PepIOWidgetBundle.swift    # Widget bundle entry point
│   ├── Info.plist                 # Widget configuration
│   ├── PepIOWidget.entitlements   # App Groups entitlement
│   └── Assets.xcassets/           # Widget assets
├── Runner/
│   └── Runner.entitlements        # Main app entitlements
```

```
lib/
└── core/
    └── services/
        └── widget_service.dart    # Flutter widget service
```

