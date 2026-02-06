#!/usr/bin/env python3
"""Generate feature graphic for Play Store (1024x500)."""

from PIL import Image, ImageDraw, ImageFont
import os

SOURCE_ICON = "/home/manuelpa/.openclaw/workspace/projects/namedrill/namedrill_icon_cropped.png"
OUTPUT = "/home/manuelpa/.openclaw/workspace/projects/namedrill/app/store-assets/feature-graphic.png"

WIDTH = 1024
HEIGHT = 500

def create_gradient(width, height):
    """Create a gradient background matching the icon colors (purple to teal)."""
    img = Image.new("RGB", (width, height))
    pixels = img.load()
    
    # Colors from the icon: purple (#9B59B6) to teal (#1ABC9C)
    # Let's use a diagonal gradient
    start_color = (138, 82, 176)  # Purple
    end_color = (26, 188, 156)    # Teal
    
    for y in range(height):
        for x in range(width):
            # Diagonal gradient based on position
            ratio = (x / width * 0.6 + y / height * 0.4)
            r = int(start_color[0] + (end_color[0] - start_color[0]) * ratio)
            g = int(start_color[1] + (end_color[1] - start_color[1]) * ratio)
            b = int(start_color[2] + (end_color[2] - start_color[2]) * ratio)
            pixels[x, y] = (r, g, b)
    
    return img

def main():
    print("Creating feature graphic...")
    
    # Create gradient background
    bg = create_gradient(WIDTH, HEIGHT)
    
    # Load and resize icon
    icon = Image.open(SOURCE_ICON).convert("RGBA")
    icon_size = 280
    icon = icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Position icon on left side
    icon_x = 120
    icon_y = (HEIGHT - icon_size) // 2
    
    # Paste icon onto background
    bg.paste(icon, (icon_x, icon_y), icon)
    
    # Add text
    draw = ImageDraw.Draw(bg)
    
    # Try to find a good font
    font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    ]
    
    title_font = None
    subtitle_font = None
    
    for fp in font_paths:
        if os.path.exists(fp):
            title_font = ImageFont.truetype(fp, 72)
            subtitle_font = ImageFont.truetype(fp, 32)
            print(f"  Using font: {fp}")
            break
    
    if title_font is None:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
        print("  Using default font")
    
    # Text position (right of icon)
    text_x = icon_x + icon_size + 80
    
    # Title
    title = "NameDrill"
    title_y = HEIGHT // 2 - 50
    draw.text((text_x, title_y), title, fill="white", font=title_font)
    
    # Subtitle
    subtitle = "Remember every name & face"
    subtitle_y = title_y + 80
    draw.text((text_x, subtitle_y), subtitle, fill=(255, 255, 255, 200), font=subtitle_font)
    
    # Save
    bg.save(OUTPUT, "PNG")
    print(f"  Saved: {OUTPUT}")
    print("Done!")

if __name__ == "__main__":
    main()
