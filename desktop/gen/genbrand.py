from PIL import Image, ImageDraw, ImageFont, ImageChops

W,H=512,342
img=Image.new('1',(W,H),0)
d=ImageDraw.Draw(img)
ARIAL="/System/Library/Fonts/Supplemental/Arial Bold.ttf"
SFNS ="/System/Library/Fonts/SFNS.ttf"

def ctext(y,s,sz,path=ARIAL):
    f=ImageFont.truetype(path,sz); bb=d.textbbox((0,0),s,font=f)
    w=bb[2]-bb[0]
    d.text(((W-w)/2-bb[0],y),s,fill=1,font=f)

# double frame
d.rectangle([10,10,W-11,H-11],outline=1)
d.rectangle([14,14,W-15,H-15],outline=1)

# real Apple logo glyph (U+F8FF), rendered big then scaled+thresholded -> crisp solid
af=ImageFont.truetype(SFNS,240)
al=Image.new('L',(360,360),0); ImageDraw.Draw(al).text((20,20),"",fill=255,font=af)
al=al.crop(al.getbbox())
th=80; w,h=al.size; al=al.resize((int(w*th/h),th),Image.LANCZOS)
al=al.point(lambda p:255 if p>=110 else 0).convert('1')
img.paste(1,((W-al.width)//2,30),al)

ctext(150,"A/UX",88)
d.rectangle([150,250,W-150,252],fill=1)
ctext(262,"Release 3.1.1",26)
ctext(298,"Macintosh SE/30",20)

prev=img.resize((100,34)); px=prev.load()
print("\n".join("".join('#' if px[x,y] else ' ' for x in range(100)) for y in range(34)))
img.save('/tmp/fvwmbuild/auxbrand.xbm')
img.convert('L').resize((W*2,H*2),Image.NEAREST).save('/tmp/fvwmbuild/auxbrand_preview.png')
print("\nwrote auxbrand.xbm + preview, apple", al.size)
