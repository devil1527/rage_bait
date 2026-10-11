import os
from PIL import Image, ImageDraw

os.makedirs("assets/sprites", exist_ok=True)

def create_player():
    # 24x32 retro cyber runner sprite
    img = Image.new("RGBA", (24, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Body/Jumpsuit: Dark indigo / cyan trim
    # Helmet / head
    d.rectangle([6, 2, 17, 12], fill=(24, 28, 48, 255), outline=(64, 78, 120, 255))
    # Visor (glowing cyan)
    d.rectangle([9, 5, 17, 8], fill=(0, 240, 255, 255))
    d.rectangle([14, 5, 17, 8], fill=(200, 255, 255, 255))
    # Helmet crest (coral/orange)
    d.rectangle([10, 0, 13, 2], fill=(255, 75, 90, 255))
    
    # Torso
    d.rectangle([7, 13, 16, 22], fill=(35, 42, 68, 255), outline=(70, 85, 135, 255))
    # Chest neon core
    d.rectangle([10, 15, 13, 18], fill=(0, 255, 200, 255))
    
    # Arms
    d.rectangle([4, 14, 6, 21], fill=(25, 30, 50, 255))
    d.rectangle([17, 14, 19, 21], fill=(25, 30, 50, 255))
    
    # Belt (gold)
    d.rectangle([7, 21, 16, 23], fill=(255, 200, 40, 255))
    
    # Legs
    d.rectangle([7, 24, 10, 29], fill=(20, 24, 40, 255))
    d.rectangle([13, 24, 16, 29], fill=(20, 24, 40, 255))
    
    # Boots (coral orange)
    d.rectangle([6, 29, 11, 31], fill=(255, 80, 80, 255))
    d.rectangle([12, 29, 17, 31], fill=(255, 80, 80, 255))
    
    img.save("assets/sprites/player.png")

def create_coin():
    # 16x16 gold coin
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Outer rim
    d.ellipse([1, 1, 14, 14], fill=(240, 170, 20, 255), outline=(160, 100, 10, 255))
    # Inner face
    d.ellipse([3, 3, 12, 12], fill=(255, 215, 50, 255))
    # Retro currency glyph / star center
    d.rectangle([7, 5, 8, 10], fill=(200, 130, 10, 255))
    d.rectangle([5, 7, 10, 8], fill=(200, 130, 10, 255))
    # Highlight
    d.ellipse([4, 4, 7, 6], fill=(255, 255, 200, 255))
    
    img.save("assets/sprites/coin.png")

def create_tile():
    # 32x32 retro platform brick tile
    img = Image.new("RGBA", (32, 32), (20, 18, 36, 255))
    d = ImageDraw.Draw(img)
    
    # Neon top edge (cyan)
    d.line([(0, 0), (31, 0)], fill=(0, 230, 230, 255))
    d.line([(0, 1), (31, 1)], fill=(0, 160, 180, 255))
    
    # Brick pattern
    brick_dark = (14, 12, 26, 255)
    brick_light = (38, 34, 60, 255)
    
    # Row 1
    d.rectangle([1, 3, 14, 14], fill=brick_light, outline=brick_dark)
    d.rectangle([16, 3, 30, 14], fill=brick_light, outline=brick_dark)
    
    # Row 2
    d.rectangle([1, 16, 7, 28], fill=brick_light, outline=brick_dark)
    d.rectangle([9, 16, 22, 28], fill=brick_light, outline=brick_dark)
    d.rectangle([24, 16, 30, 28], fill=brick_light, outline=brick_dark)
    
    # Subtle cyber grid highlights
    d.point((4, 6), fill=(70, 65, 110, 255))
    d.point((19, 6), fill=(70, 65, 110, 255))
    d.point((13, 20), fill=(70, 65, 110, 255))
    
    img.save("assets/sprites/platform_tile.png")

def create_spikes():
    # 32x16 hazard spikes
    img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # 4 triangular spikes
    coral_light = (255, 75, 95, 255)
    coral_dark = (160, 25, 45, 255)
    tip_white = (255, 220, 225, 255)
    
    for i in range(4):
        x0 = i * 8
        d.polygon([(x0, 15), (x0 + 4, 1), (x0 + 7, 15)], fill=coral_dark)
        d.polygon([(x0 + 1, 15), (x0 + 4, 2), (x0 + 6, 15)], fill=coral_light)
        d.point((x0 + 4, 1), fill=tip_white)
        d.point((x0 + 4, 2), fill=tip_white)
        
    img.save("assets/sprites/spikes.png")

def create_exit_gates():
    # Locked gate (40x56)
    img_locked = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_locked)
    # Portal pillars
    d.rectangle([2, 4, 8, 55], fill=(30, 35, 55, 255), outline=(60, 70, 100, 255))
    d.rectangle([31, 4, 37, 55], fill=(30, 35, 55, 255), outline=(60, 70, 100, 255))
    # Arch top
    d.rectangle([2, 2, 37, 10], fill=(40, 48, 75, 255), outline=(70, 85, 125, 255))
    # Dark barrier field
    d.rectangle([9, 11, 30, 55], fill=(20, 15, 30, 240))
    # Red grid bars
    for y in range(16, 54, 8):
        d.line([(9, y), (30, y)], fill=(180, 40, 50, 255))
    # Lock symbol in center
    d.rectangle([15, 26, 24, 36], fill=(255, 60, 70, 255), outline=(255, 180, 190, 255))
    d.ellipse([17, 21, 22, 27], outline=(255, 200, 210, 255), fill=None)
    img_locked.save("assets/sprites/exit_locked.png")

    # Open gate (40x56)
    img_open = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(img_open)
    # Portal pillars glowing cyan
    d2.rectangle([2, 4, 8, 55], fill=(20, 55, 65, 255), outline=(0, 230, 255, 255))
    d2.rectangle([31, 4, 37, 55], fill=(20, 55, 65, 255), outline=(0, 230, 255, 255))
    d2.rectangle([2, 2, 37, 10], fill=(25, 70, 85, 255), outline=(0, 255, 255, 255))
    # Glowing vortex interior
    d2.rectangle([9, 11, 30, 55], fill=(10, 45, 60, 255))
    # Swirling cyber waves
    for y in range(14, 52, 6):
        d2.ellipse([11, y, 28, y + 4], outline=(0, 240, 255, 220))
    d2.ellipse([15, 24, 24, 36], fill=(220, 255, 255, 255))
    img_open.save("assets/sprites/exit_open.png")

def create_touch_buttons():
    # 128x128 polished high-res touch control buttons with retro neon styling
    def draw_pixel_jump(d, start_x, start_y, fill):
        # J (12x16)
        jx = start_x
        d.rectangle([jx, start_y, jx + 11, start_y + 2], fill=fill)
        d.rectangle([jx + 6, start_y, jx + 9, start_y + 12], fill=fill)
        d.rectangle([jx, start_y + 9, jx + 3, start_y + 12], fill=fill)
        d.rectangle([jx, start_y + 12, jx + 9, start_y + 15], fill=fill)
        # U (12x16)
        ux = jx + 15
        d.rectangle([ux, start_y, ux + 3, start_y + 12], fill=fill)
        d.rectangle([ux + 8, start_y, ux + 11, start_y + 12], fill=fill)
        d.rectangle([ux, start_y + 12, ux + 11, start_y + 15], fill=fill)
        # M (16x16)
        mx = ux + 15
        d.rectangle([mx, start_y, mx + 3, start_y + 15], fill=fill)
        d.rectangle([mx + 12, start_y, mx + 15, start_y + 15], fill=fill)
        d.rectangle([mx + 3, start_y + 3, mx + 6, start_y + 6], fill=fill)
        d.rectangle([mx + 9, start_y + 3, mx + 12, start_y + 6], fill=fill)
        d.rectangle([mx + 6, start_y + 5, mx + 9, start_y + 8], fill=fill)
        # P (12x16)
        px = mx + 19
        d.rectangle([px, start_y, px + 3, start_y + 15], fill=fill)
        d.rectangle([px, start_y, px + 11, start_y + 2], fill=fill)
        d.rectangle([px + 8, start_y, px + 11, start_y + 8], fill=fill)
        d.rectangle([px, start_y + 7, px + 11, start_y + 9], fill=fill)

    def make_btn(btn_type, pressed):
        img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        offset = 2 if pressed else 0
        
        if btn_type == "jump":
            bg_fill = (180, 135, 15, 235) if pressed else (20, 24, 44, 210)
            outline = (255, 240, 110, 255) if pressed else (255, 205, 45, 240)
            elem_fill = (255, 255, 255, 255) if pressed else (255, 215, 50, 255)
            d.ellipse([5, 5, 122, 122], fill=bg_fill, outline=outline, width=4)
            if not pressed:
                d.ellipse([11, 11, 116, 116], outline=(120, 95, 25, 130), width=2)
            # Arrow
            d.polygon([
                (64 + offset, 20 + offset),
                (36 + offset, 50 + offset),
                (51 + offset, 50 + offset),
                (51 + offset, 62 + offset),
                (77 + offset, 62 + offset),
                (77 + offset, 50 + offset),
                (92 + offset, 50 + offset)
            ], fill=elem_fill)
            # Text JUMP
            draw_pixel_jump(d, 33 + offset, 72 + offset, elem_fill)
        else:
            bg_fill = (0, 160, 210, 235) if pressed else (18, 24, 46, 210)
            outline = (180, 245, 255, 255) if pressed else (0, 220, 240, 240)
            elem_fill = (255, 255, 255, 255) if pressed else (0, 240, 255, 255)
            d.ellipse([5, 5, 122, 122], fill=bg_fill, outline=outline, width=4)
            if not pressed:
                d.ellipse([11, 11, 116, 116], outline=(30, 80, 110, 130), width=2)
            if btn_type == "left":
                d.polygon([
                    (32 + offset, 64 + offset),
                    (68 + offset, 30 + offset),
                    (68 + offset, 46 + offset),
                    (92 + offset, 46 + offset),
                    (92 + offset, 82 + offset),
                    (68 + offset, 82 + offset),
                    (68 + offset, 98 + offset)
                ], fill=elem_fill)
            else: # right
                d.polygon([
                    (96 + offset, 64 + offset),
                    (60 + offset, 30 + offset),
                    (60 + offset, 46 + offset),
                    (36 + offset, 46 + offset),
                    (36 + offset, 82 + offset),
                    (60 + offset, 82 + offset),
                    (60 + offset, 98 + offset)
                ], fill=elem_fill)
        return img

    make_btn("left", False).save("assets/sprites/btn_left.png")
    make_btn("left", True).save("assets/sprites/btn_left_pressed.png")
    make_btn("right", False).save("assets/sprites/btn_right.png")
    make_btn("right", True).save("assets/sprites/btn_right_pressed.png")
    make_btn("jump", False).save("assets/sprites/btn_jump.png")
    make_btn("jump", True).save("assets/sprites/btn_jump_pressed.png")

def create_game_cards():
    # 200x120 artwork banners for the 4 arcade games
    # 1. Coin Hell
    c1 = Image.new("RGBA", (200, 120), (22, 16, 38, 255))
    d1 = ImageDraw.Draw(c1)
    d1.rectangle([0, 0, 199, 119], outline=(255, 200, 40, 255), width=2)
    # Background neon grid lines
    for x in range(0, 200, 20):
        d1.line([(x, 0), (x, 120)], fill=(34, 26, 56, 255))
    for y in range(0, 120, 15):
        d1.line([(0, y), (200, y)], fill=(34, 26, 56, 255))
    # Giant Coin Hell Skull with Coin Eyes
    d1.rectangle([75, 28, 125, 78], fill=(45, 35, 70, 255), outline=(180, 140, 40, 255))
    # Two glowing coins for eyes
    d1.ellipse([82, 38, 96, 52], fill=(255, 215, 50, 255), outline=(200, 140, 10, 255))
    d1.ellipse([104, 38, 118, 52], fill=(255, 215, 50, 255), outline=(200, 140, 10, 255))
    # Hellish teeth
    d1.rectangle([85, 66, 115, 74], fill=(20, 15, 30, 255))
    for tx in [87, 93, 99, 105, 111]:
        d1.rectangle([tx, 66, tx + 2, 70], fill=(255, 255, 255, 255))
    # Flame horns
    d1.polygon([(78, 28), (70, 10), (86, 25)], fill=(255, 70, 80, 255))
    d1.polygon([(122, 28), (130, 10), (114, 25)], fill=(255, 70, 80, 255))
    c1.save("assets/sprites/card_coin_hell.png")

    # 2. Bullet Betrayal
    c2 = Image.new("RGBA", (200, 120), (18, 22, 36, 255))
    d2 = ImageDraw.Draw(c2)
    d2.rectangle([0, 0, 199, 119], outline=(80, 95, 130, 255), width=2)
    # Giant bullet pointing backwards
    d2.rectangle([65, 45, 125, 65], fill=(50, 60, 85, 255))
    d2.polygon([(125, 45), (145, 55), (125, 65)], fill=(220, 80, 90, 255)) # U-turn betrayal
    # U-turn arrow
    d2.arc([75, 25, 125, 75], start=180, end=360, fill=(0, 230, 255, 255), width=3)
    c2.save("assets/sprites/card_bullet_betrayal.png")

    # 3. Ninja Nightmare
    c3 = Image.new("RGBA", (200, 120), (16, 20, 32, 255))
    d3 = ImageDraw.Draw(c3)
    d3.rectangle([0, 0, 199, 119], outline=(80, 95, 130, 255), width=2)
    # Shuriken spinning silhouette
    d3.polygon([(100, 25), (105, 50), (130, 55), (105, 60), (100, 85), (95, 60), (70, 55), (95, 50)], fill=(70, 90, 120, 255))
    d3.ellipse([96, 51, 104, 59], fill=(16, 20, 32, 255))
    c3.save("assets/sprites/card_ninja_nightmare.png")

    # 4. Castle of Lies
    c4 = Image.new("RGBA", (200, 120), (20, 18, 30, 255))
    d4 = ImageDraw.Draw(c4)
    d4.rectangle([0, 0, 199, 119], outline=(80, 95, 130, 255), width=2)
    # Castle battlement
    d4.rectangle([70, 35, 130, 85], fill=(45, 40, 65, 255))
    d4.rectangle([70, 25, 80, 35], fill=(45, 40, 65, 255))
    d4.rectangle([95, 25, 105, 35], fill=(45, 40, 65, 255))
    d4.rectangle([120, 25, 130, 35], fill=(45, 40, 65, 255))
    # Trapdoor question mark
    d4.rectangle([90, 55, 110, 85], fill=(20, 15, 28, 255))
    d4.ellipse([96, 60, 104, 68], outline=(255, 80, 100, 255))
    c4.save("assets/sprites/card_castle_lies.png")

def create_ui_icons():
    # Lock icon 16x16
    lock = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    dl = ImageDraw.Draw(lock)
    dl.rectangle([3, 6, 12, 14], fill=(140, 145, 160, 255), outline=(80, 85, 100, 255))
    dl.arc([4, 2, 11, 10], start=180, end=0, fill=(180, 185, 200, 255), width=2)
    dl.point((8, 10), fill=(40, 45, 55, 255))
    lock.save("assets/sprites/icon_lock.png")

    # Check / Star icon 16x16
    star = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    ds = ImageDraw.Draw(star)
    ds.polygon([(8, 1), (10, 5), (15, 6), (11, 10), (12, 15), (8, 12), (4, 15), (5, 10), (1, 6), (6, 5)], fill=(0, 240, 200, 255), outline=(0, 160, 140, 255))
    star.save("assets/sprites/icon_completed.png")

def create_neon_ruins_assets():
    brick_dark = (12, 10, 20, 255)
    brick_mid = (30, 24, 46, 255)

    # 1. 32x32 platform_ruins.png - Cracked stone platform with neon magenta/cyan trim
    ruins = Image.new("RGBA", (32, 32), (18, 14, 28, 255))
    dr = ImageDraw.Draw(ruins)
    # Neon top rim (magenta/purple glow)
    dr.line([(0, 0), (31, 0)], fill=(255, 30, 140, 255))
    dr.line([(0, 1), (31, 1)], fill=(180, 20, 100, 255))
    # Stone brick pattern with ruin cracks
    dr.rectangle([1, 3, 14, 14], fill=brick_mid, outline=brick_dark)
    dr.rectangle([16, 3, 30, 14], fill=brick_mid, outline=brick_dark)
    dr.rectangle([1, 16, 10, 29], fill=brick_mid, outline=brick_dark)
    dr.rectangle([12, 16, 25, 29], fill=brick_mid, outline=brick_dark)
    dr.rectangle([27, 16, 30, 29], fill=brick_mid, outline=brick_dark)
    # Fissure crack lines
    dr.line([(6, 5), (9, 9), (8, 13)], fill=(0, 220, 240, 200))
    dr.line([(22, 6), (20, 11), (24, 14)], fill=(255, 40, 160, 180))
    dr.line([(16, 18), (18, 24)], fill=(0, 220, 240, 200))
    ruins.save("assets/sprites/platform_ruins.png")

    # 2. 32x32 crumbling_tile.png - Visibly fractured/unstable ruin stone
    crumb = Image.new("RGBA", (32, 32), (18, 14, 28, 255))
    dc = ImageDraw.Draw(crumb)
    dc.line([(0, 0), (31, 0)], fill=(255, 90, 50, 255))
    dc.line([(0, 1), (31, 1)], fill=(180, 50, 30, 255))
    # Fractured segments
    dc.polygon([(1, 3), (12, 3), (8, 14), (1, 14)], fill=(32, 22, 40, 255), outline=brick_dark)
    dc.polygon([(14, 3), (30, 3), (28, 14), (10, 14)], fill=(28, 20, 36, 255), outline=brick_dark)
    dc.polygon([(1, 16), (15, 16), (11, 29), (1, 29)], fill=(26, 18, 34, 255), outline=brick_dark)
    dc.polygon([(17, 16), (30, 16), (30, 29), (13, 29)], fill=(32, 22, 40, 255), outline=brick_dark)
    # Deep cracks with fiery/neon glow
    dc.line([(12, 2), (9, 15), (16, 16), (12, 30)], fill=(255, 120, 40, 255), width=1)
    dc.line([(20, 4), (25, 10), (22, 14)], fill=(255, 60, 80, 255), width=1)
    crumb.save("assets/sprites/crumbling_tile.png")

    # 3. 36x64 moving_wall.png - Heavy stone crusher monolith
    wall = Image.new("RGBA", (36, 64), (14, 12, 22, 255))
    dw = ImageDraw.Draw(wall)
    # Outer frame
    dw.rectangle([0, 0, 35, 63], outline=(255, 40, 140, 255), width=2)
    # Inner metal / stone ribs
    for y in range(4, 60, 8):
        dw.line([(4, y), (31, y)], fill=(40, 34, 58, 255), width=2)
    # Center hazardous warning rune
    dw.polygon([(18, 16), (28, 32), (18, 48), (8, 32)], fill=(25, 20, 38, 255), outline=(255, 50, 120, 255), width=2)
    dw.ellipse([14, 28, 22, 36], fill=(255, 200, 40, 255))
    wall.save("assets/sprites/moving_wall.png")

    # 4. 40x56 exit_fake.png - Deceptive glitching door
    fake = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    df = ImageDraw.Draw(fake)
    # Pillars
    df.rectangle([2, 4, 8, 55], fill=(30, 25, 45, 255), outline=(255, 40, 140, 255))
    df.rectangle([31, 4, 37, 55], fill=(30, 25, 45, 255), outline=(255, 40, 140, 255))
    df.rectangle([2, 2, 37, 10], fill=(40, 30, 60, 255), outline=(255, 60, 180, 255))
    # Interior glitch portal
    df.rectangle([9, 11, 30, 55], fill=(20, 10, 30, 255))
    for y in range(14, 52, 6):
        df.line([(10, y), (29, y)], fill=(255, 40, 120, 200))
    # Decoy question/skull glyph
    df.ellipse([16, 22, 24, 30], outline=(255, 200, 60, 255), width=2)
    df.point((20, 35), fill=(255, 200, 60, 255))
    fake.save("assets/sprites/exit_fake.png")

def create_inferno_gate_assets():
    # 1. 36x12 inferno_emitter.png - Ruin fire nozzle / magma vent
    emit = Image.new("RGBA", (36, 12), (0, 0, 0, 0))
    de = ImageDraw.Draw(emit)
    # Heavy stone base
    de.rectangle([0, 2, 35, 11], fill=(22, 18, 32, 255), outline=(50, 40, 70, 255))
    # Glowing magma conduits
    de.rectangle([2, 0, 33, 3], fill=(255, 70, 20, 255))
    de.line([(6, 1), (29, 1)], fill=(255, 220, 50, 255))
    # Vent slots
    for x in range(6, 30, 6):
        de.rectangle([x, 5, x+2, 9], fill=(255, 130, 20, 255))
    emit.save("assets/sprites/inferno_emitter.png")

    # 2. 36x128 inferno_flame.png - Vertical column of blazing neon fire
    flame = Image.new("RGBA", (36, 128), (0, 0, 0, 0))
    df = ImageDraw.Draw(flame)
    import math
    for y in range(128):
        # Calculate width of flame envelope at height y
        norm_y = y / 128.0
        # Wavy flicker based on sine waves
        wobble1 = math.sin(y * 0.22) * 2.5
        wobble2 = math.cos(y * 0.15) * 2.0
        cx = 18.0 + wobble1
        half_w = 14.0 + wobble2
        
        # Outer flame aura (neon magenta/crimson)
        x0_out = max(0, int(cx - half_w))
        x1_out = min(35, int(cx + half_w))
        df.line([(x0_out, y), (x1_out, y)], fill=(255, 30, 80, 210))
        
        # Mid flame core (blazing fire orange)
        x0_mid = max(3, int(cx - half_w * 0.75))
        x1_mid = min(32, int(cx + half_w * 0.75))
        df.line([(x0_mid, y), (x1_mid, y)], fill=(255, 120, 20, 245))
        
        # Inner flame core (scorching yellow)
        x0_in = max(6, int(cx - half_w * 0.45))
        x1_in = min(29, int(cx + half_w * 0.45))
        df.line([(x0_in, y), (x1_in, y)], fill=(255, 225, 50, 255))
        
        # White-hot plasma channel in center
        x0_core = max(11, int(cx - half_w * 0.2))
        x1_core = min(24, int(cx + half_w * 0.2))
        df.line([(x0_core, y), (x1_core, y)], fill=(255, 255, 230, 255))

    flame.save("assets/sprites/inferno_flame.png")

if __name__ == "__main__":
    create_player()
    create_coin()
    create_tile()
    create_spikes()
    create_exit_gates()
    create_touch_buttons()
    create_game_cards()
    create_ui_icons()
    create_neon_ruins_assets()
    create_inferno_gate_assets()
    print("All pixel assets generated successfully!")
