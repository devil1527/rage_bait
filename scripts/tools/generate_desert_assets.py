"""
Asset generator for Bullet Betrayal - World 2: Desert Outpost (Stage 6: Dune Patrol)
Generates crisp, seamless pixel-art desert terrain tiles, layered parallax dune/mesa
backdrops, and subtle desert props matching World 1's retro pixel density.
"""
import math
import os
from PIL import Image, ImageDraw

SPRITES_DIR = "assets/sprites"
os.makedirs(SPRITES_DIR, exist_ok=True)


def _mesa_profile(x: float, cx: float, half_top: float, base_half: float, top_y: float, base_y: float) -> float:
	d = abs(x - cx)
	if d <= half_top:
		return top_y
	if d >= base_half:
		return base_y
	# Smooth concave talus slope from mesa cap down to valley floor
	t = (d - half_top) / max(1.0, (base_half - half_top))
	# Two-tier desert butte step for authentic sandstone silhouette
	if t < 0.22:
		return top_y + (base_y - top_y) * (t / 0.22) * 0.42
	if t < 0.36:
		return top_y + (base_y - top_y) * 0.42
	rem = (t - 0.36) / 0.64
	return top_y + (base_y - top_y) * (0.42 + 0.58 * (rem ** 0.75))


def create_desert_terrain_tiles() -> None:
	# 1. Desert Sand Top Crust (32x32) — strictly seamless horizontally
	img_top = Image.new("RGBA", (32, 32), (138, 86, 42, 255))
	dt = ImageDraw.Draw(img_top)

	# Sunlit sand ridge & top crust (Y=0..10)
	for x in range(32):
		ripple = 1 if (x % 8 in (2, 3, 4)) else 0
		dt.point((x, 0), fill=(248, 210, 136, 255))
		dt.point((x, 1), fill=(236, 190, 110, 255))
		dt.line([(x, 2), (x, 5 + ripple)], fill=(216, 160, 82, 255))
		sand_bottom = 8 + ripple + (1 if x % 5 == 0 else 0)
		dt.line([(x, 6 + ripple), (x, sand_bottom)], fill=(184, 126, 60, 255))
		# Crisp drop-shadow lip under sand overhang
		dt.point((x, sand_bottom + 1), fill=(112, 66, 30, 255))

	# Fine desert grit & sunlit sand pebbles
	for px, py in [(4, 3), (12, 4), (20, 3), (28, 4), (8, 6), (17, 6), (25, 7)]:
		dt.point((px, py), fill=(246, 208, 140, 255))
	for px, py in [(2, 7), (14, 8), (22, 7), (30, 8)]:
		dt.point((px, py), fill=(154, 100, 48, 255))

	# Upper packed sandstone strata (Y=12..31)
	dt.rectangle([2, 14, 12, 20], fill=(154, 98, 50, 255), outline=(106, 62, 28, 255))
	dt.rectangle([16, 13, 29, 21], fill=(128, 78, 38, 255), outline=(100, 58, 26, 255))
	dt.rectangle([5, 23, 19, 29], fill=(146, 92, 46, 255), outline=(106, 62, 28, 255))
	dt.rectangle([22, 24, 30, 30], fill=(122, 72, 34, 255), outline=(96, 54, 24, 255))
	dt.line([(0, 15), (0, 20)], fill=(106, 62, 28, 255))
	dt.line([(31, 15), (31, 20)], fill=(106, 62, 28, 255))
	dt.point((7, 16), fill=(176, 118, 64, 255))
	dt.point((24, 16), fill=(162, 106, 54, 255))
	dt.point((12, 25), fill=(168, 112, 58, 255))
	img_top.save(f"{SPRITES_DIR}/bb_desert_sand_top.png")

	# 2. Subsurface Sandstone Strata (32x32) — matches lower tone of sand_top seamlessly
	img_sub = Image.new("RGBA", (32, 32), (124, 74, 36, 255))
	ds = ImageDraw.Draw(img_sub)
	ds.rectangle([0, 0, 31, 1], fill=(108, 62, 30, 255))
	ds.rectangle([0, 15, 31, 16], fill=(104, 60, 28, 255))
	ds.rectangle([2, 3, 14, 12], fill=(138, 86, 44, 255), outline=(98, 56, 26, 255))
	ds.rectangle([17, 4, 29, 13], fill=(116, 68, 32, 255), outline=(94, 54, 24, 255))
	ds.rectangle([4, 18, 18, 28], fill=(134, 82, 42, 255), outline=(98, 56, 26, 255))
	ds.rectangle([21, 19, 30, 29], fill=(114, 66, 32, 255), outline=(92, 52, 24, 255))
	ds.point((6, 6), fill=(154, 98, 50, 255))
	ds.point((23, 7), fill=(142, 88, 44, 255))
	ds.point((11, 21), fill=(150, 94, 48, 255))
	ds.point((25, 22), fill=(138, 84, 42, 255))
	img_sub.save(f"{SPRITES_DIR}/bb_desert_subsurface.png")


