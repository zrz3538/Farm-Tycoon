from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "maps" / "story"
SIZE = (640, 360)

CHAPTERS = [
    ("沉土墓园", "守墓人小屋", "祖父留下的账本第一页写着：牛群生病前，他曾从旧矿井带回一块会跳动的红石。那晚以后，墓地里的动物开始自己刨土。"),
    ("松针巡路", "猎人木屋", "猎人的字条：我跟踪过那些骨头。它们不怕月光，只怕火药和持续的枪声。它们把猎物拖向北面的沼泽。"),
    ("腐水浅滩", "摆渡人棚屋", "摆渡人的航行记录：水下不是树根，是一张覆盖整个山谷的血管。每天午夜，血管都向矿山方向收缩一次。"),
    ("雾桥村口", "废弃诊所", "医生的病历：寄生物先夺走饥饿感，再控制脊椎。完全感染后只剩骨骼也能活动。切断头部并不能立刻停止它。"),
    ("哭泣果园", "果农地窖", "果农给女儿的信：树上的果子全烂了。我把炸药藏进地窖最深处，但雷管被矿工带走。别再回来。"),
    ("旧礼拜道", "山谷礼拜堂", "牧师的忏悔：我们以为那颗心能治病。祖父最先听见它说话，也是他把祭坛封进矿井。钟声会让它的仆从短暂停顿。"),
    ("断脊峡谷", "升降机房", "维修记录：升降机只能下降，制动器已经被骨刺顶坏。备用线路通向采石场，那里堆着第一批被感染的巨兽。"),
    ("白石采场", "工头办公室", "工头名单上有三十七个名字，最后一行是祖父。旁边写着：所有人都听见了心跳，但只有他愿意继续向下挖。"),
    ("骨轨货场", "铁路信号房", "调度电报：第七码头的矿车无人驾驶却准点返回，车厢里装满动物骨骼。关闭东线，绝不能让列车驶向牧场。"),
    ("红灯隧道", "轨道维修站", "维修员的录音稿：墙里的东西会模仿敲击声。三短一长不是同伴的信号。听到回应时，立刻熄灯趴下。"),
    ("孵化温室", "研究温室", "研究笔记：寄生物会选择适合的骨架重组身体。鹿负责追踪，鳄鱼守水道，恐龙骨架则被用于守卫核心。"),
    ("灰烬营地", "爆破仓库", "爆破员清单：木箱里有八根炸药，缺少点火线。雷管被守门怪带去了冷却泵房。把八根同时引爆，核心才无法再生。"),
    ("冷却渠岸", "地下泵房", "泵房值班表：停止冷却后，寄生虫之心会过热九十秒。那是安装炸药的唯一窗口，也会唤醒矿井里最大的骨架。"),
    ("祖父矿镇", "祖父旧居", "祖父最后的信：我不是在供奉它，我在拖延它醒来。若你读到这里，说明封印失败。带走桌下的雷管，别相信从墙里传来的我的声音。"),
    ("心脏矿坑", "地下祭坛", "最后一页：八根炸药围住心室，连接雷管，点火后不要回头。牧场会活下来，但你必须亲手结束祖父留下的错误。"),
]

THEMES = [
    ("grave", "#61714a", "#897657"), ("pine", "#435a46", "#76694d"),
    ("swamp", "#3b5951", "#667047"), ("village", "#6f704f", "#907251"),
    ("orchard", "#5d7147", "#8a6945"), ("chapel", "#50475a", "#746150"),
    ("canyon", "#71483c", "#9a6747"), ("quarry", "#65645f", "#8b7e68"),
    ("rail", "#4e5249", "#715d48"), ("tunnel", "#343842", "#5d4d43"),
    ("greenhouse", "#4c654f", "#79634d"), ("camp", "#655344", "#887056"),
    ("canal", "#3c5b59", "#61766b"), ("town", "#59564c", "#806a51"),
    ("mine", "#2f3038", "#57493d"),
]

