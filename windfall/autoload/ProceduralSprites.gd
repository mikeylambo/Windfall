## ProceduralSprites.gd — registered as the `Art` autoload.
##
## WINDFALL's art is hand-authored pixel art drawn in code by the painters in
## scripts/Windfall/Art/ and baked to PNG by tools/bake_art.gd. This autoload is
## the runtime catalog: it loads (and caches) those sheets and builds the
## common sprite nodes so every actor uses the same origin/scale conventions.
##
## Rebake after editing a painter:
##   godot --headless -s res://tools/bake_art.gd
extends Node

const ROOT := "res://assets/art/"
const ACTOR_SHADER := preload("res://assets/shaders/actor.gdshader")
const SWAY_SHADER := preload("res://assets/shaders/sway.gdshader")

## Humanoid sheet rows (4 frames per row), mirrored in tools/bake_art.gd.
const ROWS := {
	"idle": 0, "walk": 3, "attack": 6, "roll": 9, "eat": 10,
	"cast": 13, "hurt": 16, "collapse": 19,
}
const ROW_FRAMES := {
	"idle": 2, "walk": 4, "attack": 3, "roll": 4, "eat": 2, "cast": 2, "hurt": 1, "collapse": 2,
}

var _cache: Dictionary = {}


func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var full := ROOT + path + ".png"
	var t: Texture2D = load(full) if ResourceLoader.exists(full) else null
	if t == null:
		push_warning("Art: missing texture " + full)
	_cache[path] = t
	return t


## Sprite anchored at its feet. `foot` is the texel row of the feet in the frame.
func sprite(path: String, hframes: int = 1, vframes: int = 1, foot := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex(path)
	s.hframes = hframes
	s.vframes = vframes
	s.centered = false
	if s.texture:
		var fw := s.texture.get_width() / hframes
		var fh := s.texture.get_height() / vframes
		if foot == Vector2.ZERO:
			foot = Vector2(fw * 0.5, fh)
		s.offset = -foot
	return s


## Character sprite using the shared 20x26 texel humanoid frame (2x baked).
func actor_sprite(sheet: String) -> Sprite2D:
	var s := sprite("characters/" + sheet, 4, 20, Vector2(CharacterPainter.CX * 2, (CharacterPainter.FY + 1) * 2))
	var m := ShaderMaterial.new()
	m.shader = ACTOR_SHADER
	s.material = m
	return s


func shadow(size: String = "small") -> Sprite2D:
	var s := sprite("props/shadow_" + size)
	s.centered = true
	s.offset = Vector2.ZERO
	s.z_index = -1
	return s


func glow_texture() -> Texture2D:
	return tex("fx/glow")


func family_color(fam: int, idx: int = 2) -> Color:
	return WPal.element(fam, idx)


func sway_material(strength: float = 1.0, phase: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SWAY_SHADER
	m.set_shader_parameter("strength", strength)
	m.set_shader_parameter("phase", phase)
	return m
