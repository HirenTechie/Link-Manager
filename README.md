# 🔗 Link Manager

<p align="center">
  <img src="https://raw.githubusercontent.com/lottie-react-native/lottie-react-native/master/docs/lottie-logo-light.png" width="80" alt="Lottie Logo" />
</p>

**Link Manager** is a premium, high-performance iOS application built with **SwiftUI** and **Core Data**. It is a sophisticated suite designed to capture, organize, and manage your digital life with an focus on high-performance and premium aesthetics.

---

## ✨ Features

### 🗂️ Smart Organization & Groups
- **Custom Collections**: Create and manage folders (Groups) for specialized interests.
- **Dynamic Grid Layouts**: Visually browse your collections with responsive designs.
- **Batch Operations**: Move or delete multiple links at once using the intuitive Selection Mode.

### 🌐 Intelligent Metadata Retrieval
- **LPMetadataProvider Integration**: Automatically fetches high-resolution thumbnails, titles, and site descriptions.
- **Smart Categorization**: The app extracts the primary domain to suggest categories automatically.
- **Favicon Extraction**: Uses Google's favicon API and native providers to ensure every link looks distinct.

### ❤️ Favorites & Quick Actions
- **Instant Favoriting**: Heart links with a single tap from the card or detail view.
- **Dedicated Hub**: A clean space for your most accessed content.
- **Native Sharing**: Share any saved link through the iOS system sheet with one tap.

### 🚀 Seamless Share Extension
Save links from Safari, YouTube, or Twitter without opening the app. Our extension handles background persistence and metadata queuing.

---

## 📂 Internal Architecture & File Responsibilities

### 🖥️ View Layer (SwiftUI)
- **`HomeView.swift`**: The main orchestrator. Manages tab transitions, search filtering, and the floating action button.
- **`LinkDetailView.swift`**: Provides an immersive, blurred-header detail screen for focused reading and link management.
- **`GroupListView.swift`**: Implements folder-based organization with grid-item previews and batch assignment.
- **`AddLinkView.swift`**: A streamlined sheet for manual entry, featuring real-time URL validation.
- **`ShimmerView.swift`**: Provides elegant "skeleton" loading states for a tactile, responsive feel.

### 🧠 Logic & Data (ViewModels & Services)
- **`LinkViewModel.swift`**: The brain. Handles background metadata fetching, duplicate sanitization, and complex filtering logic.
- **`MetadataService.swift`**: A specialized service leveraging Apple's `LinkPresentation` framework for robust enrichment.
- **`Persistence.swift`**: Manages the `NSPersistentCloudKitContainer`. Crucially utilizes **App Groups** to sync data between the main app and the Share Extension.

### 🎨 Animations & Shared Components
- **`LottieView.swift`**: Integrates Airbnb's Lottie for stunning vector animations (Success, Loading).
- **`AnimationManager.swift`**: Centralizes visual feedback logic for consistent UX across the app.

---

## 🛠️ Technical Specifications

- **Language**: Swift 5.10
- **Architecture**: MVVM (Model-View-ViewModel)
- **Database**: Core Data (Local-first, App Group shared)
- **UI Architecture**: Combine-driven state management + SwiftUI 
- **Minimum iOS**: iOS 16.0+

---

## 🚀 Installation

1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/yourusername/link-manager.git
    ```
2.  **Open in Xcode**: Open `Link Manager.xcodeproj`.
3.  **App Groups Setup**: Ensure your App Group ID matches in `Persistence.swift` to enable Share Extension sync.
4.  **Build & Run**: Press `Cmd + R`.

---

<p align="center">
  <i>Stay Organized. Stay Productive. Stay Ahead.</i>
</p>
