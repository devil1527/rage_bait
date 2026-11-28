"""Generate bespoke pixel-art Snow & Ice sprites for Bullet Betrayal World 3 (Stage 11)."""

from pathlib import Path
import math
from PIL import Image, ImageDraw

SPRITES_DIR = Path("c:/AntiGravity/Games/rage_bait/assets/sprites")


def _wrap_wave(x: int, width: int, a1: float, p1: float, a2: float, p2: float) -> float:
	t = (x / float(width)) * math.tau
	return a1 * math.sin(t + p1) + a2 * math.sin(2.0 * t + p2)


def create_snow_terrain_tiles() -> None:
	# 1. Snow-topped Mountain Slate Floor (32x32, seamless horizontally)
	w, h = 32, 32
	img_top = Image.new("RGBA", (w, h), (38, 48, 66, 255))
	dt = ImageDraw.Draw(img_top)

	# Subsurface stone block strata (wrapping cleanly across x=0..31)
	for y in range(10, h):
		for x in range(w):
			brick_row = (y - 10) // 7
			brick_x = (x + brick_row * 9) % 16
			brick_y = (y - 10) % 7
			if brick_y == 0 or brick_x == 0:
				col = (26, 34, 48, 255)
			elif brick_y == 1 and brick_x in (2, 3, 4, 11, 12):
				col = (68, 86, 110, 255)
			elif (x * 7 + y * 13) % 19 == 0:
				col = (56, 72, 94, 255)
			elif (x * 11 + y * 5) % 23 == 0:
				col = (30, 40, 56, 255)
			else:
				col = (44, 56, 76, 255)
			dt.point((x, y), fill=col)

	# Snow crust with undulating organic drift edge
	for x in range(w):
		drift = int(round(10.0 + _wrap_wave(x, w, 1.8, 0.4, 0.9, 1.9)))
		for y in range(0, drift):
			if y <= 2:
				# Bright windswept glacier crest
				col = (244, 250, 255, 255) if (x + y) % 5 != 0 else (228, 242, 255, 255)
			elif y <= drift - 3:
				col = (212, 232, 248, 255)
			elif y <= drift - 2:
				col = (158, 194, 224, 255)
			else:
				col = (104, 144, 180, 255)
			dt.point((x, y), fill=col)
		# Cast shadow just beneath the snow lip
		if drift < h:
			dt.point((x, drift), fill=(24, 32, 46, 255))
		if drift + 1 < h and x % 3 == 0:
			dt.point((x, drift + 1), fill=(72, 98, 128, 255))

	img_top.save(SPRITES_DIR / "bb_snow_top.png")

	# 2. Subsurface Mountain Slate Tile (32x32, seamless horizontally & vertically)
	img_sub = Image.new("RGBA", (w, h), (38, 48, 66, 255))
	ds = ImageDraw.Draw(img_sub)
	for y in range(h):
		for x in range(w):
			row = y // 8
			bx = (x + row * 8) % 16
			by = y % 8
			if by == 0 or bx == 0:
				col = (26, 34, 48, 255)
			elif by == 1 and 2 <= bx <= 13:
				col = (62, 78, 102, 255)
			elif (x * 5 + y * 9) % 17 == 0:
				col = (84, 114, 146, 255)  # Subtle frost vein
			elif (x * 13 + y * 3) % 21 == 0:
				col = (30, 38, 54, 255)
			else:
				col = (44, 56, 76, 255)
			ds.point((x, y), fill=col)

	img_sub.save(SPRITES_DIR / "bb_mountain_slate.png")

	# 3. Glacier Ice Surface Overlay (32x10, seamless horizontally)
	img_ice = Image.new("RGBA", (32, 10), (0, 0, 0, 0))
	di = ImageDraw.Draw(img_ice)
	for x in range(32):
		# Crisp reflective crystalline top rim
		di.point((x, 0), fill=(224, 248, 255, 245) if x % 4 != 0 else (255, 255, 255, 255))
		di.point((x, 1), fill=(158, 232, 252, 235))
		for y in range(2, 7):
			# Diagonal ice reflection bands
			diag = (x + y * 2) % 10
			if diag in (0, 1):
				col = (210, 246, 255, 230)
			elif diag in (2, 3):
				col = (118, 214, 244, 210)
			else:
				col = (74, 174, 222, 195)
			di.point((x, y), fill=col)
		# Frozen icicle-tooth bottom trim
		di.point((x, 7), fill=(48, 128, 180, 210))
		if x % 3 == 0:
			di.point((x, 8), fill=(138, 224, 248, 190))
		if x % 6 == 0:
			di.point((x, 9), fill=(210, 246, 255, 165))

	img_ice.save(SPRITES_DIR / "bb_ice_surface.png")


