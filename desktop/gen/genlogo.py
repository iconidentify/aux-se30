from PIL import Image, ImageDraw, ImageFont, ImageChops
SFNS="/System/Library/Fonts/SFNS.ttf"
ARIAL="/System/Library/Fonts/Supplemental/Arial Bold.ttf"

W,Hc=140,140
img=Image.new('1',(W,Hc),0); d=ImageDraw.Draw(img)

# apple glyph, ~56 tall, centered top
af=ImageFont.truetype(SFNS,200)
al=Image.new('L',(300,300),0); ImageDraw.Draw(al).text((20,20),"",fill=255,font=af)
al=al.crop(al.getbbox())
th=54; w,h=al.size; al=al.resize((int(w*th/h),th),Image.LANCZOS)
al=al.point(lambda p:255 if p>=110 else 0).convert('1')
img.paste(1,((W-al.width)//2,8),al)

# "A/UX" wordmark below
f=ImageFont.truetype(ARIAL,52)
bb=d.textbbox((0,0),"A/UX",font=f); tw=bb[2]-bb[0]
d.text(((W-tw)//2-bb[0], 74),"A/UX",fill=1,font=f)

img=img.crop(img.getbbox())  # tight crop
# small uniform margin
m=4; canvas=Image.new('1',(img.width+2*m,img.height+2*m),0)
canvas.paste(img,(m,m))
canvas.save('/tmp/fvwmbuild/auxlogo.xbm')

prev=canvas.resize((60,int(60*canvas.height/canvas.width))); px=prev.load()
print("\n".join("".join('#' if px[x,y] else ' ' for x in range(prev.width)) for y in range(prev.height)))
print("logo size", canvas.size)
