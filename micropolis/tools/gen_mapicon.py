#!/usr/bin/env python3
# Generate the editor's mini-map icon (ic mapicon.xpm) - a small, San-Francisco
# -ish peninsula in the overall-map palette.  Clicking it opens the Map window.
# Output is a <=8 colour XPM so the Maxis Tk -bitmap loader accepts it.
from PIL import Image, ImageDraw
from png2xpm import to_xpm

W, H = 40, 47
WATER = (74, 120, 176); LAND = (200, 170, 120); GREEN = (70, 160, 70)
CITY = (120, 120, 120); ROAD = (225, 225, 225); FRM = (40, 40, 40)

img = Image.new("RGB", (W, H), WATER)
d = ImageDraw.Draw(img)
land = [(13,3),(22,2),(31,5),(36,12),(37,22),(35,31),(36,41),(30,44),
        (20,43),(15,38),(17,31),(12,25),(15,17),(11,10)]
d.polygon(land, fill=LAND)
d.ellipse([15,6,26,16], fill=GREEN)
d.ellipse([24,27,34,38], fill=GREEN)
d.ellipse([14,29,21,36], fill=GREEN)
for (x,y) in [(28,10),(31,13),(27,16),(30,18),(33,21),(28,22),(31,25),(26,20),(29,31),(32,34)]:
    d.rectangle([x,y,x+1,y+1], fill=CITY)
d.line([(18,9),(33,22)], fill=ROAD)
d.line([(20,39),(34,29)], fill=ROAD)
d.rectangle([0,0,W-1,H-1], outline=FRM)

PAL = [WATER, LAND, GREEN, CITY, ROAD, FRM]
p = Image.new("P", (1,1)); flat = []
for c in PAL: flat += list(c)
flat += [0,0,0]*(256-len(PAL)); p.putpalette(flat)
q = img.convert("RGB").quantize(palette=p, dither=Image.NONE).convert("RGB")
q.save("mapicon.png")
open("mapicon.xpm","w").write(to_xpm(q, "mapicon"))
print("mapicon.xpm", q.size, "colors", len(set(q.getdata())))
