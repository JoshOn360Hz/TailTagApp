# TailTag

A modern iOS app for aircraft enthusiasts to log and track their aircraft sightings.

## Overview

TailTag is a native iOS application built with SwiftUI that allows aviation enthusiasts to document their aircraft spotting experiences. Capture photos, record aircraft details, and build your personal spotting logbook with an intuitive and beautiful interface.

## Features

### Core Functionality
- **Photo Capture**: Take or select photos of aircraft from your device
- **Detailed Logging**: Record aircraft registration, airline, location, aircraft type, and personal notes
- **Recent Activity**: View your latest aircraft sightings in chronological order
- **Search & Filter**: Quickly find specific entries in your spotting history
- **Persistent Storage**: All your data is securely stored locally on your device

### Customization
- **App Icons**: Choose from multiple app icon variants to personalize your experience
- **Accent Colors**: Customize the app's accent color to match your preferences
- **Dark Mode Support**: Full support for light and dark appearance modes
- **Flexible Theming**: Automatic system appearance detection with manual override options

## Technology Stack

- **Framework**: SwiftUI
- **Platform**: iOS
- **Language**: Swift
- **Architecture**: MVVM with ObservableObject pattern
- **Data Persistence**: Local storage with Codable models
- **Photo Management**: PhotosUI integration

## Project Structure

```
TailTag/
├── Models/
│   ├── SpottingEntry.swift      # Core data model for aircraft sightings
│   ├── SpottingStore.swift      # Data management and persistence
│   ├── AppSettings.swift        # User preferences and app configuration
│   └── DateFormatter+Extensions.swift
├── Views/
│   ├── Recents/                 # Recent sightings interface
│   ├── Search/                  # Search and filtering functionality
│   ├── Settings/                # App configuration and customization
│   └── Spotting/                # Add, edit, and view spotting entries
└── Assets/                      # App icons, colors, and visual assets
```

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+



## Usage

### Adding a New Spotting
1. Navigate to the "Recent" tab
2. Tap the add button to create a new entry
3. Select or capture a photo of the aircraft
4. Fill in the required details:
   - Aircraft registration (tail number)
   - Airline name
   - Location where spotted
5. Optionally add aircraft type and personal notes
6. Save your entry

### Viewing Your Collection
- Browse recent sightings in the "Recent" tab
- Use the "Search" tab to filter and find specific entries
- Tap any entry to view detailed information

### Customizing the App
- Access the "Settings" tab for personalization options
- Choose your preferred app icon from the available variants
- Select an accent color that suits your style
- Toggle between light, dark, or automatic appearance modes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## Development

This project follows standard iOS development practices:
- **Architecture**: MVVM pattern with SwiftUI
- **State Management**: `@StateObject` and `@EnvironmentObject` for data flow
- **Data Models**: Codable structs for easy serialization
- **UI Components**: Reusable SwiftUI views and modifiers



## Support

If you encounter any issues or have questions about TailTag, please open an issue in this repository.

---

**Happy Spotting!** 
