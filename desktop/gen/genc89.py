# genc89.py - convert the C89 Summer logo PNG to a 1-bit XBM for auxsaver.
# Source art is the project's own C89 Summer logo (white art on black).
from PIL import Image
SRC = "DOPEc89bwimage.png"   # the source logo (not in repo)
im = Image.open(SRC).convert('L')
w = 256; h = int(im.height * w / im.width)
im = im.resize((w, h), Image.LANCZOS)
im.point(lambda p: 255 if p >= 96 else 0).convert('1').save("../assets/c89logo.xbm")
print("wrote c89logo.xbm", (w, h))
