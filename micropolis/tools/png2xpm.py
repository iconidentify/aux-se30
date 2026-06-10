#!/usr/bin/env python3
# Convert the generated PNG icons to XPM (small palette) for A/UX SimCity.
# Maps each tool to the filename weditor.tcl expects (icres.xpm, etc.).

from PIL import Image
import os

SRC = "/tmp/icons"
DST = "/tmp/icons_xpm"
os.makedirs(DST, exist_ok=True)

# generator name -> deployed xpm basename (matches weditor.tcl)
NAMEMAP = {
    "res":"icres", "com":"iccom", "ind":"icind", "fire":"icfire",
    "query":"icqry", "police":"icpol", "wire":"icwire", "dozer":"icdozr",
    "rail":"icrail", "road":"icroad", "chalk":"icchlk", "eraser":"icersr",
    "stadium":"icstad", "park":"icpark", "seaport":"icseap", "coal":"iccoal",
    "nuclear":"icnuc", "airport":"icairp",
}

# XPM colour-key characters (avoid quote/backslash)
KEYCHARS = ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "0123456789.+@#$%&*=-;:>,<^~")

def to_xpm(img, cname):
    img = img.convert("RGB")
    # quantize to <= 32 colours so XPM stays small and A/UX-friendly
    q = img.convert("P", palette=Image.ADAPTIVE, colors=32).convert("RGB")
    w, h = q.size
    px = q.load()
    colors = []
    cmap = {}
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c not in cmap:
                cmap[c] = len(colors)
                colors.append(c)
    ncol = len(colors)
    cpp = 1 if ncol <= len(KEYCHARS) else 2
    keys = {}
    for i, c in enumerate(colors):
        if cpp == 1:
            keys[c] = KEYCHARS[i]
        else:
            keys[c] = KEYCHARS[i // len(KEYCHARS)] + KEYCHARS[i % len(KEYCHARS)]
    lines = []
    lines.append("/* XPM */")
    lines.append("static char *%s[] = {" % cname)
    lines.append('"%d %d %d %d",' % (w, h, ncol, cpp))
    for c in colors:
        lines.append('"%s c #%02X%02X%02X",' % (keys[c], c[0], c[1], c[2]))
    for y in range(h):
        row = "".join(keys[px[x, y]] for x in range(w))
        comma = "," if y < h - 1 else ""
        lines.append('"%s"%s' % (row, comma))
    lines.append("};")
    return "\n".join(lines) + "\n"

count = 0
for gen, base in NAMEMAP.items():
    img = Image.open(os.path.join(SRC, "ic_%s.png" % gen))
    with open(os.path.join(DST, base + ".xpm"), "w") as f:
        f.write(to_xpm(img, base))
    count += 1
    himg = Image.open(os.path.join(SRC, "ic_%s_hi.png" % gen))
    with open(os.path.join(DST, base + "hi.xpm"), "w") as f:
        f.write(to_xpm(himg, base + "hi"))
    count += 1
print("wrote", count, "xpm files to", DST)
