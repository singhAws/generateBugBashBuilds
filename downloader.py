import json
import os
import requests
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

def download_file(url, filepath):
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        with open(filepath, 'wb') as f:
            if total_size == 0:
                f.write(response.content)
            else:
                downloaded = 0
                for data in response.iter_content(chunk_size=8192):
                    downloaded += len(data)
                    f.write(data)
                print(f"\rDownloaded {filepath.name}: {downloaded}/{total_size} bytes")
        return True, filepath.name
    except Exception as e:
        return False, f"Error downloading {filepath.name}: {str(e)}"

def download_platform_files(target):
    platform_name = target['platform']
    arch = target['arch']
    
    # Create directory
    output_dir = Path(f"prod-{platform_name}-{arch}")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    download_tasks = []
    
    # Prepare download tasks
    for content in target['contents']:
        filepath = output_dir / content['filename']
        download_tasks.append((content['url'], filepath))
    
    return platform_name, arch, download_tasks

def main():
    # Load the manifest
    with open('manifest.json', 'r') as f:
        manifest = json.load(f)
    
    all_download_tasks = []
    
    # Collect all download tasks
    for target in manifest['versions'][0]['targets']:
        platform_name, arch, tasks = download_platform_files(target)
        print(f"Preparing downloads for {platform_name}-{arch}")
        all_download_tasks.extend(tasks)
    
    # Use ThreadPoolExecutor to download files concurrently
    print("\nStarting downloads...")
    with ThreadPoolExecutor(max_workers=5) as executor:
        future_to_url = {
            executor.submit(download_file, url, filepath): filepath.name
            for url, filepath in all_download_tasks
        }
        
        for future in as_completed(future_to_url):
            filename = future_to_url[future]
            success, message = future.result()
            if success:
                print(f"✓ Successfully downloaded {message}")
            else:
                print(f"✗ {message}")

if __name__ == "__main__":
    main()