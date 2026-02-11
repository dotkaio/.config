from PIL import Image
import pytesseract
import fitz
from io import BytesIO

# Reload PDF
pdf_path = "file.pdf"
doc = fitz.open(pdf_path)
page = doc[0]

# Extract image from the page
xref = page.get_images(full=True)[0][0]
image_bytes = doc.extract_image(xref)["image"]
image = Image.open(BytesIO(image_bytes))

# Run OCR
raw_text = pytesseract.image_to_string(image)

# Clean and split into names list
names = [line.strip() for line in raw_text.split('\n') if line.strip()]
names
