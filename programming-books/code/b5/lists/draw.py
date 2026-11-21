"""Draws the café's pictures for Chapter 7's apps (assets/images/*.png): flat illustrations made here, so the
book owns them. Run: python3 draw.py   (needs Pillow)"""
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).parent
OUT = HERE / "assets" / "images"
W, H, S = 480, 360, 3  # drawn three times larger, then reduced, for smooth edges


def canvas(bg):
    im = Image.new("RGB", (W * S, H * S), bg)
    return im, ImageDraw.Draw(im)


def s(*v):
    return [x * S for x in v]


def save(im, name):
    OUT.mkdir(parents=True, exist_ok=True)
    im.resize((W, H), Image.LANCZOS).save(OUT / f"{name}.png", optimize=True)


def latte():
    im, d = canvas("#f3e3cf")
    d.ellipse(s(110, 250, 370, 300), fill="#ffffff", outline="#d9c2a5", width=6)  # saucer
    d.rounded_rectangle(s(150, 140, 330, 275), radius=40 * S, fill="#ffffff", outline="#d9c2a5", width=6)
    d.ellipse(s(150, 115, 330, 165), fill="#c08552")  # coffee
    d.ellipse(s(205, 125, 275, 155), fill="#f7e7d4")  # foam
    d.arc(s(315, 165, 385, 235), -90, 90, fill="#ffffff", width=14 * S)  # handle
    for x in (205, 240, 275):
        d.arc(s(x - 15, 50, x + 15, 110), 200, 340, fill="#c9b49c", width=4 * S)  # steam
    return im


def tea():
    im, d = canvas("#e4f1e4")
    d.polygon(s(170, 120, 310, 120, 290, 290, 190, 290), fill="#d98e2b")
    d.polygon(s(170, 120, 310, 120, 305, 160, 175, 160), fill="#e8a94f")
    d.line(s(170, 120, 190, 290), fill="#ffffff", width=6 * S)
    d.line(s(310, 120, 290, 290), fill="#ffffff", width=6 * S)
    d.ellipse(s(250, 80, 330, 130), fill="#5fa35f")  # mint leaf
    d.line(s(255, 120, 325, 90), fill="#3f7a3f", width=3 * S)
    return im


def cake():
    im, d = canvas("#fbe4ec")
    d.ellipse(s(110, 260, 370, 310), fill="#ffffff", outline="#e8c7d3", width=6)
    d.polygon(s(140, 270, 340, 270, 340, 170, 140, 200), fill="#f6d28b")
    d.polygon(s(140, 230, 340, 225, 340, 205, 140, 215), fill="#c0507a")  # jam
    d.polygon(s(140, 200, 340, 170, 300, 135, 140, 175), fill="#ffffff")  # cream top
    d.ellipse(s(240, 120, 275, 155), fill="#d63b5a")  # cherry
    return im


def cookie():
    im, d = canvas("#efe7da")
    d.ellipse(s(140, 80, 340, 280), fill="#d9a35b", outline="#b9823c", width=8)
    for x, y in ((190, 140), (250, 120), (290, 180), (210, 210), (260, 240), (180, 180)):
        d.ellipse(s(x - 14, y - 12, x + 14, y + 12), fill="#5a3a22")
    return im


def juice():
    im, d = canvas("#fff1d6")
    d.polygon(s(180, 110, 300, 110, 285, 300, 195, 300), fill="#ffffff", outline="#f0d9a8")
    d.polygon(s(184, 150, 296, 150, 285, 296, 195, 296), fill="#f59a23")
    d.line(s(270, 60, 245, 230), fill="#e14b5a", width=10 * S)  # straw
    d.ellipse(s(270, 95, 340, 165), fill="#ffd166", outline="#f59a23", width=6)  # orange slice
    return im


def muffin():
    im, d = canvas("#e6e9f7")
    d.polygon(s(170, 190, 310, 190, 290, 300, 190, 300), fill="#8aa1d8")
    for x in range(185, 300, 22):
        d.line(s(x, 195, x - 5, 298), fill="#6d84bf", width=3 * S)
    d.ellipse(s(150, 105, 330, 215), fill="#7a4a2b")
    for x, y in ((200, 150), (250, 135), (285, 165), (230, 180)):
        d.ellipse(s(x - 9, y - 9, x + 9, y + 9), fill="#3b2314")
    return im


if __name__ == "__main__":
    for f in (latte, tea, cake, cookie, juice, muffin):
        save(f(), f.__name__)
        print("drew", f.__name__)
