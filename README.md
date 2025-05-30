# AWS Language Server Package Builder

This repository contains tools and files for building custom AWS language server packages with modified JavaScript files.

## Files

### Core Files
- `aws-lsp-codewhisperer.js` - Custom AWS LSP CodeWhisperer JavaScript file
- `amazonq-ui.js` - Custom Amazon Q UI JavaScript file
- `manifest.json` - Production manifest file containing download URLs and checksums

### Scripts
- `zip.sh` - Main packaging script that:
  - Downloads production files from manifest
  - Extracts `servers.zip` and `clients.zip`
  - Replaces JavaScript files with custom versions
  - Re-packages and generates SHA384 checksums
- `downloader.py` - Downloads production files from manifest

## Usage

1. **Download production files:**
   ```bash
   python3 downloader.py
   ```

2. **Package with custom files:**
   ```bash
   ./zip.sh
   ```

3. **Generated packages will be in:**
   ```
   1.9.0/alpha-{platform}/
   ├── servers.zip
   └── clients.zip
   ```

## Supported Platforms
- darwin-arm64
- darwin-x64  
- windows-x64

## Output
The script generates platform-specific packages with:
- Your custom `aws-lsp-codewhisperer.js` in `servers.zip`
- Your custom `amazonq-ui.js` in `clients.zip`
- SHA384 checksums for verification 