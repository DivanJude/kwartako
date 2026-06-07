# KwartaKo 🪙

KwartaKo is a modern, privacy-first, 100% offline personal finance manager and budget builder with an integrated **local AI Coach** running directly on your device. Keep track of your allowance, manage want-vs-need spendings, track debts, and receive automated financial coaching reflections without any cloud API fees or data leaks.

---

## Key Features 🚀

- **Weekly Budget Allowance Resets**: Active expense limits and allowances reset automatically every Sunday midnight, preserving your past spending records inside your long-term history without affecting your new week's allowance budget.
- **Offline Local AI Coach**: Dynamic financial suggestions and weekly summaries powered by a 4-bit quantized **Qwen-2-0.5B-Instruct** model running in a background isolate thread (`LlamaEngine`). Zero cloud API calls, zero server bills, and absolute privacy.
- **Interactive Money Discipline Score**: Dynamically calculated score analyzing your wants-vs-needs ratio, savings rate, and category budget caps.
- **Saturday Reflections**: Spline-based spending trend graph drawn natively via `CustomPainter`, along with category breakdowns, coach advice, and quotes.
- **Debt & Loan Ledger**: Detailed partial payment timelines with progress indicators and full-payment lock mechanics.
- **SQLite Database Architecture**: Local relational database using `sqflite` for fast, offline, and persistent storage.

---

## Installation & Download Guide 📲

Since KwartaKo runs 100% locally, we distribute pre-compiled installation packages (`.apk` and `.ipa`) directly via GitHub Releases.

### 🤖 Android (Free & Simple)
1. Go to the **Releases** tab of this GitHub repository and download the latest `kwartako-android-apk` (`app-release.apk`).
2. Open the downloaded `.apk` file on your device.
3. If prompted, allow your web browser or file manager to **Install Apps from Unknown Sources**.
4. Tap **Install** and launch KwartaKo!

---

### 🍏 iOS (Free & Private - Bypassing 7-Day Expirations via AltStore)
Because Apple restricts app installations outside the App Store, you will need a free Apple ID to sign and install the app. We recommend using **AltStore** to automate resigning the app over Wi-Fi so that you bypass the 7-day free developer account limit.

#### Prerequisites
- An iPhone or iPad.
- A computer (Windows or macOS) connected to the same Wi-Fi network as your phone.
- A USB cable for the initial setup.

#### Step 1: Install AltStore on your Phone
1. Download and install **AltServer** on your computer:
   - [AltStore Official Website](https://altstore.io/)
2. Open AltServer on your computer.
   - *On Windows:* Install the non-Microsoft Store versions of **iTunes** and **iCloud** (links are available on the AltStore site).
3. Connect your iPhone to your computer via USB, open iTunes/iCloud, and trust the computer.
4. Enable **Wi-Fi Sync** for your phone in iTunes.
5. Click the AltServer icon in the system tray, select **Install AltStore**, and choose your iPhone.
6. Enter your Apple ID and password (sent securely to Apple to register a free developer provisioning profile).
7. Once installed, go to `Settings > General > VPN & Device Management` on your iPhone and trust your Apple ID certificate.
8. Enable **Developer Mode** on your iPhone (found in `Settings > Privacy & Security > Developer Mode` on iOS 16+), then restart your phone.

#### Step 2: Sideload KwartaKo
1. Go to the **Releases** tab of this GitHub repository on your iPhone and download the latest `kwartako-ios-ipa` (`app-release.ipa`).
2. Open the **AltStore** app on your iPhone.
3. Navigate to the **My Apps** tab and tap the **`+`** icon in the top-left corner.
4. Select the downloaded `app-release.ipa` file.
5. AltStore will sign and install KwartaKo. You will see it listed under your active apps!

#### Step 3: Bypassing the 7-Day Limit (No Action Needed)
Apple free developer certificates expire every 7 days, which would normally stop the app from opening. **AltStore bypasses this automatically:**
- Keep AltServer running on your PC in the background.
- As long as your phone and PC are on the same Wi-Fi network once every 7 days, AltStore will automatically renew your certificates in the background.
- You can also manually tap **Refresh All** inside the AltStore app at any time when connected to the same Wi-Fi.

---

## Local Development & Compilation 🛠️

To build or run this project locally, ensure you have the Flutter SDK installed.

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/Kwartako.git
   cd Kwartako
   ```
2. **Fetch packages**:
   ```bash
   flutter pub get
   ```
3. **Run the project**:
   ```bash
   flutter run
   ```
4. **Compile release bundles locally**:
   - **Android**: `flutter build apk --release`
   - **iOS (Xcode needed)**: `flutter build ios --release --no-codesign`
