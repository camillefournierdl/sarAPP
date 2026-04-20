# iOS Installation Guide (No Developer Account)

## Prerequisites

- A Mac with **Xcode** installed (free, from the App Store)
- **Flutter SDK** installed on the Mac (see flutter.dev)
- A free **Apple ID** signed into Xcode (Xcode → Settings → Accounts)
- An iPhone connected via USB

## First-time setup

1. Copy the project onto the Mac
2. In the `sarapp/` directory, run:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```
3. Open `ios/Runner.xcworkspace` in Xcode (**not** `Runner.xcodeproj`)
4. Click **Runner** in the left sidebar → **Signing & Capabilities**
   - Set **Team** to your personal Apple ID
   - Set **Bundle Identifier** to something unique, e.g. `com.yourname.sarapp`
5. Plug in the iPhone — tap **Trust** on the phone when prompted
6. Select the iPhone in the device dropdown at the top of Xcode
7. Hit **Run (▶)** — Xcode builds and installs the app (~2–5 min first time)

## Re-signing every 7 days

Free provisioning profiles expire after 7 days. To renew:

1. Plug in the iPhone
2. Open `ios/Runner.xcworkspace`
3. Hit **Run (▶)**

## Notes

- This only works for devices you physically connect to the Mac
- To share with other people, a paid Apple Developer account ($99/year) + TestFlight is required
- Always open `.xcworkspace`, never `.xcodeproj`
