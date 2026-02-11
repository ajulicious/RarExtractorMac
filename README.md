# RarExtractor for macOS

A native, lightweight macOS application for extracting RAR archives. Built with Swift and SwiftUI.

![RarExtractor Icon](AppIcon.iconset/icon_128x128.png)

## Features

- **Native macOS App** — Built with SwiftUI, runs natively on Apple Silicon and Intel Macs.
- **Drag & Drop** — Simply drag `.rar` files onto the window to extract.
- **File Picker** — Use the "Select File..." button to browse for archives.
- **Self-Contained** — Bundles `unrar` internally; no external dependencies required.
- **Auto-Reveal** — Automatically opens the extracted folder in Finder upon completion.

## Requirements

- macOS 11.0 (Big Sur) or later
- Apple Silicon (M1/M2/M3) or Intel Mac

## Installation

### Option 1: Download the Pre-built App

1. Download `RarExtractor.app` from the [Releases](https://github.com/ajulicious/RarExtractorMac/releases) page.
2. Move it to your `/Applications` folder.
3. If macOS says the app is damaged, open Terminal and run:
   ```bash
   xattr -cr /Applications/RarExtractor.app
   ```

### Option 2: Build from Source

```bash
git clone https://github.com/ajulicious/RarExtractorMac.git
cd RarExtractorMac

# Compile
swiftc Sources/RarExtractor/RarExtractorApp.swift \
      Sources/RarExtractor/ContentView.swift \
      Sources/RarExtractor/RarLogic.swift \
      -o RarExtractor.app/Contents/MacOS/RarExtractor \
      -target arm64-apple-macos11.0 \
      -parse-as-library

# Clear quarantine flags
xattr -cr RarExtractor.app

# Launch
open RarExtractor.app
```

## Usage

1. Launch `RarExtractor.app`.
2. **Drag & Drop** a `.rar` file onto the window, or click **"Select File..."** to browse.
3. The archive will be extracted to a folder with the same name, in the same directory as the archive.
4. Once complete, the destination folder opens in Finder automatically.

## Project Structure

```
RarExtractorMac/
├── Package.swift                          # Swift Package Manager config
├── Sources/RarExtractor/
│   ├── RarExtractorApp.swift              # App entry point (@main)
│   ├── ContentView.swift                  # SwiftUI user interface
│   └── RarLogic.swift                     # Extraction logic (unrar wrapper)
├── RarExtractor.app/                      # Pre-built app bundle
│   └── Contents/
│       ├── Info.plist
│       ├── MacOS/RarExtractor
│       └── Resources/
│           ├── AppIcon.icns
│           └── unrar                      # Bundled unrar binary
└── README.md
```

## How It Works

The app wraps the `unrar` command-line utility (bundled inside the app) and provides a simple SwiftUI interface. When you drop or select a RAR file:

1. The app locates the bundled `unrar` binary from `Bundle.main`.
2. Creates a destination folder named after the archive.
3. Runs `unrar x -y <archive> <destination>` via `Process`.
4. Streams output for progress feedback.
5. Opens the destination in Finder when done.

## License

This project uses the [unrar](https://www.rarlab.com/rar_add.htm) binary from RARLAB. Please refer to their license for usage terms regarding `unrar`.

## Author

Made by [ajulicious](https://github.com/ajulicious).
