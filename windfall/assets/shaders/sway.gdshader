shader_type canvas_item;
// Wind sway for foliage: top of the sprite moves, base stays planted.
uniform float strength = 1.0;
uniform float phase = 0.0;

void vertex() {
	float h = 1.0 - UV.y; // 1 at top, 0 at base
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float w = sin(TIME * 1.6 + phase + world.x * 0.013) * 0.6 + sin(TIME * 2.7 + world.y * 0.02) * 0.4;
	VERTEX.x += w * h * h * 2.0 * strength;
}
