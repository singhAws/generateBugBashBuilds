#!/usr/bin/env python3
import json
import os
import sys
import shutil
import subprocess
import boto3

def update_manifest(version):
    """
    Update manifest.json file for the specified version.
    
    Args:
        version (str): The version to use for updating the manifest
    """
    # Get the base directory (toolsForBuild)
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Paths
    manifest_latest_path = os.path.join(base_dir, "manifest-latest.json")
    version_manifest_path = os.path.join(base_dir, version, "manifest.json")
    zip_info_path = os.path.join(base_dir, version, "zip_info.json")
    
    # Create version directory if it doesn't exist
    os.makedirs(os.path.join(base_dir, version), exist_ok=True)
    
    # Delete VERSION/manifest.json if it already exists
    if os.path.exists(version_manifest_path):
        os.remove(version_manifest_path)
    
    # Copy manifest-latest.json to VERSION/manifest.json
    shutil.copy(manifest_latest_path, version_manifest_path)
    
    # Load the manifest file
    with open(version_manifest_path, 'r') as f:
        manifest = json.load(f)
    
    # Keep only the first item in versions array
    if len(manifest['versions']) > 1:
        manifest['versions'] = [manifest['versions'][0]]
    
    # Update serverVersion field to VERSION
    manifest['versions'][0]['serverVersion'] = version
    
    # Load zip_info.json if it exists
    if os.path.exists(zip_info_path):
        with open(zip_info_path, 'r') as f:
            zip_info = json.load(f)
        
        # Create a lookup dictionary for zip_info entries
        zip_info_dict = {}
        for item in zip_info:
            path_parts = item['path'].split('/')
            if len(path_parts) >= 3:
                platform_arch = path_parts[1].split('-')
                if len(platform_arch) >= 3:
                    platform = platform_arch[1]
                    arch = platform_arch[2]
                    filename = path_parts[-1]
                    key = f"{platform}-{arch}-{filename}"
                    zip_info_dict[key] = item
        
        # Update each target in targets array with values from zip_info.json
        for target in manifest['versions'][0]['targets']:
            platform = target['platform']
            arch = target['arch']
            
            for content in target['contents']:
                filename = content['filename']
                key = f"{platform}-{arch}-{filename}"
                
                if key in zip_info_dict:
                    info = zip_info_dict[key]
                    content['hashes'] = [f"sha384:{info['shasum']}"]
                    content['bytes'] = info['bytes']
                    content['url'] = f"https://d1lr5061hfwsy1.cloudfront.net/language-servers-artifacts/{version}/alpha-{platform}-{arch}/{filename}"
    
    # Write updated manifest back to file
    with open(version_manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    print(f"Updated {version_manifest_path}")
    
    # Run ada command to fetch admin credentials
    try:
        print("Fetching admin credentials from isengard account...")
        subprocess.run(["ada", "credentials", "update", "--account", "726188179833", "--role", "Admin", "--once"], check=True)
        print("Successfully fetched admin credentials")
        
        # Upload VERSION folder to S3
        upload_to_s3(version, os.path.join(base_dir, version))
    except subprocess.CalledProcessError as e:
        print(f"Error fetching admin credentials: {e}")
    except FileNotFoundError:
        print("Error: 'ada' command not found. Please ensure it's installed and in your PATH.")

def upload_to_s3(version, version_dir):
    """
    Upload VERSION folder to S3 bucket
    
    Args:
        version (str): The version being processed
        version_dir (str): Path to the VERSION directory
    """
    try:
        s3 = boto3.client('s3')
        bucket_name = 'q-code-review-tool-files'
        s3_prefix = f'language-servers-artifacts/{version}/'
        
        # Delete the VERSION folder if it already exists in S3
        print(f"Checking if {version} folder exists in S3...")
        response = s3.list_objects_v2(Bucket=bucket_name, Prefix=s3_prefix)
        if 'Contents' in response:
            print(f"Deleting existing {version} folder from S3...")
            for obj in response['Contents']:
                s3.delete_object(Bucket=bucket_name, Key=obj['Key'])
            print(f"Successfully deleted existing {version} folder from S3")
        
        print(f"Uploading {version} folder to S3...")

        # Walk through the version directory and upload all files
        for root, _, files in os.walk(version_dir):
            for file in files:
                local_path = os.path.join(root, file)
                # Create S3 key by removing the version_dir prefix and adding s3_prefix
                relative_path = os.path.relpath(local_path, os.path.dirname(version_dir))
                s3_key = s3_prefix + relative_path.replace(version + '/', '')
                
                print(f"Uploading {local_path} to s3://{bucket_name}/{s3_key}")
                s3.upload_file(local_path, bucket_name, s3_key)
        
        print(f"Successfully uploaded {version} folder to S3")
        # Display path to uploaded manifest.json file
        manifest_url = f"https://d1lr5061hfwsy1.cloudfront.net/language-servers-artifacts/{version}/manifest.json"
        print(f"Manifest URL: {manifest_url}")
    except Exception as e:
        print(f"Error uploading to S3: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python update_manifest.py VERSION")
        sys.exit(1)
    
    version = sys.argv[1]
    update_manifest(version)