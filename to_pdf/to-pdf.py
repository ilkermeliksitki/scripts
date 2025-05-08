#! /home/melik/Documents/projects/scripts/to_pdf/venv/bin/python3

import sys
import os
from PIL import Image
from PIL import ExifTags

if len(sys.argv) < 3:
    print("Usage: to-pdf <output_pdf_name> <image1> <image2> ...")
    sys.exit(1)

output_pdf_name = sys.argv[1]
image_paths = sys.argv[2:]

# check if the output ends with .pdf
if not output_pdf_name.lower().endswith('.pdf'):
    print("Error: The output file name must end with '.pdf'")
    sys.exit(1)

# list to store processed images
processed_images = []

for image_path in image_paths:
    if not os.path.exists(image_path):
        print(f"Error: The file '{image_path}' does not exist. Skipping...")
        continue

    try:
        image = Image.open(image_path)

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

        # convert image to RGB (PDF does not support images in RGBA mode)
        if image.mode != "RGB":
            image = image.convert("RGB")

        # addd the processed image to the list
        processed_images.append(image)
    except Exception as e:
        print(f"Error: Unable to process the image '{image_path}'. {e}")
        continue

# save all images to a single PDF
if processed_images:
    try:
        # save the first image and append the rest
        processed_images[0].save(output_pdf_name, "PDF", save_all=True, append_images=processed_images[1:])
        print(f"PDF saved as '{output_pdf_name}'")
    except Exception as e:
        print(f"Error: Unable to save the PDF. {e}")
else:
    print("No valid images were provided. PDF not created.")
