# AWS Language Server Package Builder

This repository contains tools and files for building custom AWS language server packages with modified JavaScript files.

## Files

### Scripts
- `build-and-copy.sh`
   Purpose: Automates the complete build and packaging process for AWS language server packages with custom modifications.
   Key Steps:

   1. Parameter Validation: Requires a VERSION parameter to run

   2. Environment Cleanup: 
      • Removes old manifest files, JavaScript files, and version directories
      • Cleans the toolsForBuild workspace

   3. Manifest Download: 
      • Downloads the latest manifest.json from AWS servers

   4. Production File Download: 
      • Runs downloader.py to fetch production packages

   5. Local Build Process: 
      • Navigates to the language server runtime directory
      • Executes npm run local-build to compile custom code

   6. File Copy Operations: 
      • Copies built aws-lsp-codewhisperer.js from the build directory
      • Copies built amazonq-ui.js from the chat client build directory

   7. Package Generation: 
      • Executes zip.sh with the VERSION parameter to create custom packages

   8. Manifest Update: 
      • Runs update_manifest.py to update manifest with new version information

## Usage
```bash
./build-and-copy.sh VERSION
```

## Supported Platforms
- darwin-arm64 & x64
- linux-arm64 & x64  
- windows-arm64 & x64

## Output
Gives the URL to the new manifest.json file

## What you need to do after run script
-  Update manifestUrl in `aws-toolkit-vscode/packages/amazonq/src/lsp/config.ts`
-  Update supportedVersions to the new VERSION
-  Run - `npm run package` for aws-toolkit-vscode