from PIL import Image

QUALITY = 20
image = Image.open("passport.jpg")

# Check for EXIF metadata
try:
    for orientation in ExifTags.TAGS.keys():
        if ExifTags.TAGS[orientation] == 'Orientation':
            break

    exif = image._getexif()
    if exif is not None:
        orientation = exif.get(orientation, None)

        # Rotate the image based on the orientation
        if orientation == 3:
            image = image.rotate(180, expand=True)
        elif orientation == 6:
            image = image.rotate(270, expand=True)
        elif orientation == 8:
            image = image.rotate(90, expand=True)
except AttributeError:
    # If no EXIF metadata exists, do nothing
    pass

# Save the image as PDF
image.save("passport.pdf", "PDF", quality=QUALITY, optimize=True)


