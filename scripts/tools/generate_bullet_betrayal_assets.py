"""
Asset generator for Bullet Betrayal - World 1: The Green Hills
Generates pixel art assets for player, enemy, bullets, environment, props, and UI.
"""
import os
from PIL import Image, ImageDraw

SPRITES_DIR = "assets/sprites"
os.makedirs(SPRITES_DIR, exist_ok=True)

def create_shoot_button():
    # 64x64 Shoot Button (Crimson / Coral arcade button matching btn_jump style)
    # Normal
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Outer glow / ring
    d.ellipse([2, 2, 61, 61], fill=(40, 15, 25, 230), outline=(235, 55, 80, 255), width=3)
    d.ellipse([6, 6, 57, 57], fill=(70, 20, 35, 240), outline=(255, 90, 115, 200), width=2)
    # Bullet / Crosshair icon
    # Vertical bullet shape
    d.rectangle([28, 20, 35, 42], fill=(255, 215, 50, 255), outline=(200, 140, 20, 255))
    d.polygon([(28, 20), (31, 13), (35, 20)], fill=(255, 240, 120, 255)) # tip
    d.rectangle([27, 40, 36, 44], fill=(220, 160, 30, 255)) # casing rim
    # Crosshair tick marks
    d.line([(15, 30), (23, 30)], fill=(255, 90, 115, 255), width=2)
    d.line([(40, 30), (48, 30)], fill=(255, 90, 115, 255), width=2)
    d.line([(31, 46), (31, 52)], fill=(255, 90, 115, 255), width=2)
    img.save(f"{SPRITES_DIR}/btn_shoot.png")

    # Pressed
    img_p = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    dp = ImageDraw.Draw(img_p)
    dp.ellipse([4, 4, 59, 59], fill=(95, 25, 45, 255), outline=(255, 120, 140, 255), width=3)
    dp.ellipse([8, 8, 55, 55], fill=(130, 35, 60, 255), outline=(255, 170, 185, 230), width=2)
    # Bullet shape pressed (brighter highlight)
    dp.rectangle([28, 22, 35, 42], fill=(255, 235, 100, 255), outline=(230, 170, 40, 255))
    dp.polygon([(28, 22), (31, 15), (35, 22)], fill=(255, 255, 200, 255))
    dp.rectangle([27, 40, 36, 43], fill=(240, 180, 40, 255))
    dp.line([(17, 31), (23, 31)], fill=(255, 170, 185, 255), width=2)
    dp.line([(40, 31), (46, 31)], fill=(255, 170, 185, 255), width=2)
    dp.line([(31, 45), (31, 50)], fill=(255, 170, 185, 255), width=2)
    img_p.save(f"{SPRITES_DIR}/btn_shoot_pressed.png")

