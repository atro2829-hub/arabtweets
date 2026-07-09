#!/usr/bin/env python3
"""Generate monochrome black/white AdenTweet app icon for all densities."""
from PIL import Image, ImageDraw, ImageFont
import os

SIZES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}

def create_mono_icon(size):
    """Black rounded square with white 'A' lettermark - like X."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    radius = int(size * 0.22)

    # Draw rounded rect background (black)
    for y in range(size):
        for x in range(size):
            in_rect = True
            if (x < radius or x > size - radius - 1) and (y < radius or y > size - radius - 1):
                corners = [(radius, radius), (size-radius-1, radius), (radius, size-radius-1), (size-radius-1, size-radius-1)]
                for cx, cy in corners:
                    if (abs(x-cx)**2 + abs(y-cy)**2) > radius**2:
                        in_rect = False; break
            if in_rect:
                img.putpixel((x, y), (0, 0, 0, 255))

    # Draw white 'A'
    font_size = int(size * 0.55)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
    except:
        font = ImageFont.load_default()

    text = "A"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
    tx = (size - tw) / 2 - bbox[0]
    ty = (size - th) / 2 - bbox[1] - int(size * 0.02)
    draw.text((tx, ty), text, fill=(255, 255, 255, 255), font=font)
    return img

base = "/home/z/my-project/arabtweets/android/app/src/main/res"
for density, size in SIZES.items():
    icon = create_mono_icon(size)
    out_dir = os.path.join(base, f"mipmap-{density}")
    os.makedirs(out_dir, exist_ok=True)
    icon.save(os.path.join(out_dir, "ic_launcher.png"))

    # Round version
    round_icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size-1, size-1], fill=255)
    round_icon.paste(icon, (0, 0), mask)
    round_icon.save(os.path.join(out_dir, "ic_launcher_round.png"))

# Flutter asset icon
flutter_icon = create_mono_icon(1024)
os.makedirs("/home/z/my-project/arabtweets/assets/icons", exist_ok=True)
flutter_icon.save("/home/z/my-project/arabtweets/assets/icons/app_icon.png")

# Transparent version (white A on transparent bg) for splash/internal
transparent_size = 288
timg = Image.new('RGBA', (transparent_size, transparent_size), (0, 0, 0, 0))
tdraw = ImageDraw.Draw(timg)
try:
    tfont = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(transparent_size * 0.7))
except:
    tfont = ImageFont.load_default()
bbox = tdraw.textbbox((0, 0), "A", font=tfont)
tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
tx = (transparent_size - tw) / 2 - bbox[0]
ty = (transparent_size - th) / 2 - bbox[1]
tdraw.text((tx, ty), "A", fill=(255, 255, 255, 255), font=tfont)
timg.save("/home/z/my-project/arabtweets/assets/icons/app_icon_transparent.png")

print("All monochrome icons generated!")