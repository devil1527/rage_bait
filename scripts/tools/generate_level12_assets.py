import os
from PIL import Image, ImageDraw

os.makedirs("assets/sprites", exist_ok=True)

def create_steam_vent():
    # 32x24 industrial steam vent nozzle
    img = Image.new("RGBA", (32, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # 1. Base mounting flange / pipe (iron & brass)
    d.rectangle([2, 14, 29, 23], fill=(32, 28, 40, 255), outline=(18, 14, 26, 255))
    # Brass reinforcement band
    d.rectangle([4, 16, 27, 21], fill=(180, 110, 30, 255), outline=(120, 70, 15, 255))
    # Rivets
    d.point((6, 18), fill=(240, 190, 70, 255))
    d.point((13, 18), fill=(240, 190, 70, 255))
    d.point((18, 18), fill=(240, 190, 70, 255))
    d.point((25, 18), fill=(240, 190, 70, 255))
    
    # 2. Upper tapered nozzle
    d.polygon([(5, 14), (26, 14), (22, 4), (9, 4)], fill=(44, 38, 54, 255), outline=(22, 18, 30, 255))
    # Nozzle rim lip
    d.rectangle([8, 2, 23, 4], fill=(60, 52, 72, 255), outline=(28, 22, 38, 255))
    # Nozzle orifice (dark interior)
    d.rectangle([10, 0, 21, 2], fill=(14, 10, 20, 255))
    
    # 3. Pressure gauge dial (center front)
    d.ellipse([12, 7, 19, 14], fill=(230, 220, 200, 255), outline=(60, 40, 20, 255))
    # Gauge needle (warning orange)
    d.line([(15, 11), (17, 8)], fill=(220, 50, 20, 255))
    # Warning LED beacon right next to dial
    d.rectangle([22, 8, 24, 10], fill=(255, 140, 20, 255), outline=(140, 60, 0, 255))
    
    img.save("assets/sprites/steam_vent.png")
    print("Created assets/sprites/steam_vent.png")

def create_steam_plume():
    # 32x96 vertical high-pressure steam plume
    img = Image.new("RGBA", (32, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    import math

    for y in range(96):
        # Base is narrow at nozzle (y=95), expands upward towards y=0
        norm_y = (95 - y) / 95.0 # 0 at bottom, 1 at top
        half_w = 4.0 + (norm_y * 11.0) # expands from width 8 to 30
        
        # Turbulent wave effect
        wobble = math.sin(y * 0.28) * 1.5
        cx = 16.0 + wobble
        
        x0_out = max(0, int(cx - half_w))
        x1_out = min(31, int(cx + half_w))
        
        # Outer thermal halo (warning hot amber / faint steam mist)
        alpha_out = int(140 * (1.0 - norm_y * 0.45))
        d.line([(x0_out, y), (x1_out, y)], fill=(255, 160, 50, alpha_out))
        
        # Mid steam envelope (bright boiling vapor)
        x0_mid = max(2, int(cx - half_w * 0.72))
        x1_mid = min(29, int(cx + half_w * 0.72))
        alpha_mid = int(210 * (1.0 - norm_y * 0.35))
        d.line([(x0_mid, y), (x1_mid, y)], fill=(220, 240, 255, alpha_mid))
        
        # Core superheated jet (white-hot plasma steam)
        x0_core = max(5, int(cx - half_w * 0.38))
        x1_core = min(26, int(cx + half_w * 0.38))
        alpha_core = int(250 * (1.0 - norm_y * 0.25))
        d.line([(x0_core, y), (x1_core, y)], fill=(255, 255, 255, alpha_core))

    img.save("assets/sprites/steam_plume.png")
    print("Created assets/sprites/steam_plume.png")

def create_pressure_piston():
    # 32x48 heavy pneumatic piston head with hazard stripes
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # 1. Piston chrome cylinder rod (upper half)
    d.rectangle([11, 0, 20, 22], fill=(190, 195, 210, 255), outline=(100, 105, 120, 255))
    # Chrome shine reflection line
    d.line([(13, 0), (13, 22)], fill=(245, 250, 255, 255))
    d.line([(14, 0), (14, 22)], fill=(245, 250, 255, 255))
    
    # 2. Heavy steel ram block (lower half)
    d.rectangle([2, 22, 29, 45], fill=(38, 34, 46, 255), outline=(20, 16, 26, 255))
    
    # 3. Yellow / black industrial hazard stripes across ram block
    for i in range(-2, 7):
        ox = i * 8
        d.line([(max(3, ox), 24), (min(28, ox + 14), 38)], fill=(240, 180, 20, 255), width=3)
    
    # 4. Heavy hardened steel impact plate on bottom edge
    d.rectangle([1, 44, 30, 47], fill=(60, 55, 70, 255), outline=(24, 20, 32, 255))
    # Rivets on impact plate
    d.point((4, 45), fill=(200, 190, 170, 255))
    d.point((15, 45), fill=(200, 190, 170, 255))
    d.point((27, 45), fill=(200, 190, 170, 255))
    
    img.save("assets/sprites/pressure_piston.png")
    print("Created assets/sprites/pressure_piston.png")

if __name__ == "__main__":
    create_steam_vent()
    create_steam_plume()
    create_pressure_piston()
