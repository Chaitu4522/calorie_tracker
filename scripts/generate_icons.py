#!/usr/bin/env python3
"""
Generate Android launcher icons for the Calorie Tracker app.
Run this script if ic_launcher.png files are missing.

Usage: python3 scripts/generate_icons.py
"""

import struct
import zlib
import os

def create_png(width, height, rgb_color, filepath):
    """Create a simple solid color PNG file."""
    r, g, b = rgb_color
    
    def png_chunk(chunk_type, data):
        chunk_len = struct.pack('>I', len(data))
        chunk_crc = struct.pack('>I', zlib.crc32(chunk_type + data) & 0xffffffff)
        return chunk_len + chunk_type + data + chunk_crc
    
    # PNG signature
    signature = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = png_chunk(b'IHDR', ihdr_data)
    
    # IDAT chunk (image data)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # filter byte
        for x in range(width):
            raw_data += bytes([r, g, b])
    
    compressed = zlib.compress(raw_data)
    idat = png_chunk(b'IDAT', compressed)
    
    # IEND chunk
    iend = png_chunk(b'IEND', b'')
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'wb') as f:
        f.write(signature + ihdr + idat + iend)

def main():
    # Get the script's directory to find project root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    
    # Teal color (matching the app theme: Colors.teal = #009688)
    teal = (0, 150, 136)
    
    # Icon sizes for each density
    icons = [
        (48, 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png'),
        (72, 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png'),
        (96, 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'),
        (144, 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png'),
        (192, 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'),
    ]
    
    print("Generating launcher icons...")
    
    for size, relative_path in icons:
        filepath = os.path.join(project_root, relative_path)
        create_png(size, size, teal, filepath)
        print(f"  Created {relative_path} ({size}x{size})")
    
    print("\nAll icons created successfully!")
    print("\nNote: These are placeholder icons (solid teal squares).")
    print("For a production app, replace them with proper designed icons.")

if __name__ == '__main__':
    main()
