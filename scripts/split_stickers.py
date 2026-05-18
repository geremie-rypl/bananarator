#!/usr/bin/env python3
"""Split a sticker sheet (transparent PNG with multiple stickers) into
individual PNGs by alpha-channel connected components.

Usage:
    python3 split_stickers.py <input.png> <output_dir> [--prefix sticker_] [--min-area 5000]

Each output is named <prefix><index>.png, sorted left-to-right, top-to-bottom.
After it runs, rename the files to match the asset names the model expects.
"""
import argparse
import os
import sys
from PIL import Image


def find_islands(alpha, alpha_threshold=20):
    """Flood-fill to find connected non-transparent regions. Returns list of bboxes."""
    w, h = alpha.size
    px = alpha.load()
    visited = bytearray(w * h)
    bboxes = []
    for y in range(h):
        for x in range(w):
            if px[x, y] < alpha_threshold or visited[y * w + x]:
                continue
            # BFS
            min_x = max_x = x
            min_y = max_y = y
            stack = [(x, y)]
            visited[y * w + x] = 1
            count = 0
            while stack:
                cx, cy = stack.pop()
                count += 1
                if cx < min_x: min_x = cx
                if cx > max_x: max_x = cx
                if cy < min_y: min_y = cy
                if cy > max_y: max_y = cy
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not visited[ny * w + nx] and px[nx, ny] >= alpha_threshold:
                        visited[ny * w + nx] = 1
                        stack.append((nx, ny))
            bboxes.append((min_x, min_y, max_x + 1, max_y + 1, count))
    return bboxes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("output_dir")
    ap.add_argument("--prefix", default="sticker_")
    ap.add_argument("--min-area", type=int, default=5000, help="Skip islands smaller than this many pixels")
    ap.add_argument("--pad", type=int, default=16, help="Padding around each crop")
    ap.add_argument("--gap", type=int, default=40, help="Merge islands whose bboxes are within this many px (handles disconnected pieces of one sticker)")
    ap.add_argument("--no-merge", action="store_true", help="Skip the bbox-overlap merge pass entirely")
    args = ap.parse_args()

    img = Image.open(args.input).convert("RGBA")
    alpha = img.split()[-1]
    print(f"Loaded {args.input} ({img.size[0]}x{img.size[1]})", file=sys.stderr)

    bboxes = find_islands(alpha)
    print(f"Found {len(bboxes)} islands (raw)", file=sys.stderr)

    # Drop tiny noise
    bboxes = [b for b in bboxes if b[4] >= args.min_area]
    print(f"{len(bboxes)} after min-area filter", file=sys.stderr)

    # Merge nearby bboxes (e.g., detached chain link of pocket watch)
    def merge_pass(boxes):
        merged = True
        while merged:
            merged = False
            out = []
            used = [False] * len(boxes)
            for i, a in enumerate(boxes):
                if used[i]:
                    continue
                ax0, ay0, ax1, ay1, ac = a
                for j in range(i + 1, len(boxes)):
                    if used[j]:
                        continue
                    bx0, by0, bx1, by1, bc = boxes[j]
                    if (ax0 - args.gap <= bx1 and bx0 - args.gap <= ax1 and
                            ay0 - args.gap <= by1 and by0 - args.gap <= ay1):
                        ax0 = min(ax0, bx0); ay0 = min(ay0, by0)
                        ax1 = max(ax1, bx1); ay1 = max(ay1, by1)
                        ac += bc
                        used[j] = True
                        merged = True
                out.append((ax0, ay0, ax1, ay1, ac))
                used[i] = True
            boxes = out
        return boxes

    if not args.no_merge:
        bboxes = merge_pass(bboxes)
        print(f"{len(bboxes)} after merge", file=sys.stderr)

    # Sort top-to-bottom, left-to-right (with row tolerance)
    row_tol = 80
    bboxes.sort(key=lambda b: (b[1] // row_tol, b[0]))

    os.makedirs(args.output_dir, exist_ok=True)
    pad = args.pad
    W, H = img.size
    for i, (x0, y0, x1, y1, _) in enumerate(bboxes, 1):
        x0 = max(0, x0 - pad)
        y0 = max(0, y0 - pad)
        x1 = min(W, x1 + pad)
        y1 = min(H, y1 + pad)
        crop = img.crop((x0, y0, x1, y1))
        out = os.path.join(args.output_dir, f"{args.prefix}{i:02d}.png")
        crop.save(out, optimize=True)
        print(f"  {os.path.basename(out)}  ({crop.size[0]}x{crop.size[1]})")


if __name__ == "__main__":
    main()
