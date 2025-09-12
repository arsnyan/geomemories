# GeoMemories
**GeoMemories** is a personal map-based diary that allows users to capture and organize their memories by marking significant locations (points of interest or "memories" (or "entries" in code)) on a map. Each memory can be enriched with textual descriptions, photos and video recordings.

[![Swift Version](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Xcode Version](https://img.shields.io/badge/Xcode-26%20beta-blue)](https://developer.apple.com/xcode/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0%2B-lightgrey.svg)](https://developer.apple.com/ios/)
[![SwiftLint](https://img.shields.io/badge/SwiftLint-enabled-brightgreen.svg)](https://github.com/realm/SwiftLint)

| iOS 26.0+ Demo (It can take some time to load the demonstration) (Загрузка демонстрационного видео может занять какое-то время) |
| :---------: |
![App GIF for iOS 26.0](https://github.com/arsnyan/geomemories/blob/main/Demonstration%20iOS%2026.gif) |

## Table of Contents
2.  [Features](#features)
3.  [Technical Stack & Architecture](#technical-stack--architecture)
4.  [Screenshots](#screenshots)
5.  [Setup and Run](#setup-and-run)
7.  [Git Flow](#git-flow)
9.  [Author](#author)

---

## <a name="features"></a>1. Features

*   **Interactive Map:** View your current location and all your saved memories on a dynamic map
*   **Memory Creation:** Add new memories with a specific location, title, and description
*   **Photo & Video Capture:** Capture photos directly within the app or select from the photo library
*   **Local Data Persistence:** All memory details, including associated photos and videos, are stored on your device
*   **Detailed Memory View:** Explore individual memories with all their media content
*   **User Location Tracking:** Displays the user's current position on the map (with appropriate permissions)

## <a name="technical-stack--architecture"></a>2. Technical Stack & Architecture

*   **UI Framework:** UIKit
*   **Architecture:**
    *   **Clean Swift (VIP Cycle):** Some major modules (e.g., Home, CreateEditEntry, SearchLocation sub-module) are structured around the View, Interactor, Presenter pattern, promoting strict separation of concerns, testability, and maintainability
    *   **MVC**: Used for easier, static views without a state
*   **Reactive Framework:** **Combine** is extensively used to:
    *   Handle asynchronous operations, such as saving data to Core Data (via CoreStore) or interacting with `AVKit`.
*   **Local Data Persistence:** **Core Data** is utilized for local storage of `Entry` entities
*   **Location Services:** **MapKit** for displaying maps and custom annotations, and `CLLocationManager` for precise location tracking.
*   **Media & Graphics:** AVKit is used for playing videos in entry details view
*   **Code Quality:** **SwiftLint** is integrated and strictly adhered to ensure consistent code style

## <a name="screenshots"></a>3. Screenshots

| Home Screen | Create/Edit Memory | Memory Details |
| :---------: | :----------------: | :------------: |
| ![](/Screenshots/HomeScreen.png) | ![](/Screenshots/EditScreen.png) | ![](/Screenshots/DetailsScreen.png) |

## <a name="setup-and-run"></a>4. Setup and Run

To set up and run GeoMemories on your local machine:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/arsnyan/geomemories.git
    cd GeoMemories
    ```
2.  **Install SwiftLint (if you don't have it):**
    ```bash
    brew install swiftlint
    ```
3.  **Open in Xcode:**
    ```bash
    open GeoMemories.xcodeproj
    ```
4.  **Select a Simulator or Device:** Choose an iOS Simulator (e.g., iPhone 15 Pro) or a physical device.
5.  **Build and Run:** Press `Cmd + R` or click the Run button in Xcode.

*Note: The first launch might prompt for Location and Camera permissions when using location pin buttons. Please grant them for full functionality.*

## <a name="git-flow"></a>5. Git Flow

This project follows the **Git Flow** branching model to manage development and ensure a structured workflow:

*   **`main` branch:** Represents the stable production release
*   **`develop` branch:** Integrates all completed features and serves as the primary development branch
*   **`feature/*` branches:** New features are developed in dedicated branches, branching off `develop` and merging back into `develop` upon completion

Regular commits and Pull Requests (PRs) were made, following the principles of Git Flow for clean version control and collaboration.

## <a name="author"></a>6. Author

**Arsen** - [Link to my LinkedIn Profile](https://www.linkedin.com/in/arsnyan/) | [E-mail](mailto:arsnyan.dev@gmail.com) | [Telegram](https://www.t.me/arsnyan)

---
