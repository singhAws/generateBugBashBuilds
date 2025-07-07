#!/bin/bash

# Check if VERSION is provided as an argument
if [ $# -eq 0 ]; then
    echo "Error: VERSION parameter is required"
    echo "Usage: $0 <VERSION>"
    exit 1
fi

VERSION="$1"

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
process_platform "windows-x64"
process_platform "windows-arm64"
process_platform "linux-x64"
process_platform "linux-arm64"
process_platform "darwin-x64"
process_platform "darwin-arm64"

echo "All tasks completed successfully!"

PLATFORMS=("windows-x64" "windows-arm64" "linux-x64" "linux-arm64" "darwin-x64" "darwin-arm64")

# Create JSON file with zip information
json_file="$VERSION/zip_info.json"
echo "[" > "$json_file"

first_entry=true

for platform in "${PLATFORMS[@]}"; do
    for type in "servers" "clients"; do
        file="$VERSION/alpha-$platform/$type.zip"
        if [[ -f "$file" ]]; then
            # Calculate shasum and file size
            shasum=$(shasum -a 384 "$file" | awk '{print $1}')
            bytes=$(stat -f %z "$file")
            
            # Add comma before entry if not the first one
            if [ "$first_entry" = true ]; then
                first_entry=false
            else
                echo "," >> "$json_file"
            fi
            
            # Add JSON entry
            cat << EOF >> "$json_file"
  {
    "path": "$VERSION/alpha-$platform/$type.zip",
    "shasum": "$shasum",
    "bytes": $bytes
  }
EOF
        fi
    done
done

echo "
]" >> "$json_file"

echo "JSON file created at $json_file"