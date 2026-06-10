#!/usr/bin/env python3
# Generate small, consistently-themed SimCity tool palette icons.
# Classic-SimCity aesthetic: flat themed background tile + simple white pictograph.
# Outputs: a PNG preview montage, and 18 XPM files for A/UX.

from PIL import Image, ImageDraw
import os

S = 32          # icon size (square)
OUT = "/tmp/icons"
os.makedirs(OUT, exist_ok=True)

# palette categories -> background colour
BG = {
    "res":   (60, 150, 70),    # green  - residential
    "com":   (60, 110, 190),   # blue   - commercial
    "ind":   (200, 160, 50),   # amber  - industrial
    "fire":  (200, 60, 50),    # red    - fire dept
    "query": (90, 130, 140),   # teal   - query
    "police":(50, 70, 150),    # navy   - police
    "wire":  (210, 175, 40),   # gold   - power line
    "dozer": (190, 110, 40),   # orange - bulldozer
    "rail":  (90, 95, 105),    # slate  - rail
    "road":  (110, 110, 115),  # grey   - road
    "chalk": (120, 80, 160),   # purple - chalk
    "eraser":(195, 90, 130),   # pink   - eraser
    "stadium":(70, 150, 90),   # green  - stadium
    "park":  (80, 160, 80),    # green  - park
    "seaport":(45, 120, 175),  # water  - seaport
    "coal":  (95, 80, 70),     # brown  - coal
    "nuclear":(80, 160, 60),   # radgreen - nuclear
    "airport":(70, 140, 190),  # sky    - airport
}

W = (245, 245, 250)   # white glyph
D = (30, 30, 35)      # dark detail

# tool order matching weditor.tcl indices 0..17
TOOLS = ["res","com","ind","fire","query","police",
         "wire","dozer","rail","road","chalk","eraser",
         "stadium","park","seaport","coal","nuclear","airport"]

def base(name, hi=False):
    bg = BG[name]
    if hi:
        # selected: brighten the tile so it reads as "active" (button also
        # goes -relief sunken), and keep the white glyph.
        bg = tuple(min(255, int(c * 1.0) + 55) for c in bg)
    img = Image.new("RGB", (S, S), bg)
    d = ImageDraw.Draw(img)
    # subtle bevel: light top/left, dark bottom/right
    light = tuple(min(255, c + 35) for c in bg)
    dark  = tuple(max(0,   c - 45) for c in bg)
    d.line([(0,0),(S-1,0)], fill=light)
    d.line([(0,0),(0,S-1)], fill=light)
    d.line([(0,S-1),(S-1,S-1)], fill=dark)
    d.line([(S-1,0),(S-1,S-1)], fill=dark)
    if hi:
        # bright selection ring just inside the edge
        ring = (255, 235, 90)
        d.rectangle([1,1,S-2,S-2], outline=ring)
        d.rectangle([2,2,S-3,S-3], outline=ring)
    return img, d

def house(d):              # residential: simple house
    d.polygon([(8,16),(16,8),(24,16)], fill=W)        # roof
    d.rectangle([10,16,22,25], fill=W)                # body
    d.rectangle([14,19,18,25], fill=BG["res"])        # door

def store(d):              # commercial: storefront with awning
    d.rectangle([8,12,24,25], fill=W)                 # building
    d.rectangle([8,12,24,16], fill=D)                 # awning band
    d.rectangle([11,18,15,25], fill=BG["com"])        # window
    d.rectangle([17,18,21,25], fill=BG["com"])        # window

def factory(d):            # industrial: factory + smokestack
    d.rectangle([8,16,24,25], fill=W)                 # base
    d.polygon([(8,16),(12,16),(12,20),(16,16),(16,20),(20,16),(20,25),(8,25)], fill=W)
    d.rectangle([20,9,23,25], fill=W)                 # stack
    d.ellipse([19,5,25,11], fill=D)                   # smoke

def flame(d):              # fire dept: flame
    d.polygon([(16,6),(21,16),(19,22),(13,22),(11,16)], fill=W)
    d.polygon([(16,13),(18,18),(16,22),(14,18)], fill=BG["fire"])

def magnify(d):            # query: magnifier
    d.ellipse([8,8,20,20], outline=W, width=3)
    d.line([(19,19),(25,25)], fill=W, width=3)

def shield(d):             # police: shield + star
    d.polygon([(16,6),(24,10),(24,17),(16,26),(8,17),(8,10)], fill=W)
    d.polygon([(16,11),(17.5,15),(22,15),(18,18),(20,22),(16,19.5),(12,22),(14,18),(10,15),(14.5,15)], fill=BG["police"])

def bolt(d):               # power line: lightning bolt
    d.polygon([(18,5),(10,18),(15,18),(13,27),(22,13),(17,13)], fill=W)

def dozer(d):              # bulldozer: blade + body
    d.rectangle([12,14,22,20], fill=W)                # body
    d.rectangle([9,12,11,22], fill=W)                 # blade
    d.ellipse([12,20,16,24], fill=D)                  # wheel
    d.ellipse([18,20,22,24], fill=D)                  # wheel

