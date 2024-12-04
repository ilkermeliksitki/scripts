import cv2
import numpy as np

# load the image
image = cv2.imread("diploma.png")

# create a matrix of ones and multiply by the desired brightness factor
# positive to brighten, negative to darken
brightness_factor = 35  
bright_image = cv2.add(image, np.ones(image.shape, dtype=np.uint8) * brightness_factor)

# save the image
cv2.imwrite("diploma_bright.png", bright_image)