def create_player_soldier():
    # 28x36 pixel commando soldier (Camo green uniform, blue beret/bandana, rifle)
    # Idle
    img = Image.new("RGBA", (28, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Bandana / Headband (Red/Crimson action hero bandana)
    d.rectangle([10, 4, 18, 7], fill=(220, 40, 50, 255))
    d.rectangle([7, 6, 9, 10], fill=(200, 30, 40, 255)) # knot tail
    # Face / Skin
    d.rectangle([10, 8, 18, 13], fill=(235, 180, 140, 255))
    # Eye
    d.point((15, 9), fill=(30, 25, 25, 255))
    # Torso (Olive green military vest / muscle shirt)
    d.rectangle([9, 14, 19, 23], fill=(55, 85, 45, 255), outline=(35, 60, 30, 255))
    # Ammo bandolier across chest
    d.line([(10, 14), (18, 22)], fill=(180, 140, 40, 255), width=2)
    # Arms holding rifle
    d.rectangle([14, 16, 21, 20], fill=(225, 170, 130, 255))
    # Rifle (Matte black / steel assault rifle facing right)
    d.rectangle([16, 17, 27, 21], fill=(45, 48, 55, 255), outline=(20, 22, 28, 255))
    d.rectangle([24, 18, 28, 20], fill=(70, 75, 85, 255)) # barrel
    d.rectangle([18, 21, 20, 24], fill=(30, 32, 38, 255)) # magazine
    # Belt
    d.rectangle([9, 23, 19, 25], fill=(30, 32, 28, 255))
    d.rectangle([13, 23, 15, 25], fill=(210, 170, 40, 255)) # buckle
    # Camo trousers
    d.rectangle([9, 25, 13, 31], fill=(50, 75, 40, 255), outline=(35, 55, 28, 255))
    d.rectangle([15, 25, 19, 31], fill=(58, 82, 46, 255), outline=(35, 55, 28, 255))
    # Combat boots
    d.rectangle([8, 31, 13, 35], fill=(30, 28, 25, 255))
    d.rectangle([15, 31, 20, 35], fill=(30, 28, 25, 255))
    img.save(f"{SPRITES_DIR}/bb_soldier_idle.png")

    # Run frame 1
    img_run1 = img.copy()
    d_r1 = ImageDraw.Draw(img_run1)
    # Clear and redraw legs in stride
    d_r1.rectangle([7, 25, 21, 35], fill=(0, 0, 0, 0))
    d_r1.rectangle([6, 25, 11, 31], fill=(50, 75, 40, 255))
    d_r1.rectangle([5, 31, 10, 35], fill=(30, 28, 25, 255)) # front foot forward
    d_r1.rectangle([16, 25, 21, 30], fill=(58, 82, 46, 255))
    d_r1.rectangle([18, 30, 23, 34], fill=(30, 28, 25, 255)) # back foot back
    img_run1.save(f"{SPRITES_DIR}/bb_soldier_run_1.png")

    # Run frame 2
    img_run2 = img.copy()
    d_r2 = ImageDraw.Draw(img_run2)
    d_r2.rectangle([7, 25, 21, 35], fill=(0, 0, 0, 0))
    d_r2.rectangle([15, 25, 20, 31], fill=(50, 75, 40, 255))
    d_r2.rectangle([16, 31, 22, 35], fill=(30, 28, 25, 255)) # back leg swings forward
    d_r2.rectangle([8, 25, 12, 30], fill=(58, 82, 46, 255))
    d_r2.rectangle([6, 30, 11, 34], fill=(30, 28, 25, 255))
    img_run2.save(f"{SPRITES_DIR}/bb_soldier_run_2.png")

    # Jump
    img_jump = img.copy()
    d_j = ImageDraw.Draw(img_jump)
    d_j.rectangle([7, 25, 21, 35], fill=(0, 0, 0, 0))
    d_j.rectangle([8, 24, 13, 29], fill=(50, 75, 40, 255))
    d_j.rectangle([8, 29, 13, 32], fill=(30, 28, 25, 255)) # legs tucked
    d_j.rectangle([15, 24, 20, 30], fill=(58, 82, 46, 255))
    d_j.rectangle([16, 30, 21, 33], fill=(30, 28, 25, 255))
    img_jump.save(f"{SPRITES_DIR}/bb_soldier_jump.png")

def create_enemy_soldier():
    # 28x36 Enemy Soldier (Steel combat helmet with red visor/goggles, gray/slate uniform)
    img = Image.new("RGBA", (28, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Steel Combat Helmet
    d.rectangle([9, 3, 19, 9], fill=(60, 65, 75, 255), outline=(40, 42, 50, 255))
    # Red Goggles / Visor (intimidating red glow)
    d.rectangle([10, 8, 16, 11], fill=(255, 45, 65, 255), outline=(180, 20, 35, 255))
    d.point((12, 9), fill=(255, 200, 210, 255)) # gleam
    # Mask / Jaw
    d.rectangle([10, 12, 17, 14], fill=(45, 48, 55, 255))
    # Body Armor / Tactical Vest (Dark Slate)
    d.rectangle([8, 15, 19, 24], fill=(55, 60, 70, 255), outline=(35, 38, 45, 255))
    d.rectangle([11, 16, 16, 22], fill=(40, 44, 52, 255)) # reinforced plate
    # Enemy Submachine Gun / Rifle
    d.rectangle([3, 17, 15, 21], fill=(35, 35, 40, 255)) # facing left default
    d.rectangle([1, 18, 5, 20], fill=(70, 75, 85, 255)) # barrel pointing left
    d.rectangle([7, 21, 9, 24], fill=(25, 25, 28, 255)) # magazine
    # Hands
    d.rectangle([7, 16, 14, 19], fill=(45, 48, 55, 255))
    # Belt with tactical pouches
    d.rectangle([8, 24, 19, 26], fill=(30, 30, 35, 255))
    d.rectangle([9, 24, 12, 26], fill=(70, 75, 85, 255))
    # Pants (Dark Charcoal)
    d.rectangle([9, 26, 13, 31], fill=(48, 50, 58, 255))
    d.rectangle([15, 26, 19, 31], fill=(48, 50, 58, 255))
    # Boots
    d.rectangle([8, 31, 13, 35], fill=(25, 25, 28, 255))
    d.rectangle([15, 31, 20, 35], fill=(25, 25, 28, 255))
    img.save(f"{SPRITES_DIR}/bb_enemy_idle.png")

    # Run frame 1
    img_r1 = img.copy()
    dr1 = ImageDraw.Draw(img_r1)
    dr1.rectangle([7, 26, 21, 35], fill=(0, 0, 0, 0))
    dr1.rectangle([6, 26, 11, 31], fill=(48, 50, 58, 255))
    dr1.rectangle([5, 31, 10, 35], fill=(25, 25, 28, 255))
    dr1.rectangle([16, 26, 20, 30], fill=(48, 50, 58, 255))
    dr1.rectangle([18, 30, 23, 34], fill=(25, 25, 28, 255))
    img_r1.save(f"{SPRITES_DIR}/bb_enemy_run_1.png")

    # Run frame 2
    img_r2 = img.copy()
    dr2 = ImageDraw.Draw(img_r2)
    dr2.rectangle([7, 26, 21, 35], fill=(0, 0, 0, 0))
    dr2.rectangle([15, 26, 20, 31], fill=(48, 50, 58, 255))
    dr2.rectangle([16, 31, 22, 35], fill=(25, 25, 28, 255))
    dr2.rectangle([8, 26, 12, 30], fill=(48, 50, 58, 255))
    dr2.rectangle([6, 30, 11, 34], fill=(25, 25, 28, 255))
    img_r2.save(f"{SPRITES_DIR}/bb_enemy_run_2.png")

def create_bullets():
    # Player Bullet (16x8 luminous tracer bullet)
    img_pb = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img_pb)
    # Glow trail
    d.line([(0, 4), (10, 4)], fill=(255, 140, 20, 160), width=3)
    # Bullet body
    d.rectangle([6, 2, 13, 5], fill=(255, 230, 60, 255))
    # Tip (white hot)
    d.polygon([(13, 2), (16, 3), (16, 4), (13, 5)], fill=(255, 255, 220, 255))
    img_pb.save(f"{SPRITES_DIR}/bb_bullet_player.png")

    # Enemy Bullet (12x8 red-orange plasma / tracer)
    img_eb = Image.new("RGBA", (12, 8), (0, 0, 0, 0))
    d_eb = ImageDraw.Draw(img_eb)
    d_eb.line([(2, 4), (11, 4)], fill=(255, 40, 60, 180), width=3)
    d_eb.rectangle([1, 2, 8, 5], fill=(255, 90, 80, 255))
    d_eb.polygon([(0, 3), (0, 4), (2, 2), (2, 5)], fill=(255, 230, 230, 255))
    img_eb.save(f"{SPRITES_DIR}/bb_bullet_enemy.png")

def create_ammo_crate():
    # 24x20 Olive-drab military ammo crate with gold ammo stencil
    img = Image.new("RGBA", (24, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Box body
    d.rectangle([1, 4, 22, 19], fill=(50, 70, 45, 255), outline=(30, 45, 25, 255), width=1)
    # Metal corner brackets
    d.rectangle([1, 4, 4, 7], fill=(85, 95, 80, 255))
    d.rectangle([19, 4, 22, 7], fill=(85, 95, 80, 255))
    d.rectangle([1, 16, 4, 19], fill=(85, 95, 80, 255))
    d.rectangle([19, 16, 22, 19], fill=(85, 95, 80, 255))
    # Top lid handle
    d.rectangle([8, 1, 15, 4], fill=(70, 80, 65, 255), outline=(35, 45, 30, 255))
    # Stenciled gold bullets / "AMMO" marking
    # 3 vertical bullet outlines
    d.rectangle([7, 8, 9, 15], fill=(255, 215, 50, 255))
    d.polygon([(7, 8), (8, 6), (9, 8)], fill=(255, 240, 150, 255))
    d.rectangle([11, 8, 13, 15], fill=(255, 215, 50, 255))
    d.polygon([(11, 8), (12, 6), (13, 8)], fill=(255, 240, 150, 255))
    d.rectangle([15, 8, 17, 15], fill=(255, 215, 50, 255))
    d.polygon([(15, 8), (16, 6), (17, 8)], fill=(255, 240, 150, 255))
    img.save(f"{SPRITES_DIR}/bb_ammo_crate.png")

def create_environment_tiles():
    # 1. Grassy hill surface tile (32x32)
    img_grass = Image.new("RGBA", (32, 32), (55, 42, 30, 255)) # Rich soil brown base
    dg = ImageDraw.Draw(img_grass)
    # Soil texture
    dg.rectangle([2, 12, 8, 16], fill=(45, 34, 22, 255))
    dg.rectangle([14, 18, 22, 23], fill=(68, 52, 38, 255))
    dg.rectangle([8, 24, 13, 28], fill=(45, 34, 22, 255))
    dg.rectangle([24, 14, 29, 18], fill=(45, 34, 22, 255))
    # Grass layer on top
    dg.rectangle([0, 0, 31, 6], fill=(58, 145, 50, 255))
    # Grass blades / highlights
    for x in range(0, 32, 3):
        h = 8 if (x % 6 == 0) else 6
        dg.polygon([(x, 0), (x+1, h), (x+2, 0)], fill=(85, 195, 65, 255))
        dg.point((x+1, 1), fill=(140, 235, 95, 255))
    img_grass.save(f"{SPRITES_DIR}/bb_terrain_grass.png")

    # 2. Sub-surface rock / cliff tile (32x32)
    img_rock = Image.new("RGBA", (32, 32), (52, 40, 32, 255))
    dr = ImageDraw.Draw(img_rock)
    dr.rectangle([3, 4, 16, 14], fill=(64, 50, 40, 255), outline=(38, 28, 22, 255))
    dr.rectangle([18, 12, 30, 24], fill=(42, 32, 24, 255), outline=(32, 24, 18, 255))
    dr.rectangle([2, 18, 14, 29], fill=(58, 45, 36, 255), outline=(38, 28, 22, 255))
    dr.point((8, 8), fill=(80, 65, 52, 255))
    dr.point((24, 18), fill=(75, 60, 48, 255))
    img_rock.save(f"{SPRITES_DIR}/bb_terrain_rock.png")

    # 3. Wooden military platform (64x20)
    img_plat = Image.new("RGBA", (64, 20), (0, 0, 0, 0))
    dp = ImageDraw.Draw(img_plat)
    # Heavy wooden beams
    dp.rectangle([0, 2, 63, 17], fill=(110, 75, 42, 255), outline=(65, 42, 22, 255), width=2)
    # Plank vertical dividers
    dp.line([(16, 2), (16, 17)], fill=(65, 42, 22, 255), width=2)
    dp.line([(32, 2), (32, 17)], fill=(65, 42, 22, 255), width=2)
    dp.line([(48, 2), (48, 17)], fill=(65, 42, 22, 255), width=2)
    # Wood grain highlight
    dp.line([(2, 4), (14, 4)], fill=(145, 102, 60, 255))
    dp.line([(18, 4), (30, 4)], fill=(145, 102, 60, 255))
    dp.line([(34, 4), (46, 4)], fill=(145, 102, 60, 255))
    dp.line([(50, 4), (61, 4)], fill=(145, 102, 60, 255))
    # Steel bolt studs
    for bx in [4, 12, 20, 28, 36, 44, 52, 60]:
        dp.point((bx, 6), fill=(190, 195, 205, 255))
        dp.point((bx, 13), fill=(190, 195, 205, 255))
    img_plat.save(f"{SPRITES_DIR}/bb_platform_wood.png")

    # 4. Sandbags prop (48x24)
    img_sb = Image.new("RGBA", (48, 24), (0, 0, 0, 0))
    dsb = ImageDraw.Draw(img_sb)
    # Bottom row (3 bags)
    bags_bottom = [(1, 10, 16, 23), (15, 10, 32, 23), (30, 10, 47, 23)]
    for x0, y0, x1, y1 in bags_bottom:
        dsb.rounded_rectangle([x0, y0, x1, y1], radius=4, fill=(185, 165, 120, 255), outline=(125, 105, 70, 255), width=1)
        dsb.line([(x0+3, y0+3), (x1-3, y0+3)], fill=(215, 195, 145, 255))
    # Top row (2 bags)
    bags_top = [(8, 2, 24, 14), (23, 2, 40, 14)]
    for x0, y0, x1, y1 in bags_top:
        dsb.rounded_rectangle([x0, y0, x1, y1], radius=4, fill=(195, 175, 130, 255), outline=(130, 110, 75, 255), width=1)
        dsb.line([(x0+3, y0+3), (x1-3, y0+3)], fill=(225, 205, 155, 255))
    img_sb.save(f"{SPRITES_DIR}/bb_sandbag.png")

    # 5. Wooden supply crate prop (32x32)
    img_crate = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    dc = ImageDraw.Draw(img_crate)
    dc.rectangle([1, 1, 30, 30], fill=(130, 90, 50, 255), outline=(75, 50, 28, 255), width=2)
    # Diagonal brace
    dc.line([(3, 3), (28, 28)], fill=(85, 58, 32, 255), width=3)
    dc.line([(28, 3), (3, 28)], fill=(85, 58, 32, 255), width=3)
    # Edge rivets
    for p in [(3, 3), (28, 3), (3, 28), (28, 28)]:
        dc.point(p, fill=(210, 215, 225, 255))
    img_crate.save(f"{SPRITES_DIR}/bb_crate.png")

    # 6. Jungle Tree (64x96)
    img_tree = Image.new("RGBA", (64, 96), (0, 0, 0, 0))
    dt = ImageDraw.Draw(img_tree)
    # Trunk
    dt.rectangle([28, 48, 35, 95], fill=(85, 55, 30, 255), outline=(50, 32, 18, 255))
    dt.line([(30, 50), (30, 94)], fill=(115, 75, 42, 255))
    # Foliage Canopy (Multi-tiered jungle foliage)
    tiers = [
        ([14, 44, 49, 68], (38, 110, 42, 255), (25, 78, 28, 255)),
        ([10, 26, 53, 52], (48, 135, 52, 255), (32, 95, 36, 255)),
        ([16, 8, 47, 34], (62, 165, 62, 255), (42, 118, 44, 255)),
        ([24, 0, 39, 16], (80, 195, 75, 255), (55, 140, 52, 255))
    ]
    for box, fill_col, out_col in tiers:
        dt.ellipse(box, fill=fill_col, outline=out_col, width=2)
        # Highlight arcs
        dt.arc([box[0]+4, box[1]+2, box[2]-4, box[3]-6], start=190, end=350, fill=(120, 225, 110, 200), width=2)
    img_tree.save(f"{SPRITES_DIR}/bb_jungle_tree.png")

    # 7. Extraction Goal Beacon (40x64)
    img_goal = Image.new("RGBA", (40, 64), (0, 0, 0, 0))
    dg = ImageDraw.Draw(img_goal)
    # Outpost Communications Antenna Mast
    dg.rectangle([18, 8, 21, 58], fill=(95, 105, 115, 255), outline=(55, 62, 70, 255))
    # Concrete base
    dg.rectangle([8, 56, 31, 63], fill=(80, 85, 90, 255), outline=(45, 50, 55, 255), width=2)
    # Cross struts
    for sy in [20, 32, 44]:
        dg.line([(12, sy), (27, sy)], fill=(120, 130, 140, 255), width=2)
        dg.line([(12, sy-4), (27, sy+4)], fill=(80, 90, 100, 255))
    # Top radar dish / military radio dome
    dg.ellipse([14, 4, 25, 15], fill=(70, 80, 90, 255), outline=(40, 48, 55, 255))
    # Glowing Green Extraction Beacon
    dg.ellipse([16, 0, 23, 7], fill=(0, 255, 130, 255), outline=(200, 255, 220, 255))
    # Flagpole & Pennant
    dg.rectangle([21, 10, 36, 20], fill=(225, 45, 55, 230), outline=(160, 25, 35, 255))
    dg.polygon([(36, 10), (32, 15), (36, 20)], fill=(0, 0, 0, 0)) # notch
    img_goal.save(f"{SPRITES_DIR}/bb_extraction_beacon.png")

    # 8. Parallax distant green hills backdrop (320x180)
    img_hills = Image.new("RGBA", (320, 180), (0, 0, 0, 0))
    dh = ImageDraw.Draw(img_hills)
    # Distant misty hills layer
    dh.chord([-40, 60, 200, 220], start=180, end=360, fill=(45, 75, 70, 180))
    dh.chord([120, 80, 360, 240], start=180, end=360, fill=(40, 70, 65, 180))
    # Midground lush green hills
    dh.chord([-20, 100, 160, 240], start=180, end=360, fill=(35, 95, 60, 220))
    dh.chord([100, 110, 260, 250], start=180, end=360, fill=(30, 88, 55, 220))
    dh.chord([200, 95, 350, 240], start=180, end=360, fill=(38, 102, 64, 220))
    img_hills.save(f"{SPRITES_DIR}/bb_hills_bg.png")

def main():
    print("Generating Bullet Betrayal assets...")
    create_shoot_button()
    create_player_soldier()
    create_enemy_soldier()
    create_bullets()
    create_ammo_crate()
    create_environment_tiles()
    print("All Bullet Betrayal assets generated successfully!")

if __name__ == "__main__":
    main()