def create_snow_parallax_layers() -> None:
	# 4. Far Alpine Snow Peaks (512x160, seamless horizontally)
	w_far, h_far = 512, 160
	img_far = Image.new("RGBA", (w_far, h_far), (0, 0, 0, 0))
	df = ImageDraw.Draw(img_far)

	# Peaks as cyclic harmonic triangles so x=0 matches x=511 seamlessly
	peaks = [
		(64, 22, 92),
		(168, 36, 80),
		(276, 16, 104),
		(392, 30, 88),
		(472, 42, 74),
	]
	for x in range(w_far):
		best_y = h_far
		lit_side = True
		for px, py_top, half_w in peaks:
			dx = (x - px) % w_far
			if dx > w_far // 2:
				dx -= w_far
			adx = abs(dx)
			if adx <= half_w:
				# Jagged harmonic noise along slope (periodic in w_far)
				jag = int(round(3.0 * math.sin((x / w_far) * math.tau * 12.0 + px)))
				y_slope = py_top + int((adx / float(half_w)) * (h_far - py_top)) + jag
				y_slope = max(10, min(h_far - 1, y_slope))
				if y_slope < best_y:
					best_y = y_slope
					lit_side = dx <= 0
		if best_y < h_far:
			for y in range(best_y, h_far):
				depth = (y - best_y) / max(1.0, float(h_far - best_y))
				if y - best_y <= 3:
					col = (224, 240, 252, 245) if lit_side else (154, 184, 214, 245)
				elif lit_side:
					r = int(186 - 58 * depth)
					g = int(214 - 52 * depth)
					b = int(236 - 42 * depth)
					col = (r, g, b, 245)
				else:
					r = int(88 - 26 * depth)
					g = int(114 - 28 * depth)
					b = int(148 - 26 * depth)
					col = (r, g, b, 248)
				df.point((x, y), fill=col)

	img_far.save(SPRITES_DIR / "bb_snow_peaks_far.png")

	# 5. Mid Frosted Pine Ridges (512x128, seamless horizontally)
	w_mid, h_mid = 512, 128
	img_mid = Image.new("RGBA", (w_mid, h_mid), (0, 0, 0, 0))
	dm = ImageDraw.Draw(img_mid)
	for x in range(w_mid):
		ridge_h = int(
			round(
				46.0
				+ _wrap_wave(x, w_mid, 14.0, 0.2, 7.0, 1.4)
				+ 4.0 * math.sin((x / w_mid) * math.tau * 7.0)
			)
		)
		ridge_h = max(24, min(h_mid - 16, ridge_h))
		# Snow-dusted upper crest
		dm.line([(x, ridge_h), (x, min(h_mid - 1, ridge_h + 3))], fill=(144, 178, 208, 245))
		dm.point((x, ridge_h), fill=(198, 224, 244, 248))
		# Dark alpine slate ridge body
		for y in range(ridge_h + 4, h_mid):
			t = (y - ridge_h) / max(1.0, float(h_mid - ridge_h))
			r = int(42 - 14 * t)
			g = int(58 - 18 * t)
			b = int(82 - 20 * t)
			dm.point((x, y), fill=(r, g, b, 250))

		# Silhouette frosted pines every ~18 px
		if x % 18 == 9:
			tree_h = 12 + (x * 3) % 9
			for ty in range(tree_h):
				half_tw = max(1, (ty * 4) // max(1, tree_h))
				py = ridge_h - tree_h + ty
				if 0 <= py < h_mid:
					for tx in range(x - half_tw, x + half_tw + 1):
						wx = tx % w_mid
						if ty <= 2:
							dm.point((wx, py), fill=(184, 214, 238, 245))
						else:
							dm.point((wx, py), fill=(28, 46, 62, 248))

	img_mid.save(SPRITES_DIR / "bb_snow_ridges_mid.png")


def create_icicle_and_props() -> None:
	# 6. Hanging Glacier Icicle (18x34, opaque anchor at top y=0, point at y=33)
	img_ici = Image.new("RGBA", (18, 34), (0, 0, 0, 0))
	di = ImageDraw.Draw(img_ici)
	# Snow-ice anchor collar at top
	di.rectangle([2, 0, 15, 3], fill=(216, 238, 252, 255), outline=(42, 74, 108, 255))
	di.line([(3, 1), (14, 1)], fill=(248, 252, 255, 255))
	# Main tapering translucent/crystalline icicle cone + flanking mini spikes
	di.polygon(
		[(3, 3), (14, 3), (11, 20), (9, 33), (8, 33), (6, 20)],
		fill=(112, 208, 242, 255),
		outline=(26, 58, 92, 255),
	)
	# Flanking small crystal tips on sides
	di.polygon([(1, 3), (4, 3), (2, 13)], fill=(138, 222, 248, 255), outline=(26, 58, 92, 255))
	di.polygon([(13, 3), (16, 3), (15, 12)], fill=(86, 178, 220, 255), outline=(26, 58, 92, 255))
	# Gleaming left-facet specular highlight
	di.line([(5, 4), (7, 19), (8, 31)], fill=(236, 252, 255, 255))
	di.line([(6, 5), (7, 16)], fill=(196, 242, 255, 255))
	# Darker shadow facet along right edge
	di.line([(12, 5), (10, 20), (9, 30)], fill=(62, 138, 186, 255))
	img_ici.save(SPRITES_DIR / "bb_icicle.png")

	# 7. Frosted Alpine Pine (36x56, opaque bottom exact at y=55)
	img_p = Image.new("RGBA", (36, 56), (0, 0, 0, 0))
	dp = ImageDraw.Draw(img_p)
	# Dark trunk sitting flush on y=55
	dp.rectangle([15, 44, 20, 55], fill=(74, 52, 38, 255), outline=(36, 24, 18, 255))
	dp.line([(17, 45), (17, 54)], fill=(102, 74, 54, 255))
	# Three tiered evergreen boughs (bottom -> mid -> apex)
	tiers = [
		(46, 28, 14),
		(34, 18, 12),
		(22, 4, 9),
	]
	for y_bot, y_top, half_w in tiers:
		dp.polygon(
			[(18, y_top), (18 - half_w, y_bot), (18 + half_w, y_bot)],
			fill=(34, 82, 72, 255),
			outline=(16, 40, 38, 255),
		)
		# Left sunlit pine highlight
		dp.polygon(
			[(18, y_top + 1), (18 - half_w + 2, y_bot - 1), (18, y_bot - 1)],
			fill=(48, 108, 94, 255),
		)
		# Heavy snow-cap mantle draped on upper triangle
		snow_bot = y_top + (y_bot - y_top) // 2
		snow_hw = max(3, half_w // 2 + 1)
		dp.polygon(
			[(18, y_top), (18 - snow_hw, snow_bot), (18 - snow_hw // 2, snow_bot + 2), (18, snow_bot - 1), (18 + snow_hw // 2, snow_bot + 2), (18 + snow_hw, snow_bot)],
			fill=(226, 242, 252, 255),
			outline=(132, 168, 202, 255),
		)
		dp.line([(18, y_top + 1), (18 - snow_hw + 2, snow_bot - 1)], fill=(248, 252, 255, 255))
	img_p.save(SPRITES_DIR / "bb_snow_pine.png")

	# 8. Snow-capped Mountain Boulder (34x20, opaque bottom exact at y=19)
	img_r = Image.new("RGBA", (34, 20), (0, 0, 0, 0))
	dr = ImageDraw.Draw(img_r)
	dr.polygon(
		[(2, 19), (5, 10), (14, 5), (23, 7), (30, 12), (32, 19)],
		fill=(58, 72, 92, 255),
		outline=(26, 34, 48, 255),
	)
	dr.polygon([(7, 19), (12, 13), (21, 12), (27, 19)], fill=(42, 54, 72, 255))
	# Pillowy white-cyan snow cap across top facet
	dr.polygon(
		[(5, 10), (14, 5), (23, 7), (27, 11), (22, 12), (15, 10), (9, 12)],
		fill=(228, 242, 252, 255),
		outline=(138, 174, 206, 255),
	)
	dr.line([(9, 8), (14, 6), (22, 8)], fill=(250, 254, 255, 255))
	img_r.save(SPRITES_DIR / "bb_snow_rock.png")

	# 9. Frosted Outpost Barricade (36x26, opaque bottom exact at y=25)
	img_b = Image.new("RGBA", (36, 26), (0, 0, 0, 0))
	db = ImageDraw.Draw(img_b)
	# Legs flush to y=25
	db.rectangle([5, 14, 9, 25], fill=(82, 56, 38, 255), outline=(36, 24, 16, 255))
	db.rectangle([26, 14, 30, 25], fill=(82, 56, 38, 255), outline=(36, 24, 16, 255))
	# Steel armored rail with amber warning stripes
	db.rectangle([2, 6, 33, 15], fill=(74, 88, 108, 255), outline=(24, 32, 46, 255))
	for sx in (5, 13, 21, 29):
		db.polygon([(sx, 7), (sx + 3, 7), (sx + 1, 14), (sx - 2, 14)], fill=(236, 178, 44, 255))
	# Snow drift settled along top bar
	db.polygon(
		[(2, 6), (6, 3), (14, 4), (22, 3), (30, 4), (33, 6), (33, 8), (2, 8)],
		fill=(228, 242, 252, 255),
		outline=(122, 160, 196, 255),
	)
	db.line([(6, 4), (14, 5), (22, 4), (29, 5)], fill=(250, 254, 255, 255))
	img_b.save(SPRITES_DIR / "bb_snow_barricade.png")

	# 10. Frosted Warning Signpost (24x32, opaque bottom exact at y=31)
	img_s = Image.new("RGBA", (24, 32), (0, 0, 0, 0))
	ds2 = ImageDraw.Draw(img_s)
	ds2.rectangle([10, 14, 13, 31], fill=(86, 58, 38, 255), outline=(36, 24, 16, 255))
	ds2.polygon(
		[(12, 2), (21, 11), (12, 20), (3, 11)],
		fill=(238, 184, 46, 255),
		outline=(42, 30, 20, 255),
	)
	# Exclamation mark
	ds2.rectangle([11, 7, 12, 12], fill=(32, 24, 20, 255))
	ds2.rectangle([11, 14, 12, 15], fill=(32, 24, 20, 255))
	# Snow dusting on top triangle edges
	ds2.polygon([(12, 1), (19, 8), (16, 9), (12, 4), (8, 9), (5, 8)], fill=(234, 246, 255, 255))
	img_s.save(SPRITES_DIR / "bb_snow_sign.png")


if __name__ == "__main__":
	SPRITES_DIR.mkdir(parents=True, exist_ok=True)
	create_snow_terrain_tiles()
	create_snow_parallax_layers()
	create_icicle_and_props()
	print("Generated Snow & Ice sprites for Stage 11.")
