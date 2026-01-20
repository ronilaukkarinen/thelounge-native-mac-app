<h1 align="center">
	<img
		width="300"
		alt="The Lounge"
		src="https://raw.githubusercontent.com/thelounge/thelounge/master/client/img/logo-vertical-transparent-bg.svg?sanitize=true">
</h1>

<h3 align="center">
	The Lounge - Native macOS app (unofficial)
</h3>
<div align="center">
	<img src="https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white">
</div>

<img width="1441" height="1142" alt="image" src="https://github.com/user-attachments/assets/1be08f10-97af-4183-978b-fdaeee69a998" />

## Overview

A native macOS wrapper for [The Lounge](https://thelounge.chat/) IRC client with native notifications, customizable appearance, and full macOS integration. Looking for Linux version? Check out [thelounge-native-linux-app](https://github.com/ronilaukkarinen/thelounge-native-linux-app).

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
