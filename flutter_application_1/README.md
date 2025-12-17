# Flutter Org-mode Todo App

Welcome! This is a Flutter-based Todo application inspired by the powerful **Emacs Org-mode**. It's designed to help you manage tasks hierarchically, track your time, and view your schedule in an agenda format.

## 🚀 Getting Started

If you are new to Flutter, follow these steps to get the app running on your machine.

### Prerequisites
1.  **Install Flutter**: Follow the [Official Flutter Install Guide](https://docs.flutter.dev/get-started/install).
2.  **Verify Setup**: Run `flutter doctor` in your terminal to ensure everything is configured correctly.

### 🏃 How to Run (Development Mode)
To see the app in action while you develop:
1.  Connect a device (or start an emulator/simulator).
2.  Open your terminal in the project folder.
3.  Run:
    ```bash
    flutter run
    ```
    *   **Tip**: Press `r` in the terminal for "Hot Reload" to see changes instantly without restarting!

---

## 🛠️ How to Build (Production)

When you're ready to share your app, you need to "build" it for specific platforms.

### 🪟 Windows (Desktop)
```bash
flutter build windows
```
The executable will be located in `build\windows\x64\runner\Release`.

### 🌐 Web
```bash
flutter build web
```
The files in `build\web` can be hosted on any web server (like GitHub Pages or Netlify).

### 🤖 Android
```bash
flutter build apk
```
The installer (.apk) will be in `build\app\outputs\flutter-apk\app-release.apk`.

### 🍎 iOS / macOS
*Note: Requires a Mac with Xcode installed.*
```bash
# For iOS
flutter build ios
# For macOS
flutter build macos
```

---

## ✨ Features

### 1. Hierarchical Tree View
Organize your thoughts! Create a main task and add infinite sub-tasks.
- **Add Task**: Click the `+` button.
- **Add Sub-task**: Click the `+` icon on any existing task.
- **Collapse/Expand**: Click the arrow next to a task to hide/show its children.

### 2. Custom Todo States
Tap the state badge (e.g., `TODO`) to cycle through:
- 🔴 **TODO**: Work to be done.
- 🟠 **WAITING**: Blocked or waiting on someone else.
- 🟢 **DONE**: Completed!

### 3. Agenda View
Switch to the **Agenda** tab at the bottom to see:
- **Today's Tasks**: Anything scheduled for today.
- **Global TODOs**: A bird's-eye view of all unfinished tasks.

### 4. Time Tracking (Clocking)
Track exactly how much time you spend on a task:
- Tap the **Clock icon** 🕒 to start tracking.
- Tap it again (turns grey) to stop.
- Total time is displayed right below the task.

---

## 🧪 Running Tests
To ensure the logic is working correctly:
```bash
flutter test
```

Enjoy your productivity journey with Flutter and Org-mode!
