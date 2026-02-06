#!/usr/bin/env python3
"""
Generate NameDrill app icon - 1024x1024 PNG
Design: Clean flashcard with person silhouette - conveys "learn names"
Colors from app theme: Primary #6366F1 (Indigo)
"""

from PIL import Image, ImageDraw
import math

# Icon dimensions
SIZE = 1024
CENTER = SIZE // 2

# Colors from app theme
PRIMARY = (99, 102, 241)  # #6366F1 Indigo
PRIMARY_DARK = (67, 70, 180)  # Darker indigo for depth
PRIMARY_LIGHT = (165, 167, 255)  # Lighter for accents
WHITE = (255, 255, 255)
LIGHT_GRAY = (240, 240, 250)

def create_icon():
    # Create image with transparent background
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # === BACKGROUND - Rounded square ===
    padding = 50
    corner_radius = 220
    
    # Main background
    draw.rounded_rectangle(
        [(padding, padding), (SIZE - padding, SIZE - padding)],
        radius=corner_radius,
        fill=PRIMARY
    )
    
    # === FLASHCARD ===
    card_margin_x = 140
    card_margin_top = 160
    card_margin_bottom = 180
    card_radius = 50
    
    # Card shadow
    shadow_offset = 12
    draw.rounded_rectangle(
        [(card_margin_x + shadow_offset, card_margin_top + shadow_offset), 
         (SIZE - card_margin_x + shadow_offset, SIZE - card_margin_bottom + shadow_offset)],
        radius=card_radius,
        fill=(40, 40, 80, 100)
    )
    
    # Main card (white)
    draw.rounded_rectangle(
        [(card_margin_x, card_margin_top), 
         (SIZE - card_margin_x, SIZE - card_margin_bottom)],
        radius=card_radius,
        fill=WHITE
    )
    
    # === PERSON SILHOUETTE ===
    person_center_x = CENTER
    
    # Head
    head_y = 340
    head_radius = 95
    draw.ellipse(
        [(person_center_x - head_radius, head_y - head_radius),
         (person_center_x + head_radius, head_y + head_radius)],
        fill=PRIMARY
    )
    
    # Shoulders/body - upper portion of ellipse
    shoulders_top = head_y + head_radius - 20
    shoulders_width = 180
    shoulders_height = 200
    
    # Draw full ellipse for shoulders
    draw.ellipse(
        [(person_center_x - shoulders_width, shoulders_top),
         (person_center_x + shoulders_width, shoulders_top + shoulders_height * 2)],
        fill=PRIMARY
    )
    
    # Mask bottom part with white to show only shoulders
    card_bottom_inner = SIZE - card_margin_bottom - 5
    draw.rectangle(
        [(card_margin_x + 5, shoulders_top + shoulders_height + 20), 
         (SIZE - card_margin_x - 5, card_bottom_inner)],
        fill=WHITE
    )
    
    # === NAME PLACEHOLDER LINES ===
    line_y = 680
    line_height = 22
    line_radius = line_height // 2
    
    # Main name line
    line1_width = 260
    draw.rounded_rectangle(
        [(CENTER - line1_width//2, line_y), 
         (CENTER + line1_width//2, line_y + line_height)],
        radius=line_radius,
        fill=PRIMARY_LIGHT
    )
    
    # Subtitle line (shorter, lighter)
    line2_y = line_y + 40
    line2_width = 160
    draw.rounded_rectangle(
        [(CENTER - line2_width//2, line2_y), 
         (CENTER + line2_width//2, line2_y + line_height)],
        radius=line_radius,
        fill=LIGHT_GRAY
    )
    
    # === BRAIN/MEMORY BADGE ===
    # Small badge in top-right corner representing learning/memory
    badge_x = SIZE - card_margin_x - 85
    badge_y = card_margin_top + 85
    badge_radius = 48
    
    # Badge circle
    draw.ellipse(
        [(badge_x - badge_radius, badge_y - badge_radius),
         (badge_x + badge_radius, badge_y + badge_radius)],
        fill=PRIMARY
    )
    
    # Draw checkmark inside (learned/memorized concept)
    check_color = WHITE
    # Checkmark path
    check_points = [
        (badge_x - 22, badge_y),
        (badge_x - 5, badge_y + 18),
        (badge_x + 25, badge_y - 15)
    ]
    draw.line([check_points[0], check_points[1]], fill=check_color, width=10)
    draw.line([check_points[1], check_points[2]], fill=check_color, width=10)
    
    # Round the line ends with circles
    for point in check_points:
        draw.ellipse(
            [(point[0] - 5, point[1] - 5), (point[0] + 5, point[1] + 5)],
            fill=check_color
        )
    
    return img

def create_foreground_adaptive():
    """Create foreground for adaptive icons - centered with padding for safe zone"""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # For adaptive icons, content should be in center ~66% 
    # We'll draw just the card and person, no background
    
    # Scale factor to fit in safe zone
    scale = 0.72
    offset_x = int(SIZE * (1 - scale) / 2)
    offset_y = int(SIZE * (1 - scale) / 2)
    
    # Card dimensions (scaled)
    card_left = offset_x + 50
    card_right = SIZE - offset_x - 50
    card_top = offset_y + 60
    card_bottom = SIZE - offset_y - 80
    card_radius = 40
    
    # Card shadow
    draw.rounded_rectangle(
        [(card_left + 10, card_top + 10), (card_right + 10, card_bottom + 10)],
        radius=card_radius,
        fill=(40, 40, 80, 80)
    )
    
    # Main card
    draw.rounded_rectangle(
        [(card_left, card_top), (card_right, card_bottom)],
        radius=card_radius,
        fill=WHITE
    )
    
    # Person
    person_x = CENTER
    head_y = int(320 * scale) + offset_y + 40
    head_r = int(80 * scale)
    
    draw.ellipse(
        [(person_x - head_r, head_y - head_r),
         (person_x + head_r, head_y + head_r)],
        fill=PRIMARY
    )
    
    shoulders_top = head_y + head_r - 15
    shoulders_w = int(150 * scale)
    shoulders_h = int(170 * scale)
    
    draw.ellipse(
        [(person_x - shoulders_w, shoulders_top),
         (person_x + shoulders_w, shoulders_top + shoulders_h * 2)],
        fill=PRIMARY
    )
    
    # Mask
    draw.rectangle(
        [(card_left + 5, shoulders_top + shoulders_h + 15), 
         (card_right - 5, card_bottom - 5)],
        fill=WHITE
    )
    
    # Name lines
    line_y = int(SIZE * 0.66)
    line_h = 18
    
    draw.rounded_rectangle(
        [(CENTER - 100, line_y), (CENTER + 100, line_y + line_h)],
        radius=9,
        fill=PRIMARY_LIGHT
    )
    
    draw.rounded_rectangle(
        [(CENTER - 60, line_y + 32), (CENTER + 60, line_y + 32 + line_h)],
        radius=9,
        fill=LIGHT_GRAY
    )
    
    # Badge with checkmark
    badge_x = card_right - 65
    badge_y = card_top + 65
    badge_r = 38
    
    draw.ellipse(
        [(badge_x - badge_r, badge_y - badge_r),
         (badge_x + badge_r, badge_y + badge_r)],
        fill=PRIMARY
    )
    
    # Checkmark
    check_points = [
        (badge_x - 17, badge_y),
        (badge_x - 4, badge_y + 14),
        (badge_x + 20, badge_y - 12)
    ]
    draw.line([check_points[0], check_points[1]], fill=WHITE, width=8)
    draw.line([check_points[1], check_points[2]], fill=WHITE, width=8)
    for point in check_points:
        draw.ellipse([(point[0] - 4, point[1] - 4), (point[0] + 4, point[1] + 4)], fill=WHITE)
    
    return img

def create_background_adaptive():
    """Solid color background for adaptive icons"""
    img = Image.new('RGBA', (SIZE, SIZE), PRIMARY)
    return img

if __name__ == '__main__':
    # Main icon (for iOS, web, store listings)
    icon = create_icon()
    icon.save('app_icon.png', 'PNG')
    print(f"Created app_icon.png ({SIZE}x{SIZE})")
    
    # Adaptive icon layers (for Android)
    fg = create_foreground_adaptive()
    fg.save('app_icon_foreground.png', 'PNG')
    print(f"Created app_icon_foreground.png ({SIZE}x{SIZE})")
    
    bg = create_background_adaptive()
    bg.save('app_icon_background.png', 'PNG')
    print(f"Created app_icon_background.png ({SIZE}x{SIZE})")
