# 📱 Link Manager: Screen-by-Screen Guide
### *A Visual & Functional Breakdown of the Premium Experience*

---

## 🚀 1. Splash Screen
*The "Welcome" Experience*

- **Visuals**: Features a premium high-quality Lottie vector animation (`success.json` style).
- **Functionality**: 
  - Performs initial **Core Data stack initialization** in the background.
  - Automatically transitions to the Home Dashboard after a 2-second fluid delay.
  - Ensures a standard, branded entry point every time the app launches.

---

## 🏠 2. Home Dashboard (Latest Links)
*The Command Center*

- **Primary View**: A clean, vertical list of your most recently saved digital assets.
- **Key Features**:
  - **Smart Search**: Real-time filtering across titles, URLs, and descriptions.
  - **Category Bar**: A horizontal scrolling strip of auto-generated categories (extracted from the root domains of your links).
  - **Link Cards**: Interactive cards showing favicons, high-res thumbnails, and quick-action hearts.
  - **Pull-to-Refresh**: Triggers a manual sync with the `MetadataService` to update older links.

---

## 📂 3. Groups & Collections
*The Organization Hub*

- **Layout**: A responsive dynamic grid showcasing your custom folders.
- **Functionality**:
  - **Folder Management**: Create, rename, or delete specialized collections (e.g., "Personal", "Work", "Recipe Research").
  - **Link Counters**: Each folder displays the exact count of links contained within.
  - **Quick Entry**: Tapping a folder opens the **Group Detail View**, showing only the links assigned to that specific collection.

---

## ❤️ 4. Favorites Hub
*Your Priority Content*

- **Focus**: A dedicated tab for the items you use most.
- **Interactions**:
  - **Instant Removal**: Click the heart again to move it back to the general list.
  - **Filtered Search**: Search specifically within your favorite items.
  - **Zero-State**: Beautifully designed "No Favorites" state with a call-to-action to start hearting links.

---

## 🔍 5. Immersive Link Detail View
*The Deep Dive*

- **Visuals**: Features a **Dynamic Blurred Header** that uses the link's thumbnail as a background, creating an immersive "glassmorphism" effect.
- **Actions Area**:
  - **Open Browser**: High-visibility blue button to launch the link in Safari.
  - **Edit Mode**: Change the title or add a custom description manually.
  - **Native Share**: Trigger the iOS Share Sheet to send the link to friends or other apps.
  - **Delete**: Safely remove the link with a confirmation alert.

---

## ➕ 6. Add Link Modal
*The Input Gateway*

- **Intelligence**:
  - **Auto-Paste**: Detects if a URL is currently in your clipboard and offers one-tap insertion.
  - **Text Parsing**: Accepts entire paragraphs of text; the app will scan and extract all valid URLs automatically.
  - **Selection UI**: If multiple URLs are detected in your text, a specialized selection sheet appears so you can choose which ones to save.
  - **Immediate Enrichment**: Once "Add" is tapped, metadata fetching starts instantly in the background.

---

## 📲 7. iOS Share Extension
*The "Outside-the-App" Power*

- **Availability**: Accessible from Safari, Chrome, YouTube, and any app with a "Share" icon.
- **Process**:
  - **Background Persistence**: Saves data directly to the App Group SQLite store without needing to open the main app.
  - **Visual Feedback**: Shows a "Success" or "Failed" Lottie animation overlaying the host app to confirm the save.
  - **Sync**: The next time you open Link Manager, your shared links will be waiting, already enriched with metadata.

---
<p align="center">
  <i>Link Manager: Designed for Professional Clarity.</i>
</p>
