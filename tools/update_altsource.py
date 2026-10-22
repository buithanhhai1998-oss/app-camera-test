#!/usr/bin/env python3
"""
Updates AltSource apps.json with new release version, file size, download URL, and release date.
Used locally or in GitHub Actions CI to automate SideStore app distribution.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone

def update_altsource(input_path, output_path, version, download_url, size_bytes, release_date=None, description=""):
    if not os.path.exists(input_path):
        print(f"[!] Error: Source file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not release_date:
        release_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    # Clean version string (remove leading 'v' if present)
    clean_version = version.lstrip("v")

    # Find the main app entry in apps array
    apps = data.get("apps", [])
    if not apps:
        print("[!] Error: No apps defined in apps.json", file=sys.stderr)
        sys.exit(1)

    app = apps[0] # primary app entry
    app_versions = app.get("versions", [])

    new_version_entry = {
        "version": clean_version,
        "date": release_date,
        "localizedDescription": description or f"Release version {clean_version}",
        "downloadURL": download_url,
        "size": int(size_bytes),
        "minOSVersion": "13.0"
    }

    # Prepend or update version
    existing_idx = next((i for i, v in enumerate(app_versions) if v.get("version") == clean_version), None)
    if existing_idx is not None:
        app_versions[existing_idx] = new_version_entry
        print(f"[OK] Updated existing version entry: {clean_version}")
    else:
        app_versions.insert(0, new_version_entry)
        print(f"[OK] Appended new version entry: {clean_version}")

    app["versions"] = app_versions
    data["apps"] = apps

    # Ensure output directory exists
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"[SUCCESS] Wrote updated AltSource manifest to: {output_path}")

def main():
    parser = argparse.ArgumentParser(description="Update SideStore AltSource apps.json")
    parser.add_argument("--input", default="altsource/apps.json", help="Path to input apps.json")
    parser.add_argument("--output", default="altsource/apps.json", help="Path to output apps.json")
    parser.add_argument("--version", required=True, help="Release version (e.g. 1.0.0 or v1.0.0)")
    parser.add_argument("--download-url", required=True, help="Direct HTTPS download URL for the IPA")
    parser.add_argument("--size", required=True, type=int, help="Size of the IPA file in bytes")
    parser.add_argument("--date", default=None, help="Release date in YYYY-MM-DD format (defaults to UTC today)")
    parser.add_argument("--description", default="", help="Changelog or release description")

    args = parser.parse_args()
    update_altsource(
        input_path=args.input,
        output_path=args.output,
        version=args.version,
        download_url=args.download_url,
        size_bytes=args.size,
        release_date=args.date,
        description=args.description
    )

if __name__ == "__main__":
    main()
