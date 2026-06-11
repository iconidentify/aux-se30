#!/usr/bin/env python3
# Render a clean, anti-aliased "SimCity" wordmark (simcitybig.xpm) for the
# Welcome / About screens - big-S/big-C styling, blue with depth, composited on
# the Tk window gray (#B0B0B0) so it blends with no box.  Rendered at 3x and
# downscaled for crisp edges, then quantized to 16 colours for the depth-8
# shared colormap (and the Maxis Tk -bitmap loader).
from PIL import Image, ImageDraw, ImageFont
from png2xpm import to_xpm

GRAY = (176,176,176)            # #B0B0B0 - the colour the original logo uses
BLUE = (34,38,170); DK = (12,14,90); HI = (150,170,255)

def font(sz):
    for f in ("/System/Library/Fonts/Supplemental/Arial Black.ttf",
              "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
              "/System/Library/Fonts/Supplemental/Arial.ttf"):
        try: return ImageFont.truetype(f, sz)
        except Exception: pass
    return ImageFont.load_default()

parts = [("S",66),("im",46),("C",66),("ity",46)]
S = 3; W, H = 300, 80
img = Image.new("RGB", (W*S, H*S), GRAY)
d = ImageDraw.Draw(img)
fonts = {sz: font(sz*S) for _, sz in parts}
widths = [d.textbbox((0,0), t, font=fonts[sz])[2] for t, sz in parts]
cx = (W*S - sum(widths)) // 2
baseline = int(H*S*0.74)
for (t, sz), w in zip(parts, widths):
    f = fonts[sz]; asc, _ = f.getmetrics(); y = baseline - asc
    for dx, dy in [(-2,-2),(2,2),(2,-2),(-2,2),(0,3*S//2),(3*S//2,0)]:
        d.text((cx+dx, y+dy), t, fill=DK, font=f)
    d.text((cx-1, y-2), t, fill=HI, font=f)
    d.text((cx, y), t, fill=BLUE, font=f)
    cx += w
img = img.resize((W, H), Image.LANCZOS)
q = img.quantize(colors=16, dither=Image.NONE).convert("RGB")
q.save("simcitybig.png")
open("simcitybig.xpm","w").write(to_xpm(q, "simcitybig"))
print("simcitybig.xpm", q.size, "colors", len(set(q.getdata())))
