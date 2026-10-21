shader_type canvas_item;
// Draws InkBrush geometry: a soft antialiased edge across each line, a faint grain along it,
// and an inky dissolve that eats a drawing away. UV.y runs 0 to 1 across a line, and UV.x is the
// distance along it. Fills and dots use a negative UV.x, which skips the grain.

/** Softness of a line's edge, in screen pixels. */
uniform float edge_softness : hint_range(0.0, 4.0, 0.05) = 1.0;
/** How unevenly the ink lies along a line: 0 is perfectly even. */
uniform float grain : hint_range(0.0, 0.5, 0.01) = 0.1;
/** Length of the grain's patches along a line, in pixels. */
uniform float grain_scale : hint_range(1.0, 40.0, 0.5) = 6.0;
/** Eats the drawing away like ink soaking into paper: 0 is whole, 1 is gone. */
uniform float dissolve : hint_range(0.0, 1.0, 0.001) = 0.0;
/** Size of the dissolve's blotches, in pixels. */
uniform float dissolve_scale : hint_range(2.0, 80.0, 0.5) = 14.0;
/** Width of the soft rim where the dissolve is eating, as a fraction. */
uniform float dissolve_softness : hint_range(0.0, 0.5, 0.01) = 0.08;

varying vec2 local_position;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float across = abs(UV.y * 2.0 - 1.0);
	float edge_width = max(fwidth(across) * edge_softness, 0.0001);
	float coverage = clamp((1.0 - across) / edge_width, 0.0, 1.0);

	if (UV.x >= 0.0) {
		coverage *= 1.0 - grain * value_noise(vec2(UV.x / grain_scale, UV.y * 2.0));
	}

	if (dissolve > 0.0) {
		float blotch = value_noise(local_position / dissolve_scale) * 0.7
				+ value_noise(local_position / (dissolve_scale * 0.35)) * 0.3;
		float threshold = dissolve * (1.0 + dissolve_softness * 2.0) - dissolve_softness;
		coverage *= smoothstep(threshold, threshold + dissolve_softness, blotch);
	}

	COLOR.a *= coverage;
}
