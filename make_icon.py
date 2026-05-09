#!/usr/bin/env python3
"""NBA Tracker App Icon — v3: dark navy · vivid orange ball · gold type"""
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE  = 1024
SCALE = 4
W     = SIZE * SCALE

# ── Palette ──────────────────────────────────────────────────────────────────
BG_TOP    = (6,   8,  18)
BG_BOT    = (14, 16,  36)
BALL_MID  = (220, 100,  10)   # warm orange centre
BALL_RIM  = (155,  55,   0)   # darker orange rim
BALL_BRI  = (255, 160,  30)   # bright highlight band
SEAM_COL  = (110,  40,   0)   # dark seam
SEAM_HI   = (200,  90,  10)   # seam inner highlight
GLOW_COL  = (240, 130,  10)   # orange-gold glow
GOLD      = (247, 181,   0)   # NBA gold text
GOLD2     = (200, 140,   0)   # dimmer gold for sub-text
WHITE     = (255, 255, 255)

def bez(p0, p1, p2, n=200):
    pts = []
    for i in range(n+1):
        t = i/n
        x = (1-t)**2*p0[0]+2*(1-t)*t*p1[0]+t**2*p2[0]
        y = (1-t)**2*p0[1]+2*(1-t)*t*p1[1]+t**2*p2[1]
        pts.append((x,y))
    return pts

def pline(draw, pts, col, w):
    for i in range(len(pts)-1):
        draw.line([pts[i], pts[i+1]], fill=col, width=w)

def stroke(d, p0, p1, col, w):
    d.line([p0, p1], fill=col, width=w)

# ── Canvas ────────────────────────────────────────────────────────────────────
img  = Image.new("RGBA", (W, W), BG_TOP+(255,))
draw = ImageDraw.Draw(img)

for y in range(W):
    t = y/W
    r = int(BG_TOP[0]*(1-t)+BG_BOT[0]*t)
    g = int(BG_TOP[1]*(1-t)+BG_BOT[1]*t)
    b = int(BG_TOP[2]*(1-t)+BG_BOT[2]*t)
    draw.line([(0,y),(W,y)], fill=(r,g,b,255))

# Geometry
cx, cy = W//2, int(W*0.405)
R = int(W*0.305)

# ── Soft ambient glow (separate layer, blurred) ───────────────────────────────
gl  = Image.new("RGBA", (W,W), (0,0,0,0))
gd  = ImageDraw.Draw(gl)
for i in range(20, 0, -1):
    a  = int((21-i)*4)
    gr = R + i*int(W*0.016)
    gd.ellipse([cx-gr,cy-gr,cx+gr,cy+gr], fill=(*GLOW_COL, a))
gl  = gl.filter(ImageFilter.GaussianBlur(radius=int(W*0.030)))
img = Image.alpha_composite(img, gl)
draw = ImageDraw.Draw(img)

# ── Ball body — radial fill ───────────────────────────────────────────────────
for r in range(R, 0, -1):
    t  = r/R                                   # 1=rim, 0=centre
    ri = int(BALL_BRI[0]*(1-t) + BALL_RIM[0]*t)
    gi = int(BALL_BRI[1]*(1-t) + BALL_RIM[1]*t)
    bi = int(BALL_BRI[2]*(1-t) + BALL_RIM[2]*t)
    draw.ellipse([cx-r,cy-r,cx+r,cy+r], fill=(ri,gi,bi,255))

# Edge darkening (right-bottom shadow ring)
sh  = Image.new("RGBA", (W,W), (0,0,0,0))
sd  = ImageDraw.Draw(sh)
for i in range(1, 32):
    a = int(i * 6)
    sd.arc([cx-R+i, cy-R+i, cx+R-i, cy+R-i], 20, 200, fill=(0,0,0,a), width=3)
sh  = sh.filter(ImageFilter.GaussianBlur(radius=8))
img = Image.alpha_composite(img, sh)
draw = ImageDraw.Draw(img)

# ── Specular highlight (top-left) ────────────────────────────────────────────
hl  = Image.new("RGBA", (W,W), (0,0,0,0))
hd  = ImageDraw.Draw(hl)
hcx = cx - int(R*0.28)
hcy = cy - int(R*0.30)
hr  = int(R*0.21)
for r in range(hr, 0, -1):
    a = int((1 - r/hr)**1.8 * 100)
    hd.ellipse([hcx-r,hcy-r,hcx+r,hcy+r], fill=(255,230,170,a))
hl  = hl.filter(ImageFilter.GaussianBlur(radius=int(hr*0.5)))
img = Image.alpha_composite(img, hl)
draw = ImageDraw.Draw(img)

