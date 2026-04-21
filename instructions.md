# Installing sarAPP on iPhone (free Apple ID)

End-to-end setup for running sarAPP on a physical iPhone with no paid Apple Developer account.

## One-time Mac setup

You need **Xcode** (full Mac App Store install — Command Line Tools alone is not enough), **Flutter**, and **CocoaPods**.

```bash
# Flutter SDK
brew install --cask flutter

# CocoaPods (for iOS native dependencies)
brew install cocoapods
```

Install **Xcode** from the Mac App Store (~15 GB). Then open Xcode once and go to **Settings → Platforms** → install the **iOS** platform if it isn't already.

After Xcode is installed, switch `xcode-select` to it and accept the license:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept
```

Sign into Xcode with your Apple ID: **Xcode → Settings → Accounts → +**.

## One-time iPhone setup

1. **Enable Developer Mode**: Settings → Privacy & Security → Developer Mode → On (phone restarts).
2. Make sure the phone has a passcode (free signing requires one).
3. Plug the phone into the Mac with USB. Tap **Trust** on the phone and enter the passcode.
4. In Xcode: **Window → Devices and Simulators** — wait until the phone shows under **Connected** with no errors.

## Clone and prepare the project

```bash
git clone https://github.com/camillefournierdl/sarAPP.git
cd sarAPP/sarAPP/sarapp
flutter pub get
```

Optional — regenerate launcher icons from `assets/icon/`:

```bash
dart run flutter_launcher_icons
```

## Configure signing (Xcode, one time per Mac)

Open the workspace (**not** the `.xcodeproj`):

```bash
open ios/Runner.xcworkspace
```

In Xcode:

1. Click **Runner** at the top of the left sidebar.
2. In the middle pane, under **TARGETS**, select **Runner** → **Signing & Capabilities** tab.
3. Check **Automatically manage signing**.
4. **Team** → your **Personal Team** (your Apple ID).
5. **Bundle Identifier** → change `com.example.sarapp` to something unique, e.g. `com.yourname.sarapp`. Apple rejects duplicates.

## Run on the iPhone

With the phone plugged in and unlocked:

```bash
flutter run --release -d <device-id>
```

Find `<device-id>` with `flutter devices`. Or just:

```bash
flutter run --release
```

…and pick the iPhone from the prompt.

First build takes 2–5 minutes. After it installs, you can press `q` to quit `flutter run` — the app stays on the phone and launches from the home-screen icon.

The first launch after install shows **"Untrusted Developer"**. Fix it once: on the iPhone → **Settings → General → VPN & Device Management** → tap your Apple ID profile → **Trust**.

## Re-signing every 7 days

Free Apple ID provisioning expires after 7 days. The app stays installed but refuses to launch. To renew, plug the phone in and run the same command:

```bash
cd sarAPP/sarAPP/sarapp
flutter run --release
```

Press `q` once it's installed.

## Troubleshooting

- **"Could not build the precompiled application for the device"** with missing `.xcconfig` files → you're on an old clone from before the scaffolding fix. `git pull origin main` and retry.
- **"MissingPluginException" on sqflite** at startup → `flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run --release`.
- **iPhone not showing in `flutter devices`** → run `flutter doctor`; open Xcode's Devices window and finish any pending pairing prompt on the phone.
- **"iOS settings must be set when targeting iOS platform"** → you're on an old commit from before the notification-init fix. Pull latest.
