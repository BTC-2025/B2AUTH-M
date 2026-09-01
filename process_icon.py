import os
from PIL import Image

image_path = r'C:\Users\RAVI KUMAR C\Desktop\b2auth\assets\Auth_img.png'

if os.path.exists(image_path):
    img = Image.open(image_path).convert('RGBA')
    
    # Create a solid white background image of 1024x1024
    size = 1024
    white_bg = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    
    # Resize original image preserving aspect ratio with padding
    img.thumbnail((size - 160, size - 160), Image.Resampling.LANCZOS)
    
    # Center the original image on the white background
    x = (size - img.width) // 2
    y = (size - img.height) // 2
    white_bg.paste(img, (x, y), img)
    
    # Save as RGB PNG
    final_img = white_bg.convert('RGB')
    final_img.save(image_path, 'PNG')
    print(f"Successfully processed {image_path} with a solid white background (1024x1024)!")
else:
    print(f"File not found: {image_path}")