def rail(d):               # rail: track with ties
    d.line([(11,8),(11,25)], fill=W, width=2)
    d.line([(21,8),(21,25)], fill=W, width=2)
    for y in (10,15,20,24):
        d.line([(8,y),(24,y)], fill=W, width=2)

def road(d):              # road: lane with dashes
    d.rectangle([8,11,24,21], fill=W)
    d.rectangle([8,15,24,17], fill=BG["road"])
    for x in (9,14,19):
        d.rectangle([x,15,x+3,17], fill=W)

def chalk(d):             # chalk: pencil drawing line
    d.line([(8,24),(24,8)], fill=W, width=3)
    d.polygon([(22,6),(26,10),(24,12),(20,8)], fill=D)  # tip
    d.line([(7,25),(11,21)], fill=W, width=2)           # squiggle tail

def eraser(d):            # eraser: block
    d.polygon([(10,20),(20,10),(25,15),(15,25)], fill=W)
    d.polygon([(10,20),(15,25),(13,27),(8,22)], fill=D)

def stadium(d):           # stadium: oval bowl
    d.ellipse([6,10,26,22], fill=W)
    d.ellipse([11,13,21,19], fill=BG["stadium"])

def park(d):              # park: tree
    d.ellipse([9,7,23,21], fill=W)                    # foliage
    d.rectangle([15,18,17,26], fill=D)                # trunk

def seaport(d):           # seaport: anchor
    d.ellipse([14,6,18,10], outline=W, width=2)
    d.line([(16,9),(16,24)], fill=W, width=2)
    d.line([(10,18),(16,24)], fill=W, width=2)
    d.line([(22,18),(16,24)], fill=W, width=2)
    d.line([(11,16),(21,16)], fill=W, width=2)

def coal(d):              # coal power: stacks + smoke
    d.rectangle([8,18,24,25], fill=W)
    d.rectangle([11,10,15,18], fill=W)
    d.rectangle([18,10,22,18], fill=W)
    d.ellipse([10,5,16,11], fill=D)
    d.ellipse([17,5,23,11], fill=D)

def nuclear(d):          # nuclear: trefoil radiation
    cx, cy, r = 16, 16, 3
    d.ellipse([cx-r,cy-r,cx+r,cy+r], fill=W)
    import math
    for a in (90, 210, 330):
        a0 = math.radians(a-30); a1 = math.radians(a+30)
        d.pieslice([cx-11,cy-11,cx+11,cy+11], a-30, a+30, fill=W)
    d.ellipse([cx-3,cy-3,cx+3,cy+3], fill=BG["nuclear"])
    d.ellipse([cx-r,cy-r,cx+r,cy+r], fill=W)

def airport(d):          # airport: plane
    d.polygon([(16,5),(18,15),(16,26),(14,15)], fill=W)  # fuselage
    d.polygon([(4,16),(28,16),(18,12),(14,12)], fill=W)  # wings
    d.polygon([(11,24),(21,24),(18,21),(14,21)], fill=W) # tailplane

GLYPH = {
    "res":house, "com":store, "ind":factory, "fire":flame, "query":magnify,
    "police":shield, "wire":bolt, "dozer":dozer, "rail":rail, "road":road,
    "chalk":chalk, "eraser":eraser, "stadium":stadium, "park":park,
    "seaport":seaport, "coal":coal, "nuclear":nuclear, "airport":airport,
}

LABEL = {
    "res":"Residential","com":"Commercial","ind":"Industrial","fire":"Fire",
    "query":"Query","police":"Police","wire":"Power","dozer":"Bulldoze",
    "rail":"Rail","road":"Road","chalk":"Chalk","eraser":"Eraser",
    "stadium":"Stadium","park":"Park","seaport":"Seaport","coal":"Coal",
    "nuclear":"Nuclear","airport":"Airport",
}

icons = {}
for name in TOOLS:
    img, d = base(name)
    GLYPH[name](d)
    icons[name] = img
    img.save(os.path.join(OUT, "ic_%s.png" % name))
    # highlighted (selected) variant
    himg, hd = base(name, hi=True)
    GLYPH[name](hd)
    himg.save(os.path.join(OUT, "ic_%s_hi.png" % name))

# ---- preview montage: 6 cols x 3 rows, scaled 3x, with labels ----
from PIL import ImageFont
scale = 3
cols, rows = 6, 3
cell_w = S*scale + 16
cell_h = S*scale + 22
mont = Image.new("RGB", (cols*cell_w, rows*cell_h), (24,24,28))
md = ImageDraw.Draw(mont)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 13)
except Exception:
    font = ImageFont.load_default()
for i, name in enumerate(TOOLS):
    r, c = divmod(i, cols)
    x = c*cell_w + 8
    y = r*cell_h + 6
    big = icons[name].resize((S*scale, S*scale), Image.NEAREST)
    mont.paste(big, (x, y))
    md.text((x, y + S*scale + 3), LABEL[name], fill=(220,220,225), font=font)
mont.save("/tmp/icons_preview.png")
print("wrote", len(TOOLS), "icons +", "/tmp/icons_preview.png")
