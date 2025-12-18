# 📋 OrgFlow: Flutter Org-mode Todo App

Welcome! This is a powerful, Flutter-based Todo application inspired by the **Emacs Org-mode**. It helps you manage tasks hierarchically, track your time, and visualize your schedule through multiple lenses like Agenda, Timeline, and Kanban.

---

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

### 1. Hierarchical Task Management
Organize your thoughts! Create main tasks and add infinite sub-tasks.
- **Tree View**: View your tasks in a structured hierarchy.
- **Collapse/Expand**: Keep your workspace clean by nesting sub-tasks.
- **Deep Focus**: Tap any task to enter the **Task Focus** view for detailed management.

### 2. Multi-Perspective Visualization
Switch between different views to understand your workload:
- **📅 Agenda**: See today's scheduled tasks and a global list of unfinished TODOs.
- **⏳ Timeline**: A chronological view of your tasks based on scheduled dates and deadlines.
- **📋 Kanban**: Move tasks through columns based on their state (TODO, WAITING, DONE).

### 3. Rich Task Metadata
Each task can store more than just a title:
- **Descriptions**: Add detailed notes to any task.
- **Tags**: Categorize tasks with custom tags for easy filtering.
- **Status Cycling**: Quickly cycle through states like `TODO`, `WAITING`, and `DONE`.
- **Dates**: Set **Scheduled** and **Deadline** timestamps with integrated date/time pickers.

### 4. ⚙️ Typed Custom Properties
Go beyond basic text! Define global property types in the **Options** tab:
- **Text**: Standard string values.
- **Number**: Numeric values (e.g., Cost, Effort).
- **Boolean**: Yes/No toggles.
- **Options**: Select from a predefined list of values.
Once defined, these properties appear as structured inputs in the Task Detail view.

### 5. 🕒 Time Tracking & Logging
Track exactly how much time you spend on a task:
- **Clocking**: Start/stop a timer on any task to log effort.
- **Activity Log**: Every state change, time log, and comment is automatically recorded in the task's history.
- **Comments**: Add manual notes and comments to track progress.

### 6. 🌓 Modern UI & Themes
- **Material 3**: Clean, modern interface using the latest Flutter design standards.
- **Dark Mode**: Fully supports system dark/light modes.
- **Custom Fonts**: Uses Google Fonts (Inter) for excellent readability.

---

## 🧪 Running Tests
To ensure the logic is working correctly:
```bash
flutter test
```

Enjoy your productivity journey with Flutter and OrgFlow!