BUILDINGS = ["keeper", "hunter", "ferry", "clinic", "cellar", "chapel", "lift", "office", "signal", "workshop", "lab", "store", "pump", "cabin", "altar"]
INTERIOR_ADDENDA = [
    "守墓人的桌下压着一张矿区通行证，背面画着祖父带领矿工搬运红色矿石的路线。最早失踪的不是人，而是墓园附近的狗。",
    "墙上的猎物名单被全部划掉，最后留下的脚印从窗边一直延伸到沼泽。猎人把银弹留给后来者，自己却没能走出去。",
    "棚屋地板刻着退潮时间。摆渡人发现骨架只在血管收缩时过河，所以用一条腐木筏反复运送幸存者。",
    "诊所药柜里没有药，只剩一排拔出的牙齿。医生确认感染通过牛奶扩散，并在关门前烧掉了市场的进货记录。",
    "地窖里摆着八个空位，原本存放炸药。墙上箭头指向山谷礼拜堂，说明雷管曾交给牧师保管。",
    "祭台下藏着祖父的旧照片。他站在矿井入口，身后的人影没有脸。丧钟上的裂缝正好组成矿区地图。",
    "控制台仍有余电。下降记录显示升降机曾在无人操作时连续运行七次，每次都从深处带回更多骨头。",
    "工头办公室的窗户被从里面钉死。薪资册证明祖父一直在付钱让矿工保持沉默，而最后一笔钱寄给了你的父亲。",
    "信号灯操作规程被改写：红灯不是停车，而是警告驾驶员闭眼。骨列车会模仿亲人的声音引人登车。",
    "维修站里留下半截电报。矿工切断东线后，寄生物开始沿电缆爬行，并学会利用灯光引诱活人。",
    "培养槽编号对应不同骨架：犬、猪、鹿、马、鳄鱼、迅猛龙、三角龙与暴龙。研究员称它们为核心的临时身体。",
    "爆破仓库的木箱完好，里面正好八根炸药。清单提醒：单根爆炸只会让心脏分裂，必须用同一只雷管同时点火。",
    "泵房手册写明冷却系统一停，九十秒后核心会暴露。旁边的血迹一直通向祖父矿镇，雷管也被带去了那里。",
    "祖父在床板下藏着雷管与道歉信。他承认用自己的声音喂养核心多年，只为让它忽略地面上的家人。",
    "祭坛石板给出最后步骤：关闭冷却、围放八根炸药、接入雷管、点火后沿废弃通风井撤离。心跳已经开始加速。",
]


def rgb(value: str):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, amount):
    return tuple(max(0, min(255, int(v + amount))) for v in c)


def px_rect(draw, box, fill, outline=None, width=1):
    draw.rectangle(tuple(int(v) for v in box), fill=fill, outline=outline, width=width)


