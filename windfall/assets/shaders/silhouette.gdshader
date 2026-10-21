shader_type canvas_item;
// Codex silhouette: blacked-out shape with a faint light outline so the
// species' silhouette stays guessable.
uniform vec4 fill : source_color = vec4(0.07, 0.05, 0.09, 1.0);
uniform vec4 edge : source_color = vec4(0.85, 0.75, 0.6, 0.45);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * 3.0;
	if (c.a > 0.5) {
		COLOR = fill;
	} else {
		float n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		COLOR = n > 0.5 ? edge : vec4(0.0);
	}
}
