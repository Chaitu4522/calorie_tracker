# Developer Wiki - Calorie Tracker

A comprehensive guide for setting up and developing the Calorie Tracker Flutter app on Linux using VS Code.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installing Flutter on Linux](#installing-flutter-on-linux)
3. [Android SDK Setup](#android-sdk-setup)
4. [VS Code Setup](#vs-code-setup)
5. [Project Setup](#project-setup)
6. [Running the App](#running-the-app)
7. [Testing on Devices](#testing-on-devices)
8. [Building for Release](#building-for-release)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **OS**: Ubuntu 20.04+ / Fedora 33+ / Arch Linux (or similar)
- **Disk Space**: ~5 GB for Flutter SDK + Android SDK
- **RAM**: 8 GB minimum (16 GB recommended for emulator)
- **Tools**: `git`, `curl`, `unzip`, `xz-utils`

### Install Basic Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y git curl unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

**Fedora:**
```bash
sudo dnf install -y git curl unzip xz zip mesa-libGLU clang cmake ninja-build gtk3-devel
```

**Arch Linux:**
```bash
sudo pacman -S --needed git curl unzip xz zip base-devel clang cmake ninja gtk3
```

---

## Installing Flutter on Linux

### Option 1: Manual Installation (Recommended)

```bash
# Create development directory
mkdir -p ~/development
cd ~/development

# Download Flutter SDK (check https://flutter.dev for latest version)
curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz

# Extract
tar xf flutter_linux_3.24.0-stable.tar.xz

# Add to PATH (add this to ~/.bashrc or ~/.zshrc)
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter --version
```

### Option 2: Using Snap (Ubuntu)

```bash
sudo snap install flutter --classic
flutter sdk-path  # Note the path for VS Code
```

### Option 3: Using AUR (Arch Linux)

```bash
yay -S flutter
```

### Accept Licenses

```bash
flutter doctor --android-licenses
```

---

## Android SDK Setup

### Option 1: Android Studio (Easiest)

1. Download Android Studio from https://developer.android.com/studio
2. Extract and run:
   ```bash
   tar -xzf android-studio-*.tar.gz
   cd android-studio/bin
   ./studio.sh
   ```
3. Complete the setup wizard (it will download Android SDK)
4. Go to **Settings → Languages & Frameworks → Android SDK**
5. Install:
   - Android SDK Platform 34 (or latest)
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools

### Option 2: Command Line Only (Lightweight)

```bash
# Create Android SDK directory
mkdir -p ~/Android/Sdk
cd ~/Android/Sdk

# Download command-line tools
curl -LO https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true

# Add to PATH (add to ~/.bashrc)
cat >> ~/.bashrc << 'EOF'
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/emulator"
EOF
source ~/.bashrc

# Install required SDK components
sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis;x86_64"

# Accept licenses
yes | sdkmanager --licenses
```

### Configure Flutter to Use Android SDK

```bash
flutter config --android-sdk ~/Android/Sdk
```

---

## VS Code Setup

### Install VS Code

**Ubuntu/Debian:**
```bash
# Via Snap
sudo snap install code --classic

# Or via .deb package
curl -LO https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
sudo dpkg -i code_*.deb
```

**Fedora:**
```bash
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install code
```

**Arch Linux:**
```bash
yay -S visual-studio-code-bin
```

### Essential VS Code Extensions

Open VS Code and install these extensions (`Ctrl+Shift+X`):

| Extension | ID | Purpose |
|-----------|-----|---------|
| **Flutter** | `Dart-Code.flutter` | Flutter development support |
| **Dart** | `Dart-Code.dart-code` | Dart language support |
| **Error Lens** | `usernamehw.errorlens` | Inline error highlighting |
| **Pubspec Assist** | `jeroen-meijer.pubspec-assist` | Easy dependency management |
| **Flutter Widget Snippets** | `alexisvt.flutter-snippets` | Code snippets for widgets |
| **Better Comments** | `aaron-bond.better-comments` | Colored comment annotations |
| **GitLens** | `eamodio.gitlens` | Git integration |
| **Material Icon Theme** | `PKief.material-icon-theme` | File icons |

**Install via command line:**
```bash
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
code --install-extension usernamehw.errorlens
code --install-extension jeroen-meijer.pubspec-assist
code --install-extension alexisvt.flutter-snippets
code --install-extension aaron-bond.better-comments
code --install-extension eamodio.gitlens
code --install-extension PKief.material-icon-theme
```

### VS Code Settings for Flutter

Create or update `.vscode/settings.json` in the project:

```json
{
  "dart.flutterSdkPath": "~/development/flutter",
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit",
    "source.organizeImports": "explicit"
  },
  "dart.lineLength": 100,
  "[dart]": {
    "editor.rulers": [100],
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.selectionHighlight": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": "off"
  },
  "files.watcherExclude": {
    "**/.dart_tool/**": true,
    "**/build/**": true
  }
}
```

### VS Code Launch Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "calorie_tracker (debug)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug"
    },
    {
      "name": "calorie_tracker (profile)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "profile"
    },
    {
      "name": "calorie_tracker (release)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release"
    }
  ]
}
```

---

## Project Setup

### Clone/Setup Project

```bash
cd ~/projects  # or your preferred directory
# If you have the zip file:
unzip calorie_tracker.zip
cd calorie_tracker

# Remove the buggy folder if present
rm -rf "{lib"

# Get dependencies
flutter pub get
```

### Verify Setup

```bash
flutter doctor -v
```

You should see checkmarks for:
- ✓ Flutter
- ✓ Android toolchain
- ✓ Linux toolchain (for desktop, optional)
- ✓ VS Code

### Open in VS Code

```bash
code .
```

---

## Running the App

### Create Android Emulator

**Via Android Studio:**
1. Open Android Studio
2. Go to **Tools → Device Manager**
3. Click **Create Device**
4. Select a phone (e.g., Pixel 7)
5. Download and select a system image (API 34 recommended)
6. Finish and launch the emulator

**Via Command Line:**
```bash
# Create AVD (Android Virtual Device)
avdmanager create avd -n pixel7_api34 -k "system-images;android-34;google_apis;x86_64" -d "pixel_7"

# List available emulators
emulator -list-avds

# Start emulator
emulator -avd pixel7_api34
```

### Run from VS Code

1. Open the project in VS Code
2. Click on the device selector in the bottom-right status bar
3. Select your emulator or connected device
4. Press `F5` or click **Run → Start Debugging**

**Or use the command palette:**
- `Ctrl+Shift+P` → "Flutter: Select Device"
- `Ctrl+Shift+P` → "Flutter: Run Flutter App"

### Run from Terminal

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d emulator-5554  # or device ID

# Run with hot reload enabled (default)
flutter run

# Run in release mode
flutter run --release
```

### Hot Reload & Hot Restart

| Action | Shortcut | Description |
|--------|----------|-------------|
| Hot Reload | `r` in terminal / `Ctrl+S` | Preserves state, updates UI |
| Hot Restart | `R` in terminal / `Ctrl+Shift+F5` | Restarts app, loses state |
| Stop | `q` in terminal / `Shift+F5` | Stops the app |

---

## Testing on Devices

### Physical Android Device

1. **Enable Developer Options:**
   - Go to **Settings → About Phone**
   - Tap **Build Number** 7 times

2. **Enable USB Debugging:**
   - Go to **Settings → Developer Options**
   - Enable **USB Debugging**

3. **Connect via USB:**
   ```bash
   # Check if device is detected
   flutter devices
   
   # If not detected, check ADB
   adb devices
   ```

4. **Configure udev rules (if device not detected):**
   ```bash
   # Find your device's vendor ID
   lsusb
   # Look for your phone manufacturer
   
   # Add udev rule (replace XXXX with vendor ID)
   echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="XXXX", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/51-android.rules
   sudo udevadm control --reload-rules
   
   # Reconnect device
   ```

### Wireless Debugging (Android 11+)

```bash
# On phone: Enable Wireless Debugging in Developer Options
# Note the IP address and port shown

# Connect via ADB
adb pair <IP>:<PAIRING_PORT>  # Enter pairing code
adb connect <IP>:<PORT>

# Verify
flutter devices
```

---

## Building for Release

### Build APK

```bash
# Debug APK (larger, with debug info)
flutter build apk --debug

# Release APK (optimized)
flutter build apk --release

# Split APKs by ABI (smaller individual files)
flutter build apk --split-per-abi
```

Output location: `build/app/outputs/flutter-apk/`

### Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Install APK on Device

```bash
# Install directly
flutter install

# Or use ADB
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Troubleshooting

### Common Issues

**1. Flutter doctor shows issues:**
```bash
# Re-run with verbose output
flutter doctor -v

# Common fix: re-accept licenses
flutter doctor --android-licenses
```

**2. Emulator won't start (KVM issues):**
```bash
# Check if KVM is available
kvm-ok

# If not, enable virtualization in BIOS
# Or install KVM:
sudo apt install qemu-kvm libvirt-daemon-system
sudo adduser $USER kvm
# Log out and back in
```

**3. Gradle build fails:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**4. "Unable to locate Android SDK":**
```bash
flutter config --android-sdk ~/Android/Sdk
```

**5. VS Code not detecting Flutter:**
- Check that Flutter SDK path is correct in settings
- Reload VS Code: `Ctrl+Shift+P` → "Developer: Reload Window"

**6. Hot reload not working:**
- Ensure you're running in debug mode
- Check that the file you modified is imported
- Try hot restart (`R`) instead

**7. Permission denied for USB device:**
```bash
# Add yourself to plugdev group
sudo usermod -aG plugdev $USER
# Log out and back in
```

### Useful Commands

```bash
# Clean project
flutter clean

# Update dependencies
flutter pub upgrade

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Check outdated packages
flutter pub outdated

# Format code
dart format .

# Generate launcher icons (if using flutter_launcher_icons)
flutter pub run flutter_launcher_icons
```

### VS Code Shortcuts for Flutter

| Shortcut | Action |
|----------|--------|
| `Ctrl+.` | Quick fixes / code actions |
| `Ctrl+Shift+R` | Refactor menu |
| `F2` | Rename symbol |
| `Ctrl+Space` | Trigger suggestions |
| `Ctrl+Shift+O` | Go to symbol |
| `Alt+Enter` | Wrap with widget |
| `Ctrl+Shift+P` | Command palette |

---

## Dependencies Reference

This project uses the following packages:

| Package | Version | Purpose |
|---------|---------|---------|
| `sqflite` | ^2.3.0 | SQLite database |
| `path` | ^1.8.3 | File path utilities |
| `flutter_secure_storage` | ^9.0.0 | Encrypted storage for API key |
| `provider` | ^6.1.1 | State management |
| `image_picker` | ^1.0.7 | Camera/gallery access |
| `http` | ^1.2.0 | HTTP client for API calls |
| `fl_chart` | ^0.66.0 | Charts for weekly view |
| `intl` | ^0.18.1 | Date/number formatting |
| `url_launcher` | ^6.2.4 | Open URLs in browser |
| `share_plus` | ^7.2.1 | Share files (CSV export) |
| `path_provider` | ^2.1.2 | Get system directories |

---

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets)
- [Pub.dev (Package Repository)](https://pub.dev/)
- [Flutter GitHub](https://github.com/flutter/flutter)
- [Google Gemini API Docs](https://ai.google.dev/docs)

---

*Last updated: January 2025*