def tree(draw, x, y, theme, rng, scale=1.0):
    trunk = rgb("#594132")
    leaf = rgb("#304e3c") if theme not in ("canyon", "mine", "tunnel") else rgb("#4a3430")
    w, h = int(9 * scale), int(28 * scale)
    px_rect(draw, (x-w//2, y-h, x+w//2, y), trunk, rgb("#17242a"), 2)
    for ox, oy, rad in [(-14,-31,17),(4,-39,20),(18,-26,16),(-2,-20,20)]:
        r=int(rad*scale); cx=int(x+ox*scale); cy=int(y+oy*scale)
        draw.rectangle((cx-r,cy-r,cx+r,cy+r),fill=leaf,outline=rgb("#17242a"),width=3)
        px_rect(draw,(cx-r+5,cy-r+5,cx+2,cy-2),shade(leaf,20))


def tomb(draw, x, y, rng):
    stone=rgb("#8d9187"); ink=rgb("#26313a")
    px_rect(draw,(x-13,y-34,x+13,y),stone,ink,3)
    px_rect(draw,(x-17,y-5,x+17,y+2),shade(stone,-12),ink,2)
    px_rect(draw,(x-6,y-25,x+6,y-22),shade(stone,-28))
    draw.line((x+8,y-32,x+2,y-18,x+8,y-8),fill=shade(stone,-35),width=2)


def rock(draw, x, y, rng, scale=1.0):
    r=int(15*scale); c=rgb("#686a64")
    pts=[(x-r,y),(x-r+4,y-r+5),(x+3,y-r),(x+r,y-r+7),(x+r+3,y),(x+7,y+7),(x-r+5,y+6)]
    draw.polygon(pts,fill=c,outline=rgb("#222a31"))
    draw.line((x-r+6,y-r+3,x+2,y-r+7),fill=shade(c,30),width=3)


def building(draw, x, y, kind, color):
    wall=shade(color,25); dark=rgb("#1c2630"); roof=rgb("#573842") if kind not in ("lab","pump") else rgb("#40505a")
    px_rect(draw,(x-55,y-58,x+55,y+18),wall,dark,4)
    draw.polygon([(x-65,y-58),(x,y-105),(x+65,y-58)],fill=roof,outline=dark)
    px_rect(draw,(x-14,y-27,x+14,y+18),rgb("#50382f"),dark,3)
    px_rect(draw,(x-45,y-35,x-25,y-15),rgb("#86a7a6"),dark,3)
    px_rect(draw,(x+25,y-35,x+45,y-15),rgb("#86a7a6"),dark,3)
    px_rect(draw,(x-70,y+18,x+70,y+27),shade(color,-20),dark,2)
    # A unique readable silhouette for each chapter building.
    if kind in ("chapel","altar"):
        px_rect(draw,(x-4,y-125,x+4,y-90),rgb("#b6aa82"),dark,2)
        px_rect(draw,(x-14,y-116,x+14,y-108),rgb("#b6aa82"),dark,2)
    elif kind in ("signal","lift"):
        px_rect(draw,(x+35,y-120,x+48,y-60),rgb("#4e4840"),dark,2)
    elif kind in ("lab","pump"):
        px_rect(draw,(x-40,y-83,x+40,y-68),rgb("#a8b6b2"),dark,2)


def biome_details(draw, theme, ground, rng):
    dark=rgb("#1a2730")
    for i in range(20):
        x=rng.randrange(30,615);y=rng.randrange(45,345)
        if theme in ("swamp","canal"):
            draw.ellipse((x-14,y-5,x+14,y+5),fill=shade(ground,-24),outline=rgb("#315d5b"),width=2)
            for k in range(3):draw.line((x-10+k*9,y,x-8+k*9,y-12-rng.randrange(7)),fill=rgb("#587642"),width=2)
        elif theme in ("rail","tunnel","mine","quarry"):
            draw.line((x-12,y+4,x+13,y-5),fill=rgb("#7b654b"),width=3)
            draw.line((x-8,y+8,x+17,y-1),fill=rgb("#282f34"),width=2)
            if i%4==0:draw.polygon([(x,y-10),(x+5,y),(x,y+10),(x-5,y)],fill=rgb("#6fa6aa"),outline=dark)
        elif theme in ("grave","chapel"):
            draw.line((x,y,x+rng.choice([-8,8]),y-8),fill=rgb("#d5c9ad"),width=2)
            draw.line((x,y,x+rng.choice([-7,7]),y+6),fill=rgb("#d5c9ad"),width=2)
            if i%5==0:px_rect(draw,(x+4,y-9,x+7,y+2),rgb("#e7ba57"),dark,1)
        elif theme in ("orchard","greenhouse"):
            draw.line((x,y,x,y-12),fill=rgb("#345f3b"),width=2)
            draw.rectangle((x-6,y-13,x+6,y-7),fill=rgb("#6f9147"),outline=dark,width=1)
            if i%3==0:draw.rectangle((x-2,y-12,x+3,y-8),fill=rgb("#d69b48"))
        else:
            draw.line((x,y,x-4,y-8),fill=shade(ground,-26),width=2);draw.line((x,y,x+5,y-10),fill=shade(ground,-18),width=2)
            if i%4==0:px_rect(draw,(x-4,y+2,x+8,y+4),shade(ground,20))


def draw_outdoor(stage, title, theme_name, ground_hex, path_hex):
    rng=random.Random(9107+stage*331)
    ground=rgb(ground_hex); path=rgb(path_hex); dark=rgb("#18242b")
    im=Image.new("RGB",SIZE,ground); d=ImageDraw.Draw(im)
    # Handmade ground tiles.
    for i in range(650):
        x=rng.randrange(8,632); y=rng.randrange(30,356); c=shade(ground,rng.choice([-18,-11,11,17]))
        px_rect(d,(x,y,x+rng.choice([1,2,3]),y+rng.choice([1,2])),c)
    # Five route silhouettes keep chapters spatially distinct while preserving broad loops.
    variant=(stage//2)%5
    routes=[
        [(42,318),(120,302),(180,270),(250,278),(315,232),(390,245),(455,192),(525,205),(575,145)],
        [(42,318),(135,275),(110,210),(225,180),(315,210),(405,150),(500,170),(555,105)],
        [(42,318),(150,325),(235,285),(210,225),(335,190),(450,225),(535,190),(580,205)],
        [(42,318),(120,280),(230,310),(345,275),(320,205),(440,180),(515,125),(535,90)],
        [(42,318),(150,250),(260,265),(350,310),(440,265),(500,210),(570,245)],
    ]
    route=routes[variant]
    d.line(route,fill=dark,width=38,joint="curve"); d.line(route,fill=path,width=32,joint="curve")
    for i in range(80):
        t=rng.random(); seg=min(len(route)-2,int(t*(len(route)-1))); q=t*(len(route)-1)-seg
        x=int(route[seg][0]*(1-q)+route[seg+1][0]*q+rng.randint(-13,13)); y=int(route[seg][1]*(1-q)+route[seg+1][1]*q+rng.randint(-10,10))
        px_rect(d,(x,y,x+2,y+1),shade(path,rng.choice([-20,18])))
    biome_details(d,theme_name,ground,rng)
    props=[]; collisions=[]
    positions=[(85,110),(155,175),(250,112),(350,150),(470,92),(565,260),(500,315),(370,320),(235,335),(75,245),(600,72),(420,285)]
    for i,(x,y) in enumerate(positions):
        x+=rng.randint(-18,18); y+=rng.randint(-12,12)
        if theme_name=="grave" or (stage%6==0 and i%2==0): kind="tomb"
        elif theme_name in ("quarry","canyon","mine","tunnel") and i%2==0: kind="rock"
        else: kind="tree"
        scale=rng.choice([0.82,0.92,1.0,1.08])
        if kind=="tree": tree(d,x,y,theme_name,rng,scale); base=(x-8,y-8,16,13)
        elif kind=="tomb": tomb(d,x,y,rng); base=(x-15,y-8,30,13)
        else: rock(d,x,y,rng,scale); base=(x-15,y-5,30,12)
        props.append({"kind":kind,"x":x*2,"y":y*2,"scale":scale})
        collisions.append([base[0]*2,base[1]*2,base[2]*2,base[3]*2])
    bx,by=[(565,118),(555,92),(580,205),(535,88),(570,245)][variant]
    building(d,bx,by,BUILDINGS[stage//2],ground)
    collisions.append([(bx-60)*2,(by-12)*2,120*2,36*2])
    props.append({"kind":"roof","x":bx*2,"y":by*2,"scale":1.0})
    # Entry sign and a note board.
    px_rect(d,(28,305,52,344),rgb("#674b35"),dark,2); px_rect(d,(22,300,58,317),rgb("#a98350"),dark,2)
    nx,ny=320,300
    px_rect(d,(nx-10,ny-16,nx+10,ny+10),rgb("#d7c386"),dark,2); px_rect(d,(nx-6,ny-11,nx+6,ny-8),rgb("#6f5842"))
    return im.resize((1280,720),Image.Resampling.NEAREST), props, collisions, [90,630], [bx*2,by*2+26], [nx*2,ny*2]


def draw_indoor(stage, title, theme_name, ground_hex, path_hex):
    rng=random.Random(2281+stage*197)
    floor=shade(rgb(path_hex),10); wall=shade(rgb(ground_hex),25); dark=rgb("#18242b")
    im=Image.new("RGB",SIZE,rgb("#172129")); d=ImageDraw.Draw(im)
    px_rect(d,(18,28,622,354),wall,dark,5); px_rect(d,(28,82,612,348),floor,dark,4)
    for y in range(90,350,16):
        d.line((30,y,610,y),fill=shade(floor,-12 if (y//16)%2 else 9),width=2)
        for x in range(45+(y%32),610,70): px_rect(d,(x,y+2,x+28,y+4),shade(floor,14))
    # Rooms and doorways; partitions stop before openings so the player can weave through.
    for x,y,w,h in [(95,120,110,22),(250,205,120,22),(420,118,120,22),(455,285,110,22)]:
        px_rect(d,(x,y,x+w,y+h),shade(wall,-28),dark,3)
        for k in range(3): px_rect(d,(x+8+k*32,y+5,x+26+k*32,y+13),shade(wall,15))
    props=[]; collisions=[]
    furn=[(95,142),(205,122),(260,228),(370,205),(420,140),(540,142),(455,307),(560,286)]
    for i,(x,y) in enumerate(furn):
        kind="shelf" if i%3==0 else ("crate" if i%3==1 else "pillar")
        if kind=="shelf":
            px_rect(d,(x-28,y-55,x+28,y),rgb("#604533"),dark,3)
            for sy in range(y-45,y,15): d.line((x-24,sy,x+24,sy),fill=rgb("#a67d4d"),width=3)
            base=(x-25,y-8,50,15)
        elif kind=="crate":
            px_rect(d,(x-20,y-34,x+20,y),rgb("#8c6540"),dark,3); d.line((x-17,y-31,x+17,y-3),fill=rgb("#513b2e"),width=3); d.line((x+17,y-31,x-17,y-3),fill=rgb("#513b2e"),width=3)
            base=(x-20,y-7,40,14)
        else:
            px_rect(d,(x-12,y-62,x+12,y),rgb("#73726a"),dark,3); px_rect(d,(x-18,y-10,x+18,y+3),rgb("#858277"),dark,2)
            base=(x-17,y-8,34,15)
        props.append({"kind":kind,"x":x*2,"y":y*2,"scale":1.0}); collisions.append([v*2 for v in base])
    # Start door, exit stairs and readable note.
    px_rect(d,(35,292,72,348),rgb("#4c352d"),dark,3)
    px_rect(d,(548,45,605,88),rgb("#5f5548"),dark,3)
    for s in range(4): px_rect(d,(550+s*5,78+s*5,603-s*5,83+s*5),shade(wall,-15-s*5),dark,1)
    nx,ny=318,105
    px_rect(d,(nx-12,ny-16,nx+12,ny+12),rgb("#e0cd91"),dark,2); px_rect(d,(nx-7,ny-10,nx+7,ny-7),rgb("#705940"))
    if stage==29:
        # Grandfather's altar and the heart chamber.
        px_rect(d,(475,70,600,195),rgb("#2a2229"),dark,4)
        px_rect(d,(495,155,580,180),rgb("#5d4d49"),dark,3)
        for a in range(8):
            ang=a*math.tau/8; x=int(540+42*math.cos(ang)); y=int(120+30*math.sin(ang))
            d.line((x,y,540,120),fill=rgb("#71213b"),width=4)
        d.ellipse((512,92,568,148),fill=rgb("#a52d50"),outline=dark,width=4)
    return im.resize((1280,720),Image.Resampling.NEAREST), props, collisions, [100,625], [1150,155], [nx*2,ny*2]


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    layouts=[]
    for chapter,(outside,inside,note) in enumerate(CHAPTERS):
        theme_name,ground,path=THEMES[chapter]
        for part,title in enumerate((outside,inside)):
            stage=chapter*2+part
            if part==0: image,props,collisions,entry,exitp,notep=draw_outdoor(stage,title,theme_name,ground,path)
            else: image,props,collisions,entry,exitp,notep=draw_indoor(stage,title,theme_name,ground,path)
            image.save(OUT/f"campaign_{stage:02d}.png",optimize=True)
            content=note if part==0 else INTERIOR_ADDENDA[chapter]
            full_note=f"第{chapter+1}章 · {title}\n\n{content}\n\n{'沿着痕迹进入前方建筑继续调查。' if part==0 else '这条线索把路线指向了下一个区域。'}"
            layouts.append({
                "stage":stage,"chapter":chapter+1,"title":title,
                "subtitle":f"第{chapter+1}章 · {'进入建筑调查' if part==0 else '搜索房间并继续深入'}",
                "note":full_note,"theme":theme_name,"interior":bool(part),
                "entry":entry,"exit":exitp,"note_point":notep,
                "heart":[1080,245] if stage==29 else [1040,205],
                "props":props,"collisions":collisions,
                "enemy_count":min(10,3+chapter//2+(1 if part else 0)),
                "enemy_kind":min(5,chapter//3),
                "reward":900+chapter*400+part*250,
            })
    (OUT/"campaign_layouts.json").write_text(json.dumps(layouts,ensure_ascii=False,indent=2),encoding="utf-8")
    print(f"generated {len(layouts)} maps in {OUT}")


if __name__=="__main__":
    main()
