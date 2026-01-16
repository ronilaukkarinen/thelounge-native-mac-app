# The Lounge - Native macOS app

[![Built with Swift](https://img.shields.io/badge/Built_with-Swift-orange?style=for-the-badge)](https://swift.org)
[![macOS Tahoe](https://img.shields.io/badge/macOS-Tahoe_26+-blue?style=for-the-badge)](https://www.apple.com/macos/)
[![forthebadge](https://forthebadge.com/images/badges/works-on-my-machine.svg)](https://forthebadge.com)

A native macOS wrapper for [The Lounge](https://thelounge.chat/) IRC client with native notifications, customizable appearance, and full macOS integration.

Looking for Linux? Check out [thelounge-native-linux-app](https://github.com/ronilaukkarinen/thelounge-native-linux-app).

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 16 or later (for building)
- A running instance of The Lounge web client

## Features

### Native notifications

- Bridges web Push API to native macOS notifications
- Configurable notification sounds
- Works even when the app is in the background

### Customizable titlebar

- Set any color for the window titlebar via Settings (Cmd+,)
- Persists across app restarts

### Other features

- Zoom controls (Cmd+/-, Cmd+0)
- External links open in default browser
- Spell check disabled in input fields
- Full dark mode support
- Works correctly as a login item

## Building

### Prerequisites

1. Install Xcode from the Mac App Store
2. Run `xcode-select --install` in Terminal

### Build steps

```bash
git clone https://github.com/ronilaukkarinen/thelounge-native-mac-app.git
cd thelounge-native-mac-app
xcodebuild -scheme TheLoungeApp -configuration Release -derivedDataPath build build
cp -R "build/Build/Products/Release/The Lounge.app" /Applications/
```

## Configuration

### Changing the server URL

Edit `TheLoungeApp/ContentView.swift` and change the URL:

```swift
WebView(url: URL(string: "https://your-lounge-instance.com")!)
```

Then rebuild the app.

### Settings

Open Settings with Cmd+, to configure:

- Titlebar color
- Notification preferences
- Test notifications
