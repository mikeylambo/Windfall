extends RefCounted
class_name CreaturePainter

## Non-humanoid actors. The Gnawer is an armoured beetle-rat that chews
## through orchard roots. Its sheet follows the humanoid row layout so the same
## animator drives both.

const CHITIN := [Color("24120f"), Color("452116"), Color("6e341d"), Color("a0532a"), Color("d48a48")]
const BELLY := [Color("3a2a22"), Color("5c4434"), Color("806048")]


static func paint_gnawer(dir: int, pose: Dictionary) -> PixelCanvas:
	var c := PixelCanvas.new(CharacterPainter.FW, CharacterPainter.FH, 11)
	var step: int = pose.get("step", 0)
	var bob: int = pose.get("bob", 0)
	var bite: bool = pose.get("bite", false)
	var eat: bool = pose.get("eat", false)
	var hurt: bool = pose.get("hurt", false)
	var eye := Color("ffcf4a")

	match dir:
		CharacterPainter.Dir.DOWN, CharacterPainter.Dir.UP:
			var down := dir == CharacterPainter.Dir.DOWN
			var cy := 16.5 + bob
			# legs: three per side, alternating
			for i in 3:
				var ly := int(cy) - 2 + i * 3
				var off := (1 if (i + step) % 2 == 0 else 0) if step != 0 else 0
				c.rect(3 - off, ly, 2, 1, CHITIN[0])
				c.rect(15 + off, ly, 2, 1, CHITIN[0])
			if not down:
				c.shade_ellipse(10, cy - 6.5, 1.4, 2.4, BELLY)  # tail stub
			c.shade_ellipse(10, cy, 6.6, 5.4, CHITIN, 0.05)
			# plate seams
			c.vline(9, int(cy) - 4, int(cy) + 4, CHITIN[1])
			c.hline(5, 14, int(cy) + 1, CHITIN[1])
			c.px(7, int(cy) - 3, CHITIN[4])
			c.px(6, int(cy) - 2, CHITIN[4])
			if down:
				var hy := cy + 5.0
				c.shade_ellipse(10, hy, 3.6, 2.6, BELLY)
				c.px(8, int(hy), eye)
				c.px(11, int(hy), eye)
				var spread := 2 if bite or eat else 0
				c.line(8 - spread, int(hy) + 2, 9, int(hy) + 4, CHITIN[3])
				c.line(11 + spread, int(hy) + 2, 10, int(hy) + 4, CHITIN[3])
		CharacterPainter.Dir.SIDE:
			var cy2 := 17.0 + bob
			for i in 3:
				var lx := 6 + i * 4
				var lift := 1 if (i + step) % 2 == 0 and step != 0 else 0
				c.vline(lx, int(cy2) + 3, 23 - lift, CHITIN[0])
				c.px(lx + 1, 23 - lift, CHITIN[0])
			c.shade_ellipse(9, cy2, 7.2, 4.8, CHITIN, 0.05)
			c.hline(4, 14, int(cy2), CHITIN[1])
			c.px(6, int(cy2) - 3, CHITIN[4])
			c.px(7, int(cy2) - 3, CHITIN[4])
			var hx := 16.0 + (1.0 if bite else 0.0)
			c.shade_ellipse(hx, cy2 + 1.5, 2.8, 2.6, BELLY)
			c.px(int(hx) + 1, int(cy2) + 1, eye)
			var open := 2 if bite or eat else 0
			c.line(int(hx) + 2, int(cy2) + 2, int(hx) + 4, int(cy2) + 2 - open, CHITIN[3])
			c.line(int(hx) + 2, int(cy2) + 3, int(hx) + 4, int(cy2) + 4 + open, CHITIN[3])
			c.px(1, int(cy2) - 1, BELLY[1])
	c.outline(WPal.OUTLINE, 0.6)
	if hurt:
		CharacterPainter._hurt_flash(c)
	return c


static func gnawer_sheet() -> PixelCanvas:
	var frames: Array = []
	var blank := PixelCanvas.new(CharacterPainter.FW, CharacterPainter.FH)
	var dirs := [0, 1, 2]
	var rows := [
		[{}, {"bob": 1}],                                              # idle
		[{"step": 1}, {"step": 0, "bob": -1}, {"step": -1}, {"bob": -1}],  # walk
		[{"bob": 1}, {"bite": true}, {"bite": true, "bob": 1}],        # attack
	]
	for r in rows:
		for d in dirs:
			for i in 4:
				frames.append(paint_gnawer(d, r[i]) if i < r.size() else blank)
	# roll row: curled shell spin
	for f in 4:
		var c := PixelCanvas.new(CharacterPainter.FW, CharacterPainter.FH)
		c.shade_ellipse(10, 18.0, 6.0, 5.5, CHITIN, 0.05)
		var a := f * PI * 0.5
		c.line(10, 18, int(10 + cos(a) * 5), int(18 + sin(a) * 5), CHITIN[1])
		c.outline(WPal.OUTLINE, 0.6)
		frames.append(c)
	for d in dirs:   # eat
		frames += [paint_gnawer(d, {"eat": true}), paint_gnawer(d, {"eat": true, "bob": 1}), blank, blank]
	for d in dirs:   # cast (reuse a rear-up)
		frames += [paint_gnawer(d, {"bob": -1}), paint_gnawer(d, {"bob": -1, "bite": true}), blank, blank]
	for d in dirs:   # hurt
		frames += [paint_gnawer(d, {"hurt": true}), blank, blank, blank]
	# collapse: flipped on its back
	var dead := PixelCanvas.new(CharacterPainter.FW, CharacterPainter.FH)
	dead.shade_ellipse(10, 20.0, 6.6, 3.4, BELLY, 0.1)
	for i in 3:
		dead.vline(6 + i * 4, 15, 17, CHITIN[0])
	dead.outline(WPal.OUTLINE, 0.6)
	frames += [paint_gnawer(0, {"hurt": true, "bob": 1}), dead, blank, blank]
	return PixelCanvas.pack(frames, 4)
