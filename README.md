# 🔗 Link Manager

<p align="center">
  <img src="https://raw.githubusercontent.com/lottie-react-native/lottie-react-native/master/docs/lottie-logo-light.png" width="80" alt="Lottie Logo" />
</p>

**Link Manager** is a premium, high-performance iOS application built with **SwiftUI** and **Core Data**. It is a sophisticated suite designed to capture, organize, and manage your digital life with an focus on high-performance and premium aesthetics.

---

## 🏎️ App Architecture & Flow

To understand how Link Manager works, here is the high-level user journey and data flow:

```mermaid
graph TD
    A[Launch App] --> B{Splash Screen}
    B -->|2s Delay| C[Home Dashboard]
    
    subgraph "Core Navigation (HomeView)"
        C --> D[Home Tab: Latest Links]
        C --> E[Groups Tab: Folders]
        C --> F[Favorites Tab: Highlighted]
    end

    subgraph "Adding Content"
        G[Safari / External App] -->|iOS Share Sheet| H[Share Extension]
        H -->|App Group Persist| I[Core Data Store]
        D -->|FAB + Button| J[Add Link Modal]
        J -->|Manual Entry| I
    end

    subgraph "Link Interaction (LinkCardView)"
        D -->|Single Tap| K[Link Detail View]
        D -->|Heart Click| L[Toggle Favorite]
        D -->|Action Swipe| M[Share/Delete/Group]
        D -->|Long Press| N[Selection Mode]
    end

    subgraph "Deep Management"
        K -->|Safari Icon| O[Open in Browser]
        K -->|Pencil Icon| P[Edit Metadata]
        E -->|Folder Tap| Q[Group Detail View]
        N -->|Multi-Select| R[Batch Delete/Bulk Group]
    end

    I -->|@FetchRequest| D
    I -->|@FetchRequest| E
    I -->|@FetchRequest| F
```

---

## ✨ Features Breakdown

### 🗂️ Smart Organization & Groups
- **The Flow**: From the **Groups Tab**, tap any folder to enter a specialized view. Use the **Selection Mode** (Checkmark icon) on the Home dashboard to select multiple links and "File" them into these groups instantly.
- **Dynamic Grid Layouts**: Visually browse your collections with responsive designs that adapt to your device orientation.

### 🌐 Intelligent Metadata Retrieval
- **The Flow**: Simply paste a URL in the **Add Link Modal** or use the **Share Extension**. Our `MetadataService` immediately triggers an asynchronous fetch to pull the title, description, and high-res icon, ensuring your library stays beautiful without manual typing.
- **Favicon Extraction**: Uses Google's favicon API and native providers to ensure every link looks distinct from the moment it's added.

### ❤️ Favorites & Quick Actions
- **The Flow**: See a link you love? Click the **Heart Icon** on any card. It instantly appears in the synchronized **Favorites Tab**. 
- **Native Sharing**: Every component (Card or Detail) features a one-tap **Share Button** to export your links back to the world.

### 🚀 Seamless Share Extension
- **The Flow**: You don't even need to open Link Manager. While browsing in Safari, hit **Share** -> **Link Manager**. The extension captures the URL and saves it to the **Core Data App Group**, making it available the next time you open the main app.

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
    git clone https://github.com/HirenTechie/Link-Manager.git
    ```
2.  **Open in Xcode**: Open `Link Manager.xcodeproj`.
3.  **App Groups Setup**: Ensure your App Group ID matches in `Persistence.swift` to enable Share Extension sync.
4.  **Build & Run**: Press `Cmd + R`.

---

<p align="center">
  <i>Stay Organized. Stay Productive. Stay Ahead.</i>
</p>
