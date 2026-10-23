from __future__ import annotations

import json
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance

ROOT=Path(__file__).resolve().parents[1]
MAPS=ROOT/"assets/maps"
STORY=MAPS/"story"
TEMPLATES=[
    Image.open(MAPS/"campaign_graveyard.png").convert("RGB"),
    Image.open(MAPS/"campaign_swamp.png").convert("RGB"),
    Image.open(MAPS/"campaign_chapel.png").convert("RGB"),
    Image.open(MAPS/"campaign_canyon.png").convert("RGB"),
    Image.open(MAPS/"campaign_hatchery.png").convert("RGB"),
    Image.open(MAPS/"campaign_mine.png").convert("RGB"),
]
INK=(21,29,40); EDGE=(31,42,55); GOLD=(208,176,105); PAPER=(226,207,155)
THEME_SOURCE={"grave":0,"pine":0,"swamp":1,"village":2,"orchard":4,"chapel":2,"canyon":3,"quarry":3,"rail":5,"tunnel":5,"greenhouse":4,"camp":3,"canal":1,"town":2,"mine":5}
ACCENTS={"grave":(94,105,76),"pine":(62,84,61),"swamp":(43,92,87),"village":(126,103,69),"orchard":(105,119,61),"chapel":(118,82,123),"canyon":(159,87,59),"quarry":(134,127,110),"rail":(116,83,60),"tunnel":(69,85,110),"greenhouse":(58,114,69),"camp":(157,81,53),"canal":(50,113,120),"town":(135,97,66),"mine":(79,75,88)}

def rect(d,box,fill,outline=INK,width=4):d.rectangle(tuple(int(v) for v in box),fill=fill,outline=outline,width=width)

def tomb(d,x,y,rng):
    d.ellipse((x-38,y+22,x+42,y+42),fill=(37,43,39))
    d.polygon([(x-30,y+8),(x-30,y-54),(x-15,y-73),(x+16,y-73),(x+31,y-53),(x+31,y+8)],fill=(114,122,119),outline=INK)
    d.line((x-22,y-50,x-12,y-61,x+11,y-64),fill=(172,178,169),width=5)
    d.line((x+20,y-49,x+9,y-23,x+17,y-11),fill=(75,83,86),width=4)
    d.line((x-16,y-35,x+13,y-35),fill=(69,76,80),width=4)
    d.line((x-13,y-23,x+7,y-23),fill=(83,89,91),width=3)

def bare_tree(d,x,y):
    d.line((x,y,x+3,y-128),fill=INK,width=25);d.line((x,y,x+3,y-126),fill=(94,62,46),width=16)
    branches=[((-1,-75),(-53,-123)),((1,-85),(48,-130)),((0,-100),(-25,-153)),((2,-110),(34,-161)),((0,-59),(62,-91))]
    for a,b in branches:
        d.line((x+a[0],y+a[1],x+b[0],y+b[1]),fill=INK,width=15)
        d.line((x+a[0],y+a[1],x+b[0],y+b[1]),fill=(105,67,49),width=8)

def lily(d,x,y,r):
    d.ellipse((x-r,y-r*.35,x+r,y+r*.35),fill=(20,43,48),outline=INK,width=4)
    d.ellipse((x-r+5,y-r*.35+4,x+r-5,y+r*.35-4),fill=(42,91,81),outline=(78,113,88),width=3)
    d.polygon([(x,y),(x+r*.34,y-r*.27),(x+r*.18,y+2)],fill=(20,43,48))

def bench(d,x,y,broken=False):
    color=(114,69,45)
    rect(d,(x-72,y-34,x+70,y-10),color,INK,6)
    rect(d,(x-72,y-48,x+70,y-39),(139,86,51),INK,5)
    d.line((x-48,y-8,x-54,y+36),fill=INK,width=11);d.line((x+49,y-8,x+57,y+36),fill=INK,width=11)
    d.line((x-61,y-26,x+57,y-26),fill=(177,119,69),width=3)
    if broken:d.line((x+4,y-48,x-17,y-24,x+5,y-10),fill=(43,34,33),width=6)

def egg(d,x,y,r,cracked=False):
    d.ellipse((x-r,y-r*1.25,x+r,y+r*1.25),fill=(220,174,100),outline=INK,width=6)
    d.ellipse((x-r+10,y-r,x+2,y+3),fill=(246,215,151))
    if cracked:
        d.line((x-4,y-r*.4,x+5,y-r*.1,x-5,y+r*.15,x+7,y+r*.44),fill=(111,43,50),width=5)
        d.ellipse((x-6,y-9,x+7,y+5),fill=(178,44,65),outline=INK,width=3)

def crate(d,x,y,mark=False):
    rect(d,(x-48,y-52,x+48,y+22),(122,80,49),INK,6)
    d.line((x-39,y-43,x+39,y+14),fill=(72,49,38),width=7);d.line((x+39,y-43,x-39,y+14),fill=(72,49,38),width=7)
    d.line((x-40,y-39,x+39,y-39),fill=(176,128,77),width=4)
    if mark:
        d.ellipse((x-15,y-25,x+15,y+5),fill=(159,39,65),outline=INK,width=4)
        d.line((x,y-18,x,y-2),fill=(239,192,79),width=4)

