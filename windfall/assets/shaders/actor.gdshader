shader_type canvas_item;
// Shared actor shader: hit-flash + tri-colour digestion rim glow.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int rim_count = 0;
uniform vec4 rim_a : source_color = vec4(1.0);
uniform vec4 rim_b : source_color = vec4(1.0);
uniform vec4 rim_c : source_color = vec4(1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform float ghost = 0.0;            // >0 renders as a flat afterimage
uniform vec4 ghost_color : source_color = vec4(1.0);

vec4 rim_at(float t) {
	if (rim_count <= 1) return rim_a;
	float k = fract(t) * float(rim_count);
	if (k < 1.0) return mix(rim_a, rim_b, smoothstep(0.7, 1.0, k));
	if (k < 2.0) return mix(rim_b, rim_count > 2 ? rim_c : rim_a, smoothstep(1.7, 2.0, k));
	return mix(rim_c, rim_a, smoothstep(2.7, 3.0, k));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (ghost > 0.0) {
		COLOR = vec4(ghost_color.rgb, c.a * ghost);
	} else {
		if (rim_strength > 0.0 && rim_count > 0 && c.a < 0.5) {
			vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
			float n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
				+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
			if (n > 0.5) {
				// colour sweeps around the silhouette over time
				float t = TIME * 0.6 + UV.y * 3.0;
				vec4 r = rim_at(t);
				float pulse = 0.65 + 0.35 * sin(TIME * 5.0);
				c = vec4(r.rgb, rim_strength * pulse);
			}
		}
		c.rgb = mix(c.rgb, flash_color.rgb, flash * step(0.01, c.a));
		COLOR = c * COLOR;
	}
}