def create_desert_parallax_layers() -> None:
	# 3. Far Desert Mesas & Distant Canyon Horizon (512x160) — strictly seamless H
	w_far, h_far = 512, 160
	img_far = Image.new("RGBA", (w_far, h_far), (0, 0, 0, 0))
	df = ImageDraw.Draw(img_far)

	for x in range(w_far):
		ang1 = 2.0 * math.pi * x / w_far
		base_horizon = 98.0 - 8.0 * math.sin(ang1 + 0.3)
		m1 = _mesa_profile(float(x), 115.0, 26.0, 74.0, 44.0, base_horizon)
		m2 = _mesa_profile(float(x), 360.0, 34.0, 88.0, 52.0, base_horizon)
		y0 = int(round(min(base_horizon, m1, m2)))

		# Dusty twilight sandstone rim & silhouette
		df.line([(x, y0), (x, min(h_far - 1, y0 + 2))], fill=(184, 108, 60, 225))
		if y0 + 3 < h_far:
			df.line([(x, y0 + 3), (x, h_far - 1)], fill=(128, 70, 40, 230))
		# Horizontal rock ledge strata line on tall mesas
		if y0 < 70 and y0 + 18 < h_far:
			df.line([(x, 66), (x, 67)], fill=(156, 88, 48, 210))

	img_far.save(f"{SPRITES_DIR}/bb_desert_dunes_far.png")

	# 4. Midground Smooth Sweeping Sand Dunes (512x128) — strictly seamless H, smooth shading
	w_mid, h_mid = 512, 128
	img_mid = Image.new("RGBA", (w_mid, h_mid), (0, 0, 0, 0))
	dm = ImageDraw.Draw(img_mid)

	for x in range(w_mid):
		a1 = 2.0 * math.pi * x / w_mid
		a2 = 4.0 * math.pi * x / w_mid
		# Asymmetric desert wind-dune profile: gentle rise, soft dip
		crest_y = 48.0 + 13.0 * math.sin(a1 + 0.5) + 6.0 * math.sin(a2 - 0.3)
		y0 = int(round(crest_y))

		# Continuous smooth slope-based color interpolation (no hard vertical bands!)
		deriv = 13.0 * math.cos(a1 + 0.5) * (2.0 * math.pi / w_mid) + 6.0 * math.cos(a2 - 0.3) * (4.0 * math.pi / w_mid)
		light = max(-1.0, min(1.0, -deriv / 0.25))  # +1 = sunlit left slope, -1 = shaded right slope

		r_crest = int(208 + 18 * light)
		g_crest = int(134 + 14 * light)
		b_crest = int(68 + 8 * light)
		dm.line([(x, y0), (x, min(h_mid - 1, y0 + 2))], fill=(r_crest, g_crest, b_crest, 245))

		r_body = int(154 + 16 * light)
		g_body = int(92 + 12 * light)
		b_body = int(44 + 6 * light)
		dm.line([(x, y0 + 3), (x, h_mid - 1)], fill=(r_body, g_body, b_body, 250))

	img_mid.save(f"{SPRITES_DIR}/bb_desert_dunes_mid.png")


def create_desert_props() -> None:
	# 5. Small Desert Saguaro Cactus (20x36) — opaque bottom exact at y=35 (+18 from center)
	img_cac = Image.new("RGBA", (20, 36), (0, 0, 0, 0))
	dc = ImageDraw.Draw(img_cac)
	dc.rectangle([7, 4, 12, 35], fill=(64, 102, 48, 255), outline=(38, 64, 28, 255))
	dc.point((7, 4), fill=(0, 0, 0, 0))
	dc.point((12, 4), fill=(0, 0, 0, 0))
	dc.line([(9, 5), (9, 34)], fill=(94, 140, 68, 255))
	dc.rectangle([2, 13, 7, 17], fill=(64, 102, 48, 255), outline=(38, 64, 28, 255))
	dc.rectangle([2, 8, 5, 16], fill=(64, 102, 48, 255), outline=(38, 64, 28, 255))
	dc.point((2, 8), fill=(0, 0, 0, 0))
	dc.point((5, 8), fill=(0, 0, 0, 0))
	dc.line([(3, 9), (3, 14)], fill=(94, 140, 68, 255))
	dc.rectangle([12, 16, 17, 20], fill=(64, 102, 48, 255), outline=(38, 64, 28, 255))
	dc.rectangle([14, 10, 17, 19], fill=(64, 102, 48, 255), outline=(38, 64, 28, 255))
	dc.point((14, 10), fill=(0, 0, 0, 0))
	dc.point((17, 10), fill=(0, 0, 0, 0))
	dc.line([(15, 11), (15, 16)], fill=(94, 140, 68, 255))
	img_cac.save(f"{SPRITES_DIR}/bb_desert_cactus.png")

	# 6. Small Desert Sandstone Outcrop (32x18) — opaque bottom exact at y=17 (+9 from center)
	img_r = Image.new("RGBA", (32, 18), (0, 0, 0, 0))
	dr = ImageDraw.Draw(img_r)
	dr.polygon([(2, 17), (5, 9), (14, 5), (21, 7), (28, 12), (30, 17)], fill=(156, 98, 52, 255), outline=(92, 54, 26, 255))
	dr.polygon([(6, 17), (10, 11), (17, 10), (22, 14), (24, 17)], fill=(134, 80, 42, 255))
	dr.line([(7, 9), (14, 6), (20, 8)], fill=(208, 146, 86, 255))
	img_r.save(f"{SPRITES_DIR}/bb_desert_rock.png")


if __name__ == "__main__":
	create_desert_terrain_tiles()
	create_desert_parallax_layers()
	create_desert_props()
	print("Generated refined desert sprites.")
