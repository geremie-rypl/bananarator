#!/usr/bin/env python3
"""Take the split sticker PNGs in incoming/split/<pack>/ and generate
.imageset folders inside Bananarator/Resources/Assets.xcassets/Stickers/
so SwiftUI's Image(named:) finds them.

Idempotent — re-running rebuilds the Stickers group from scratch.
"""
import json
import os
import shutil
import sys

PROJECT = os.path.expanduser("~/dickorator")
SRC = os.path.join(PROJECT, "incoming/split")
DST_GROUP = os.path.join(PROJECT, "Bananarator/Resources/Assets.xcassets/Stickers")

if os.path.exists(DST_GROUP):
    shutil.rmtree(DST_GROUP)
os.makedirs(DST_GROUP)

with open(os.path.join(DST_GROUP, "Contents.json"), "w") as f:
    json.dump({
        "info": {"author": "xcode", "version": 1},
        "properties": {"provides-namespace": False},
    }, f, indent=2)

total = 0
for pack in sorted(os.listdir(SRC)):
    pack_dir = os.path.join(SRC, pack)
    if not os.path.isdir(pack_dir):
        continue
    pack_count = 0
    for fname in sorted(os.listdir(pack_dir)):
        if not fname.endswith(".png"):
            continue
        name = fname[:-4]
        imageset = os.path.join(DST_GROUP, f"{name}.imageset")
        os.makedirs(imageset, exist_ok=True)
        shutil.copy(os.path.join(pack_dir, fname), os.path.join(imageset, fname))
        with open(os.path.join(imageset, "Contents.json"), "w") as f:
            json.dump({
                "images": [{"filename": fname, "idiom": "universal"}],
                "info": {"author": "xcode", "version": 1},
            }, f, indent=2)
        pack_count += 1
        total += 1
    print(f"  {pack}: {pack_count} stickers")

print(f"\nTotal: {total} imagesets generated in {DST_GROUP}")
