# JSON Editor

A lightweight, native macOS JSON editor built with SwiftUI.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![License](https://img.shields.io/badge/license-MIT-green)

<p align="center">
  <img src=“docs/screenshots/lightmode.png" width="800" alt="JSON Editor in Light Mode">
</p>

## Features

- **Tree View Navigation** — Collapsible sidebar displays your JSON structure at a glance
- **Syntax Highlighting** — Color-coded keys, strings, numbers, booleans, and nulls
- **Real-time Validation** — Instant feedback as you type with valid/invalid status
- **Cursor Sync** — Tree view highlights the node at your cursor position in the editor
- **Click to Navigate** — Click any node in the tree to jump to it in the editor
- **Format & Minify** — Toggle between pretty-printed and compact JSON
- **Dark Mode** — Full support for light and dark appearances
- **Drag & Drop** — Drop JSON files directly into the window
- **Native macOS** — Proxy icons, document editing state, keyboard shortcuts

## Installation

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later

### Build from Source

```bash
git clone https://github.com/yourusername/json-editor.git
cd json-editor
open JSONEditor.xcodeproj
```

Build and run with `⌘R` in Xcode.

## Usage

| Action | Shortcut |
|--------|----------|
| New File | `⌘N` |
| Open File | `⌘O` |
| Save | `⌘S` |
| Toggle Dark Mode | Toolbar button |

### Tree View

The left panel shows your JSON as a navigable tree:

- **Click** a node to jump to its location in the editor
- **Filter** nodes using the search bar
- **Expand/collapse** objects and arrays with disclosure triangles

### Editor

The right panel is a full-featured text editor:

- Syntax highlighting updates as you type
- Cursor position syncs with the tree view
- Validation indicator shows JSON status in real-time

## Project Structure

```
JSONEditor/
├── JSONEditorApp.swift           # App entry point
├── Models/
│   ├── AppearanceMode.swift      # Light/dark mode handling
│   ├── JSONNode.swift            # Tree node model
│   └── JSONParser.swift          # JSON to tree conversion
├── Views/
│   ├── ContentView.swift         # Main layout
│   ├── TreeView.swift            # Sidebar tree
│   ├── EditableJSONView.swift    # Editor panel
│   └── SupportingViews.swift     # Shared components
└── Utilities/
    ├── JSONSyntaxHighlighter.swift
    ├── SyntaxHighlightingTextView.swift
    └── Extensions.swift
```

## Screenshots

<p align="center">
  <img src=“docs/screenshots/darkmode.png" width="800" alt="JSON Editor in Dark Mode">
</p>

<p align="center">
  <img src=“docs/screenshots/validation.png" width="800" alt="Real-time Validation">
</p>

<p align="center">
  <img src=“docs/screenshots/compact.png" width="800" alt=“Compact view">
</p>

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

Built with SwiftUI and AppKit for macOS.
