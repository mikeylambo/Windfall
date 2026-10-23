extends RefCounted
class_name PixelCanvas

## A tiny pixel-art painting surface on top of Image.
## Painters work in texels; save()/to_texture() upscale with nearest filtering.
## Light comes from the top-left everywhere so all assets shade consistently.

const LIGHT := Vector3(-0.55, -0.7, 0.75)
const BAYER4 := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var img: Image
var w: int
var h: int
var rng := RandomNumberGenerator.new()


func _init(width: int, height: int, seed_value: int = 1) -> void:
	w = width
	h = height
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	rng.seed = seed_value


static func bayer(x: int, y: int) -> float:
	return (float(BAYER4[(y & 3) * 4 + (x & 3)]) + 0.5) / 16.0


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func px(x: int, y: int, c: Color) -> void:
	if not inside(x, y):
		return
	if c.a >= 0.999:
		img.set_pixel(x, y, c)
	elif c.a > 0.001:
		var under := img.get_pixel(x, y)
		if under.a <= 0.001:
			img.set_pixel(x, y, c)
		else:
			var out := under.lerp(Color(c.r, c.g, c.b, 1.0), c.a)
			out.a = maxf(under.a, c.a)
			img.set_pixel(x, y, out)


func get_px(x: int, y: int) -> Color:
	if not inside(x, y):
		return Color(0, 0, 0, 0)
	return img.get_pixel(x, y)


func is_solid(x: int, y: int) -> bool:
	return get_px(x, y).a > 0.5


func erase(x: int, y: int) -> void:
	if inside(x, y):
		img.set_pixel(x, y, Color(0, 0, 0, 0))


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			px(xx, yy, c)


func hline(x0: int, x1: int, y: int, c: Color) -> void:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		px(x, y, c)


func vline(x: int, y0: int, y1: int, c: Color) -> void:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		px(x, y, c)


