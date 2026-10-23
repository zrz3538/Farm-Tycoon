from pathlib import Path
import random
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
formal=Path(r"D:\farm-tycoon\assets\maps\corn_house.png")
source=Image.open(formal if formal.exists() else ROOT/"assets/maps/corn_house.png").convert("RGB")
canvas=source.copy();rng=random.Random(4417)

def is_grass(c):
    r,g,b=c
    return g>70 and g>r*.88 and g>b*1.18

def local_grass(y):
    samples=[source.getpixel((x,max(0,min(719,y)))) for x in range(0,1280,8)]
    samples=[c for c in samples if is_grass(c)]
    if not samples:return (111,143,79)
    samples.sort(key=lambda c:sum(c))
    return samples[len(samples)//2]

def clear_to_grass(box):
    x0,y0,x1,y1=box;d=ImageDraw.Draw(canvas)
    for y in range(y0,y1,2):
        base=local_grass(y)
        for x in range(x0,x1,2):
            jitter=rng.choice([-5,-2,0,0,2,5]);c=tuple(max(0,min(255,v+jitter)) for v in base)
            d.rectangle((x,y,x+1,y+1),fill=c)
    for _ in range(max(8,(x1-x0)*(y1-y0)//9000)):
        x=rng.randrange(x0+5,x1-5);y=rng.randrange(y0+5,y1-5);c=local_grass(y)
        d.rectangle((x,y,x+3,y+7),fill=tuple(max(0,v-35) for v in c));d.rectangle((x+4,y+2,x+6,y+7),fill=tuple(max(0,v-22) for v in c))

def cut_object(box):
    crop=source.crop(box).convert("RGBA");alpha=Image.new("L",crop.size,0);ap=alpha.load();cp=crop.load()
    for y in range(crop.height):
        for x in range(crop.width):ap[x,y]=0 if is_grass(cp[x,y][:3]) else 255
    crop.putalpha(alpha);return crop

def shrink(box,scale=.70):
    obj=cut_object(box);clear_to_grass(box);size=(int(obj.width*scale),int(obj.height*scale));obj=obj.resize(size,Image.Resampling.NEAREST)
    x=box[0]+(box[2]-box[0]-size[0])//2;y=box[3]-size[1];canvas.paste(obj,(x,y),obj)

for rect in [(62,440,335,670),(325,455,610,675),(815,440,1090,680)]:shrink(rect)
canvas.save(ROOT/"assets/maps/corn_house.png",optimize=True)