def minecart(d,x,y):
    rect(d,(x-75,y-47,x+75,y+4),(105,68,47),INK,7)
    rect(d,(x-66,y-42,x+66,y-5),(134,86,49),INK,4)
    for bx in (x-48,x-15,x+22,x+53):d.line((bx,y-35,bx+13,y-12),fill=(74,49,38),width=5)
    for wx in (x-48,x+49):
        d.ellipse((wx-15,y-7,wx+15,y+23),fill=(60,67,70),outline=INK,width=5)
        d.ellipse((wx-6,y+2,wx+6,y+14),fill=(152,144,115))

def pipes(d,x,y):
    d.line((x-110,y,x+80,y),fill=INK,width=24);d.line((x-110,y-2,x+80,y-2),fill=(102,120,124),width=13)
    d.line((x+78,y,x+78,y-75),fill=INK,width=24);d.line((x+78,y-2,x+78,y-73),fill=(128,141,137),width=13)
    for bx in (x-65,x+5,x+60):
        rect(d,(bx-9,y-14,bx+9,y+14),(82,91,94),INK,3)
        d.ellipse((bx-18,y-18,bx+18,y+18),outline=(172,178,162),width=3)

def add_scene_detail(im,theme,stage,interior,rng):
    # Preserve the original hand-pixeled scene as authored. The game draws its
    # animated clue marker and story set pieces separately; avoid flat overlays.
    return

def palette_variant(im, theme, stage):
    color=ACCENTS[theme]
    # Restrained wash keeps the source artwork's value groups and crisp outlines.
    overlay=Image.new("RGB",im.size,color)
    im=Image.blend(im,overlay,0.025+(stage%3)*0.008)
    if stage%4==2:im=ImageEnhance.Brightness(im).enhance(0.96)
    elif stage%4==3:im=ImageEnhance.Brightness(im).enhance(1.03)
    return ImageEnhance.Contrast(im).enhance(1.015)

def main():
    chapters=[
        ("沉土墓园","第1区 · 搜索墓园","grave",False,
         "爷爷的旧账本：‘墓园下面有东西在挖土。若你看见红色的心脏，千万别把它带回牧场。’\n\n墓穴通道通向沼泽。",
         (640,570),(1160,620),(980,210),3,2400),
        ("腐水浅滩","第2区 · 穿过沼泽","swamp",False,
         "摆渡人的字条：‘水里的骨头会跟着船底走。礼拜堂的人知道这种东西从哪里来。’\n\n找到通往山谷的路。",
         (830,570),(1160,620),(980,210),4,3200),
        ("山谷礼拜堂","第3区 · 搜查旧礼拜堂","chapel",True,
         "牧师的记录：爷爷曾把矿井里挖出的寄生虫核心带回镇上。教堂敲钟后，死去的动物开始活动。\n\n峡谷里的旧矿车还能运行。",
         (640,555),(1160,620),(980,210),4,4200),
        ("断脊峡谷","第4区 · 沿矿车轨道前进","canyon",False,
         "矿工留言：‘升降机下面有一条旧矿道。我们把炸药留在实验温室，别靠近红色的根。’\n\n去温室找炸药。",
         (640,570),(1160,620),(980,210),4,5600),
        ("研究温室","第5区 · 取回八根炸药","greenhouse",False,
         "实验记录：八根雷管可以摧毁矿井深处的寄生虫之心。核心会保护守门怪物，先清掉它，再点燃炸药。\n\n炸药已找到，进入矿井。",
         (640,570),(1160,620),(980,210),5,7200),
        ("寄生虫矿井","第6区 · 摧毁寄生虫之心","mine",False,
         "爷爷最后的字条：‘我以为能控制它。我错了。把核心毁掉，别让它再回到地面。’\n\n击败守门怪物，然后靠近核心安装炸药。",
         (640,430),(1150,150),(950,205),5,10000),
    ]
    raw=[]
    for stage,(title,subtitle,theme,interior,note,note_point,exit_point,heart,count,reward) in enumerate(chapters):
        TEMPLATES[THEME_SOURCE[theme]].save(STORY/f"campaign_{stage:02d}.png",optimize=True)
        raw.append({"stage":stage,"chapter":stage+1,"title":title,"subtitle":subtitle,"note":note,
                    "theme":theme,"interior":interior,"entry":[90,630],"exit":list(exit_point),
                    "note_point":list(note_point),"heart":list(heart),"props":[],"collisions":[],
                    "enemy_count":count,"enemy_kind":stage,"reward":reward})
    for old in STORY.glob("campaign_[0-9][0-9].png"):
        if int(old.stem[-2:])>=len(chapters):
            old.unlink()
            sidecar=old.with_suffix(old.suffix+".import")
            if sidecar.exists():sidecar.unlink()
    (STORY/"campaign_layouts.json").write_text(json.dumps(raw,ensure_ascii=False,indent=2),encoding="utf-8")
    print("rebuilt a six-area campaign from six distinct authored backgrounds")

if __name__=="__main__":main()
