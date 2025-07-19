#!/bin/bash

# Check if VERSION parameter is provided
if [ $# -eq 0 ]; then
  echo "Error: VERSION parameter is required"
  echo "Usage: $0 VERSION"
  exit 1
fi

VERSION="$1"
echo "Using VERSION: $VERSION"

# Source directory
SOURCE_DIR="/Users/nkrsingh/GitHubLocal/singhAws"
# Target directory
TARGET_DIR="/Users/nkrsingh/GitHubLocal/singhAws/generateBugBashBuilds"

# Step 1: Clean up generateBugBashBuilds folder
echo "Cleaning up generateBugBashBuilds folder..."
cd "$TARGET_DIR" || exit 1
rm -f manifest.json manifest-latest.json aws-lsp-codewhisperer.js amazonq-ui.js
rm -rf prod-*
rm -rf "$VERSION"

# Step 2: Download manifest.json
echo "Downloading latest manifest.json..."
curl -s https://aws-toolkit-language-servers.amazonaws.com/qAgenticChatServer/0/manifest.json -o manifest-latest.json

# Step 3: Run downloader.py
echo "Running downloader.py..."
python3 downloader.py

# Step 4: Run local build
cd "$SOURCE_DIR/language-servers/app/aws-lsp-codewhisperer-runtimes" || exit 1
echo "Running npm run local-build..."
npm run local-build

# Files to copy
FILE1="$SOURCE_DIR/language-servers/app/aws-lsp-codewhisperer-runtimes/build/aws-lsp-codewhisperer.js"
FILE2="$SOURCE_DIR/language-servers/chat-client/build/amazonq-ui.js"

# Remove files if they exist (redundant after cleanup, but keeping for safety)
if [ -f "$TARGET_DIR/aws-lsp-codewhisperer.js" ]; then
  echo "Removing existing aws-lsp-codewhisperer.js..."
  rm "$TARGET_DIR/aws-lsp-codewhisperer.js"
fi

if [ -f "$TARGET_DIR/amazonq-ui.js" ]; then
  echo "Removing existing amazonq-ui.js..."
  rm "$TARGET_DIR/amazonq-ui.js"
fi

# Copy files
echo "Copying aws-lsp-codewhisperer.js..."
cp "$FILE1" "$TARGET_DIR/"

echo "Copying amazonq-ui.js..."
cp "$FILE2" "$TARGET_DIR/"

echo "Build and copy completed successfully!"

# Execute zip.sh with the VERSION parameter
echo "Executing zip.sh with VERSION $VERSION..."
cd "$TARGET_DIR" || exit 1
./zip.sh "$VERSION"

# Execute update_manifest.py with the VERSION parameter
echo "Executing update_manifest.py with VERSION $VERSION..."
python3 update_manifest.py "$VERSION"

echo "All operations completed successfully!"