#!/bin/bash
VERSION="1.9.0"

# Function to process a single platform
process_platform() {
    local platform=$1
    
    # Create the destination directories if they don't exist
    mkdir -p "./prod-$platform/servers"
    mkdir -p "./prod-$platform/clients"
    mkdir -p "./$VERSION/alpha-$platform"

    # Process servers.zip - extract, replace, re-zip
    if [[ -f "./prod-$platform/servers.zip" ]]; then
        echo "  Processing servers.zip for $platform..."
        # Extract the production servers.zip
        unzip -q "./prod-$platform/servers.zip" -d "./prod-$platform/servers/"
        
        # Replace aws-lsp-codewhisperer.js with your version from root folder
        cp "./aws-lsp-codewhisperer.js" "./prod-$platform/servers/aws-lsp-codewhisperer.js"
        
        # Remove any .DS_Store files
        find "./prod-$platform/servers" -name ".DS_Store" -delete
        
        # Re-zip the servers directory
        cd "./prod-$platform/servers"
        zip -r -q "../../$VERSION/alpha-$platform/servers.zip" .
        cd ../..
    fi

    # Process clients.zip - extract, replace, re-zip  
    if [[ -f "./prod-$platform/clients.zip" ]]; then
        echo "  Processing clients.zip for $platform..."
        # Extract the production clients.zip
        unzip -q "./prod-$platform/clients.zip" -d "./prod-$platform/clients/"
        
        # Replace amazonq-ui.js with your version from root folder
        cp "./amazonq-ui.js" "./prod-$platform/clients/amazonq-ui.js"
        
        # Remove any .DS_Store files
        find "./prod-$platform/clients" -name ".DS_Store" -delete
        
        # Re-zip the clients directory
        cd "./prod-$platform/clients"
        zip -r -q "../../$VERSION/alpha-$platform/clients.zip" .
        cd ../..
    fi
    
    echo "Processing completed for $platform"
}

# Process for each platform
process_platform "darwin-arm64"
process_platform "darwin-x64"
process_platform "windows-x64"

echo "All tasks completed successfully!"

PLATFORMS=("darwin-arm64" "darwin-x64" "windows-x64")

for platform in "${PLATFORMS[@]}"; do
    file="$VERSION/alpha-$platform/servers.zip"
    echo "File: $file"
    if [[ -f "$file" ]]; then
        echo "SHA384: $(shasum -a 384 "$file" | awk '{print $1}')"
    else
        echo "File not found"
    fi
    echo "-------------------"
done