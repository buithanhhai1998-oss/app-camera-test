#!/usr/bin/env python3
"""
High-speed, resilient Flutter SDK installer for D:\source\IOS\flutter.
Completely localized - zero global modifications.
"""

import os
import sys
import json
import urllib.request
import subprocess
import shutil

IOS_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FLUTTER_DEST = os.path.join(IOS_ROOT, "flutter")
TEMP_ZIP = os.path.join(IOS_ROOT, "tools", "temp_flutter.zip")

def main():
    flutter_bat = os.path.join(FLUTTER_DEST, "bin", "flutter.bat")
    if os.path.exists(flutter_bat):
        print(f"[OK] Flutter SDK is already installed at: {FLUTTER_DEST}")
        subprocess.run([flutter_bat, "--version"])
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

    os.makedirs(os.path.dirname(TEMP_ZIP), exist_ok=True)

    # Use curl.exe if available for fast download with resume capability
    curl_path = shutil.which("curl")
    if curl_path:
        print(">>> Using Windows curl with resume support...")
        cmd = [curl_path, "-L", "-C", "-", "--retry", "5", "--retry-delay", "2", "-o", TEMP_ZIP, archive_url]
        res = subprocess.run(cmd)
        if res.returncode != 0:
            print("[!] curl failed, falling back to urllib...")
            urllib.request.urlretrieve(archive_url, TEMP_ZIP)
    else:
        print(">>> Downloading via urllib...")
        urllib.request.urlretrieve(archive_url, TEMP_ZIP)

    print("\n[OK] Download complete.")

    print(f">>> Extracting to {IOS_ROOT}...")
    tar_path = shutil.which("tar")
    if tar_path:
        print(">>> Using high-speed tar.exe for extraction...")
        cmd = [tar_path, "-xf", TEMP_ZIP, "-C", IOS_ROOT]
        res = subprocess.run(cmd)
        if res.returncode != 0:
            print("[!] tar failed, falling back to zipfile...")
            import zipfile
            with zipfile.ZipFile(TEMP_ZIP, "r") as z:
                z.extractall(IOS_ROOT)
    else:
        import zipfile
        with zipfile.ZipFile(TEMP_ZIP, "r") as z:
            z.extractall(IOS_ROOT)

    print("[OK] Extraction complete.")
    if os.path.exists(TEMP_ZIP):
        try:
            os.remove(TEMP_ZIP)
        except Exception:
            pass

    print(f"============================================================")
    print(f" [SUCCESS] Flutter SDK installed at: {FLUTTER_DEST}")
    print(f" Initializing Flutter toolchain...")
    print(f"============================================================")
    subprocess.run([flutter_bat, "--version"])

if __name__ == "__main__":
    main()
