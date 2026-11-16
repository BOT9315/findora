import os
from PIL import Image

src_img_path = r"C:\Users\akrk0\.gemini\antigravity\brain\ae22de00-d7e9-4477-b26b-8a96a4fb50d3\findora_orbit_app_icon_1794060202055.jpg"
project_root = r"C:\Users\akrk0\.gemini\antigravity\scratch\find_my_stuff_ai"

img = Image.open(src_img_path).convert("RGBA")

# 1. Save branding assets
branding_dir = os.path.join(project_root, "assets", "branding")
os.makedirs(branding_dir, exist_ok=True)

img_1024 = img.resize((1024, 1024), Image.Resampling.LANCZOS)
img_1024.save(os.path.join(branding_dir, "findora_orbit.png"), "PNG")

img_512 = img.resize((512, 512), Image.Resampling.LANCZOS)
img_512.save(os.path.join(branding_dir, "findora_orbit_512.png"), "PNG")

img_256 = img.resize((256, 256), Image.Resampling.LANCZOS)
img_256.save(os.path.join(branding_dir, "findora_orbit_256.png"), "PNG")

# 2. Android mipmaps
android_res = os.path.join(project_root, "android", "app", "src", "main", "res")
android_densities = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, size in android_densities.items():
    target_dir = os.path.join(android_res, folder)
    os.makedirs(target_dir, exist_ok=True)
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(os.path.join(target_dir, "ic_launcher.png"), "PNG")

# 3. iOS appiconset
ios_icons_dir = os.path.join(project_root, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.exists(ios_icons_dir):
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in ios_sizes.items():
        resized = img.resize((int(size), int(size)), Image.Resampling.LANCZOS)
        resized.save(os.path.join(ios_icons_dir, filename), "PNG")

print("Successfully generated all FINDORA ORBIT branding & icon assets!")
