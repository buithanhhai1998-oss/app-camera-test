#!/usr/bin/env python3
"""
Downloads and extracts official portable Flutter SDK directly into D:\source\IOS\flutter
Completely self-contained - zero global modifications.
"""

import os
import sys
import json
import urllib.request
import zipfile
import shutil

IOS_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FLUTTER_DEST = os.path.join(IOS_ROOT, "flutter")
TEMP_ZIP = os.path.join(IOS_ROOT, "tools", "temp_flutter.zip")

def main():
    flutter_bat = os.path.join(FLUTTER_DEST, "bin", "flutter.bat")
    if os.path.exists(flutter_bat):
        print(f"[OK] Flutter SDK already installed at: {FLUTTER_DEST}")
        os.system(f'"{flutter_bat}" --version')
        return

    print(">>> Fetching Flutter release metadata...")
    url = "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
    req = urllib.request.urlopen(url)
    data = json.loads(req.read().decode("utf-8"))

    stable_hash = data["current_release"]["stable"]
    item = next((x for x in data["releases"] if x["hash"] == stable_hash), None)
    if not item:
        archive_path = "stable/windows/flutter_windows_3.24.5-stable.zip"
        version = "3.24.5"
    else:
        archive_path = item["archive"]
        version = item["version"]

    archive_url = f"https://storage.googleapis.com/flutter_infra_release/releases/{archive_path}"
    print(f"[OK] Target Flutter Version: {version}")
    print(f">>> Downloading from: {archive_url}")
    print(f">>> Destination: {TEMP_ZIP}")

    def report_progress(block_num, block_size, total_size):
        downloaded = block_num * block_size
        if total_size > 0:
            percent = downloaded * 100 / total_size
            mb = downloaded / (1024 * 1024)
            total_mb = total_size / (1024 * 1024)
            sys.stdout.write(f"\rDownloading: {percent:.1f}% ({mb:.1f} MB / {total_mb:.1f} MB)")
            sys.stdout.flush()

    os.makedirs(os.path.dirname(TEMP_ZIP), exist_ok=True)
    urllib.request.urlretrieve(archive_url, TEMP_ZIP, report_progress)
    print("\n[OK] Download complete.")

    print(f">>> Extracting to {IOS_ROOT}...")
    with zipfile.ZipFile(TEMP_ZIP, "r") as z:
        z.extractall(IOS_ROOT)

    print("[OK] Extraction complete.")
    if os.path.exists(TEMP_ZIP):
        os.remove(TEMP_ZIP)

    print(f"============================================================")
    print(f" [SUCCESS] Flutter SDK installed at: {FLUTTER_DEST}")
    print(f" You can now run .\\env.bat to start working!")
    print(f"============================================================")
    os.system(f'"{flutter_bat}" --version')

if __name__ == "__main__":
    main()