# ── Seam lines ────────────────────────────────────────────────────────────────
sw   = int(W*0.017)
sw_h = max(1, sw//3)
bow  = int(R*0.44)
top  = (cx, cy-R)
bot  = (cx, cy+R)
lft  = (cx-R, cy)
rgt  = (cx+R, cy)

for col, width in [(SEAM_COL, sw), (SEAM_HI, sw_h)]:
    stroke(draw, lft, rgt, col, width)           # horizontal
    stroke(draw, top, bot, col, width)           # vertical
    pline(draw, bez(top, (cx-bow, cy), bot), col, width)   # left seam
    pline(draw, bez(top, (cx+bow, cy), bot), col, width)   # right seam

# Ball outline
draw.ellipse([cx-R,cy-R,cx+R,cy+R], outline=(80,30,0,200), width=sw//2)

# ── "NBA" bold block letters ──────────────────────────────────────────────────
lh  = int(W*0.108)
lw  = int(W*0.075)
lk  = int(W*0.028)
gap = int(W*0.026)
tot = 3*lw + 2*gap
lx  = cx - tot//2
ly  = int(cy + R + W*0.050)

def N(d, x, y):
    stroke(d, (x,y),     (x,    y+lh), GOLD, lk)
    stroke(d, (x,y),     (x+lw, y+lh), GOLD, lk)
    stroke(d, (x+lw, y), (x+lw, y+lh), GOLD, lk)

def B(d, x, y):
    stroke(d, (x, y), (x, y+lh), GOLD, lk)
    h2 = lh//2
    bw = int(lw*0.92)
    bw2 = int(lw*1.05)
    d.arc([x, y,    x+bw,  y+h2], -90, 90, fill=GOLD, width=lk)
    stroke(d, (x, y),    (x+bw//2,  y),    GOLD, lk)
    stroke(d, (x, y+h2), (x+bw//2,  y+h2), GOLD, lk)
    d.arc([x, y+h2, x+bw2, y+lh], -90, 90, fill=GOLD, width=lk)
    stroke(d, (x, y+h2), (x+bw2//2, y+h2), GOLD, lk)
    stroke(d, (x, y+lh), (x+bw2//2, y+lh), GOLD, lk)

def A(d, x, y):
    mx = x + lw//2
    stroke(d, (x,  y+lh), (mx, y),    GOLD, lk)
    stroke(d, (mx, y),    (x+lw, y+lh), GOLD, lk)
    bar = int(y + lh*0.56)
    ins = int(lw*0.20)
    stroke(d, (x+ins, bar), (x+lw-ins, bar), GOLD, lk)

N(draw, lx,            ly)
B(draw, lx+lw+gap,     ly)
A(draw, lx+2*(lw+gap), ly)

# ── "TRACKER" small label ────────────────────────────────────────────────────
sh  = int(W*0.036)   # sub letter height
sw2 = int(W*0.026)   # sub letter width
sk  = int(W*0.009)   # sub stroke
sg  = int(W*0.010)   # sub gap
sy  = ly + lh + int(W*0.022)

def sT(d,x,y): stroke(d,(x,y),(x+sw2,y),GOLD2,sk); stroke(d,(x+sw2//2,y),(x+sw2//2,y+sh),GOLD2,sk)
def sR(d,x,y):
    stroke(d,(x,y),(x,y+sh),GOLD2,sk)
    h2=sh//2; d.arc([x,y,x+sw2,y+h2],-90,90,fill=GOLD2,width=sk)
    stroke(d,(x,y),(x+sw2//2,y),GOLD2,sk); stroke(d,(x,y+h2),(x+sw2//2,y+h2),GOLD2,sk)
    stroke(d,(x+sw2//2,y+h2),(x+sw2,y+sh),GOLD2,sk)
def sA(d,x,y):
    mx=x+sw2//2; stroke(d,(x,y+sh),(mx,y),GOLD2,sk); stroke(d,(mx,y),(x+sw2,y+sh),GOLD2,sk)
    bar=int(y+sh*0.55); ins=int(sw2*0.18); stroke(d,(x+ins,bar),(x+sw2-ins,bar),GOLD2,sk)
def sC(d,x,y): d.arc([x,y,x+sw2,y+sh],45,315,fill=GOLD2,width=sk)
def sK(d,x,y):
    stroke(d,(x,y),(x,y+sh),GOLD2,sk); stroke(d,(x,y+sh//2),(x+sw2,y),GOLD2,sk)
    stroke(d,(x,y+sh//2),(x+sw2,y+sh),GOLD2,sk)
def sE(d,x,y):
    stroke(d,(x,y),(x,y+sh),GOLD2,sk); stroke(d,(x,y),(x+sw2,y),GOLD2,sk)
    stroke(d,(x,y+sh//2),(x+int(sw2*0.78),y+sh//2),GOLD2,sk); stroke(d,(x,y+sh),(x+sw2,y+sh),GOLD2,sk)

fns = [sT, sR, sA, sC, sK, sE, sR]
stot = len(fns)*sw2 + (len(fns)-1)*sg
sx   = cx - stot//2
for fn in fns:
    fn(draw, sx, sy)
    sx += sw2 + sg

# ── Gold divider line ─────────────────────────────────────────────────────────
dw = int(W*0.20)
dy = ly - int(W*0.018)
stroke(draw, (cx-dw//2, dy), (cx+dw//2, dy), (*GOLD, 120), int(W*0.005))

# ── Final render ──────────────────────────────────────────────────────────────
out = img.resize((SIZE, SIZE), Image.LANCZOS).convert("RGB")
path = "/Users/neha118/NBATracker/NBATracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
out.save(path, "PNG")
print(f"Saved → {path}")
