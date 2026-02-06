#!/usr/bin/env python3
"""Generate all app icons from the source image."""

from PIL import Image
import os

SOURCE = "/home/manuelpa/.openclaw/workspace/projects/namedrill/namedrill_icon_cropped.png"
APP_DIR = "/home/manuelpa/.openclaw/workspace/projects/namedrill/app"

# Android mipmap sizes (standard launcher icon)
ANDROID_MIPMAP = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Android adaptive icon foreground (needs padding, 108dp with 72dp safe zone)
# The foreground image should be 108dp with the icon in center 72dp
ANDROID_ADAPTIVE = {
    "drawable-mdpi": 108,
    "drawable-hdpi": 162,
    "drawable-xhdpi": 216,
    "drawable-xxhdpi": 324,
    "drawable-xxxhdpi": 432,
}

# iOS icon sizes
IOS_ICONS = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-50x50@1x.png", 50),
    ("Icon-App-50x50@2x.png", 100),
    ("Icon-App-57x57@1x.png", 57),
    ("Icon-App-57x57@2x.png", 114),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-72x72@1x.png", 72),
    ("Icon-App-72x72@2x.png", 144),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

def resize_icon(src_img, size, output_path):
    """Resize and save icon."""
    resized = src_img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(output_path, "PNG")
    print(f"  Created: {output_path} ({size}x{size})")

def create_adaptive_foreground(src_img, size, output_path):
    """Create adaptive icon foreground with proper padding.
    The icon should be 66.67% of the canvas (72/108)."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon_size = int(size * 72 / 108)  # 66.67% of canvas
    offset = (size - icon_size) // 2
    
    icon = src_img.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    canvas.paste(icon, (offset, offset), icon)
    canvas.save(output_path, "PNG")
    print(f"  Created: {output_path} ({size}x{size}, icon={icon_size})")

def main():
    print("Loading source image...")
    src = Image.open(SOURCE).convert("RGBA")
    print(f"  Source: {src.size[0]}x{src.size[1]}")
    
    # Android mipmap icons
    print("\nGenerating Android mipmap icons...")
    android_res = os.path.join(APP_DIR, "android/app/src/main/res")
    for folder, size in ANDROID_MIPMAP.items():
        path = os.path.join(android_res, folder, "ic_launcher.png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resize_icon(src, size, path)
    
    # Android adaptive foreground
    print("\nGenerating Android adaptive icon foregrounds...")
    for folder, size in ANDROID_ADAPTIVE.items():
        path = os.path.join(android_res, folder, "ic_launcher_foreground.png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        create_adaptive_foreground(src, size, path)
    
    # iOS icons
    print("\nGenerating iOS icons...")
    ios_dir = os.path.join(APP_DIR, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
    os.makedirs(ios_dir, exist_ok=True)
    for filename, size in IOS_ICONS:
        path = os.path.join(ios_dir, filename)
        resize_icon(src, size, path)
    
    # Store assets
    print("\nGenerating store assets...")
    store_dir = os.path.join(APP_DIR, "store-assets")
    os.makedirs(store_dir, exist_ok=True)
    resize_icon(src, 512, os.path.join(store_dir, "icon-512.png"))
    resize_icon(src, 1024, os.path.join(store_dir, "icon-1024.png"))
    
    print("\nDone!")

if __name__ == "__main__":
    main()
