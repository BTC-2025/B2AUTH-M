import os
from PIL import Image

assets_dir = r"c:\Users\RAVI KUMAR C\Desktop\b2auth\assets"
src_path = os.path.join(assets_dir, "Auth_img.png")
padded_path = os.path.join(assets_dir, "app_icon_padded.png")

def process_icon():
    if not os.path.exists(src_path):
        print(f"File not found: {src_path}")
        return

    # Load original image
    img = Image.open(src_path).convert("RGBA")
    
    # Standard 512x512 Canvas for Android/iOS App Icon
    canvas_size = 512
    
    # Create solid white background canvas
    canvas = Image.new("RGB", (canvas_size, canvas_size), (255, 255, 255))
    
    # Calculate compact icon size (45% of canvas for elegant padding/safe zone)
    target_logo_size = int(canvas_size * 0.45)
    
    # Resize inner shield logo proportionally
    img.thumbnail((target_logo_size, target_logo_size), Image.Resampling.LANCZOS)
    
    # Center logo on white background canvas
    x = (canvas_size - img.width) // 2
    y = (canvas_size - img.height) // 2
    
    # Paste transparent logo onto white canvas using alpha mask
    canvas.paste(img, (x, y), img)
    
    # Save optimized images
    canvas.save(padded_path, "PNG")
    canvas.save(src_path, "PNG")
    print(f"Successfully processed app icon with white background and compact safe zone padding.")
    print(f"Saved: {src_path}")
    print(f"Saved: {padded_path}")

if __name__ == "__main__":
    process_icon()