func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		px(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func thick_line(x0: int, y0: int, x1: int, y1: int, c: Color, t: int = 2) -> void:
	for ox in t:
		for oy in t:
			line(x0 + ox, y0 + oy, x1 + ox, y1 + oy, c)


## Filled ellipse. Centers may be fractional so even-sized shapes stay symmetric.
func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / maxf(rx, 0.01)
			var ny := (y + 0.5 - cy) / maxf(ry, 0.01)
			if nx * nx + ny * ny <= 1.0:
				px(x, y, c)


## Ellipse shaded as a lit sphere with an ordered-dither ramp.
## ramp: dark -> light colors. bias shifts overall brightness.
func shade_ellipse(cx: float, cy: float, rx: float, ry: float, ramp: Array, bias: float = 0.0, rim: bool = true) -> void:
	var L := LIGHT.normalized()
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / maxf(rx, 0.01)
			var ny := (y + 0.5 - cy) / maxf(ry, 0.01)
			var d := nx * nx + ny * ny
			if d > 1.0:
				continue
			var nz := sqrt(maxf(1.0 - d, 0.0))
			var lum := Vector3(nx, ny, nz).dot(L) * 0.5 + 0.5 + bias
			# soft bounce light along the lower-right rim
			if rim and d > 0.7 and nx + ny > 0.6:
				lum += 0.12
			px(x, y, _ramp_dither(ramp, lum, x, y))


## Rectangle shaded like a rounded box (cylinder across x).
func shade_box(x0: int, y0: int, bw: int, bh: int, ramp: Array, bias: float = 0.0) -> void:
	for y in range(y0, y0 + bh):
		for x in range(x0, x0 + bw):
			var nx := ((x + 0.5 - x0) / float(bw)) * 2.0 - 1.0
			var ny := ((y + 0.5 - y0) / float(bh)) * 2.0 - 1.0
			var lum := 0.55 - nx * 0.35 - ny * 0.18 + bias
			px(x, y, _ramp_dither(ramp, lum, x, y))


func _ramp_dither(ramp: Array, lum: float, x: int, y: int) -> Color:
	var n := ramp.size()
	var f := clampf(lum, 0.0, 0.999) * float(n)
	var i := int(f)
	var frac := f - float(i)
	# only dither in a narrow band at the boundary for a clean, painterly look
	if frac > 0.72 and bayer(x, y) < (frac - 0.72) * 3.2:
		i += 1
	return ramp[clampi(i, 0, n - 1)]


## Filled polygon via scanline (even-odd).
func poly(points: PackedVector2Array, c: Color) -> void:
	if points.size() < 3:
		return
	var min_y := INF
	var max_y := -INF
	for p in points:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	for y in range(int(floor(min_y)), int(ceil(max_y)) + 1):
		var sy := y + 0.5
		var xs: Array[float] = []
		for i in points.size():
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			for x in range(int(round(xs[k])), int(round(xs[k + 1]))):
				px(x, y, c)
			k += 2


## Selective outline ("sel-out"): each edge pixel takes a darkened version of
## the color it borders, falling back to the shared outline tone. Gives the
## soft cozy outline Stardew-likes use instead of hard black lines.
func outline(base: Color = WPal.OUTLINE, selective: float = 0.55, diagonal: bool = false) -> void:
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			var best := Color(0, 0, 0, 0)
			var found := false
			var dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
			if diagonal:
				dirs += [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
			for d in dirs:
				var sx: int = x + d.x
				var sy: int = y + d.y
				if sx < 0 or sy < 0 or sx >= w or sy >= h:
					continue
				var c := src.get_pixel(sx, sy)
				if c.a > 0.5:
					best = c
					found = true
					break
			if found:
				var o := base.lerp(best.darkened(0.6), 1.0 - selective)
				o = base.lerp(o, 0.5)
				o.a = 1.0
				img.set_pixel(x, y, o)


## Darken the lowest solid pixel of each column run (contact shadow line).
func ground_contact(c: Color = WPal.OUTLINE) -> void:
	for x in w:
		for y in range(h - 1, -1, -1):
			if is_solid(x, y):
				img.set_pixel(x, y, c)
				break


## Sprinkle random pixels inside the solid area.
func speckle(colors: Array, density: float, rect_area: Rect2i = Rect2i(), only_solid: bool = true) -> void:
	var r := rect_area if rect_area.size != Vector2i.ZERO else Rect2i(0, 0, w, h)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if only_solid and not is_solid(x, y):
				continue
			if rng.randf() < density:
				px(x, y, colors[rng.randi() % colors.size()])


## Recolor every solid pixel by multiplying with tint.
func tint(t: Color, amount: float = 1.0) -> void:
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var n := c.lerp(Color(c.r * t.r, c.g * t.g, c.b * t.b, c.a), amount)
				img.set_pixel(x, y, n)


func blit(other: PixelCanvas, ox: int, oy: int) -> void:
	for y in other.h:
		for x in other.w:
			var c := other.img.get_pixel(x, y)
			if c.a > 0.0:
				px(ox + x, oy + y, c)


func flipped_h() -> PixelCanvas:
	var c := PixelCanvas.new(w, h)
	c.img = img.duplicate() as Image
	c.img.flip_x()
	return c


func scaled_image(k: int) -> Image:
	var out := img.duplicate() as Image
	if k > 1:
		out.resize(w * k, h * k, Image.INTERPOLATE_NEAREST)
	return out


func save(path: String, k: int = 1) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	scaled_image(k).save_png(path)


func to_texture(k: int = 1) -> ImageTexture:
	return ImageTexture.create_from_image(scaled_image(k))


## Pack equally-sized frames into a sheet: rows x cols.
static func pack(frames: Array, cols: int) -> PixelCanvas:
	if frames.is_empty():
		return PixelCanvas.new(1, 1)
	var fw: int = frames[0].w
	var fh: int = frames[0].h
	var rows := int(ceil(float(frames.size()) / float(cols)))
	var sheet := PixelCanvas.new(fw * cols, fh * rows)
	for i in frames.size():
		sheet.blit(frames[i], (i % cols) * fw, (i / cols) * fh)
	return sheet
