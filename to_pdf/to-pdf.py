#! /home/melik/Documents/projects/scripts/to_pdf/venv/bin/python3

import sys
import os
from PIL import Image
from PIL import ExifTags

if len(sys.argv) != 3:
    print("Usage: to-pdf <image_path> <output_pdf_name>")
    sys.exit(1)

image_path = sys.argv[1]
output_pdf_name = sys.argv[2]

# check if the input image exists
if not os.path.exists(image_path):
    print(f"Error: The file '{image_path}' does not exist.")
    sys.exit(1)

# open the image
try:
    image = Image.open(image_path)
except Exception as e:
    print(f"Error: Unable to open the image. {e}")
    sys.exit(1)

# check for EXIF metadata and handle orientation
try:
    for orientation in ExifTags.TAGS.keys():
        if ExifTags.TAGS[orientation] == 'Orientation':
            break

    exif = image._getexif()
    if exif is not None:
        orientation = exif.get(orientation, None)

        # rotate the image based on the orientation
        if orientation == 3:
            image = image.rotate(180, expand=True)
        elif orientation == 6:
            image = image.rotate(270, expand=True)
        elif orientation == 8:
            image = image.rotate(90, expand=True)
except AttributeError:
    # no EXIF metadata; do nothing
    pass

# save the image as a PDF
try:
    image.save(output_pdf_name, "PDF")
    print(f"PDF saved as '{output_pdf_name}'")
except Exception as e:
    print(f"Error: Unable to save the PDF. {e}")
    sys.exit(1)
