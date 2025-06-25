#!/usr/bin/env python3
"""
Simple Task Manager App Icon Generator
Creates app icons in various sizes for iOS and Android
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon():
    # Create base icon (1024x1024 for iOS App Store)
    size = 1024
    img = Image.new('RGB', (size, size), '#2196F3')  # Material Blue
    draw = ImageDraw.Draw(img)
    
    # Draw background gradient effect
    for i in range(size):
        alpha = int(255 * (1 - i / size * 0.3))
        color = (33, 150, 243, alpha)  # Blue with varying alpha
        draw.line([(0, i), (size, i)], fill=color[:3])
    
    # Draw circular background
    margin = size // 8
    circle_size = size - 2 * margin
    draw.ellipse([margin, margin, margin + circle_size, margin + circle_size], 
                fill='#1976D2', outline='#0D47A1', width=8)
    
    # Draw checkmark symbol
    check_margin = size // 4
    check_size = size - 2 * check_margin
    
    # Checkmark path
    check_points = [
        (check_margin + check_size * 0.2, check_margin + check_size * 0.5),
        (check_margin + check_size * 0.45, check_margin + check_size * 0.75),
        (check_margin + check_size * 0.8, check_margin + check_size * 0.25)
    ]
    
    # Draw thick checkmark
    for i in range(-8, 9):
        for j in range(-8, 9):
            offset_points = [(x + i, y + j) for x, y in check_points]
            draw.line(offset_points, fill='white', width=12)
    
    # Draw pie chart symbol (small)
    pie_center_x = size - size // 4
    pie_center_y = size // 4
    pie_radius = size // 12
    
    # Draw small pie chart
    draw.ellipse([pie_center_x - pie_radius, pie_center_y - pie_radius,
                 pie_center_x + pie_radius, pie_center_y + pie_radius],
                fill='#FFC107', outline='#FF8F00', width=2)
    
    # Draw pie slice
    draw.pieslice([pie_center_x - pie_radius, pie_center_y - pie_radius,
                  pie_center_x + pie_radius, pie_center_y + pie_radius],
                 start=0, end=90, fill='#FF5722')
    
    return img

def save_ios_icons(base_img):
    """Save iOS app icons in required sizes"""
    ios_sizes = [
        (20, "Icon-20.png"),
        (29, "Icon-29.png"),
        (40, "Icon-40.png"),
        (58, "Icon-58.png"),
        (60, "Icon-60.png"),
        (76, "Icon-76.png"),
        (80, "Icon-80.png"),
        (87, "Icon-87.png"),
        (120, "Icon-120.png"),
        (152, "Icon-152.png"),
        (167, "Icon-167.png"),
        (180, "Icon-180.png"),
        (1024, "Icon-1024.png")
    ]
    
    ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(ios_dir, exist_ok=True)
    
    for size, filename in ios_sizes:
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(ios_dir, filename))
        print(f"Created iOS icon: {filename} ({size}x{size})")

def save_android_icons(base_img):
    """Save Android app icons in required sizes"""
    android_sizes = [
        (36, "android/app/src/main/res/mipmap-ldpi/ic_launcher.png"),
        (48, "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"),
        (72, "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"),
        (96, "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"),
        (144, "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"),
        (192, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png")
    ]
    
    for size, filepath in android_sizes:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(filepath)
        print(f"Created Android icon: {filepath} ({size}x{size})")

def create_contents_json():
    """Create Contents.json for iOS AppIcon.appiconset"""
    contents = {
        "images": [
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-40.png", "scale": "2x"},
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-60.png", "scale": "3x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-58.png", "scale": "2x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-87.png", "scale": "3x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-80.png", "scale": "2x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-120.png", "scale": "3x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-120.png", "scale": "2x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-180.png", "scale": "3x"},
            {"size": "20x20", "idiom": "ipad", "filename": "Icon-20.png", "scale": "1x"},
            {"size": "20x20", "idiom": "ipad", "filename": "Icon-40.png", "scale": "2x"},
            {"size": "29x29", "idiom": "ipad", "filename": "Icon-29.png", "scale": "1x"},
            {"size": "29x29", "idiom": "ipad", "filename": "Icon-58.png", "scale": "2x"},
            {"size": "40x40", "idiom": "ipad", "filename": "Icon-40.png", "scale": "1x"},
            {"size": "40x40", "idiom": "ipad", "filename": "Icon-80.png", "scale": "2x"},
            {"size": "76x76", "idiom": "ipad", "filename": "Icon-76.png", "scale": "1x"},
            {"size": "76x76", "idiom": "ipad", "filename": "Icon-152.png", "scale": "2x"},
            {"size": "83.5x83.5", "idiom": "ipad", "filename": "Icon-167.png", "scale": "2x"},
            {"size": "1024x1024", "idiom": "ios-marketing", "filename": "Icon-1024.png", "scale": "1x"}
        ],
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }
    
    import json
    contents_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print(f"Created Contents.json for iOS")

if __name__ == "__main__":
    print("Creating Simple Task Manager app icons...")
    
    # Create base icon
    base_icon = create_app_icon()
    
    # Save for different platforms
    save_ios_icons(base_icon)
    save_android_icons(base_icon)
    create_contents_json()
    
    # Save original for reference
    base_icon.save("app_icon_1024.png")
    print("Created reference icon: app_icon_1024.png")
    
    print("\n✅ All app icons created successfully!")
    print("📱 iOS icons: ios/Runner/Assets.xcassets/AppIcon.appiconset/")
    print("🤖 Android icons: android/app/src/main/res/mipmap-*/")
