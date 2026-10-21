shader_type canvas_item;
// The page: a warm paper ground with a faint, still grain. It never boils; only the ink does.

/** The paper's colour. */
uniform vec4 paper_color : source_color = vec4(0.9608, 0.9490, 0.9137, 1.0);
/** Size of the page in canvas pixels, so the grain keeps its size at any window size. */
uniform vec2 page_size = vec2(1920.0, 1080.0);
/** Strength of the fine tooth of the paper. */
uniform float tooth_strength : hint_range(0.0, 0.2, 0.002) = 0.022;
/** Size of the tooth, in canvas pixels. */
uniform float tooth_scale : hint_range(0.5, 8.0, 0.1) = 1.6;
/** Strength of the broad, cloudy unevenness of the paper. */
uniform float cloud_strength : hint_range(0.0, 0.2, 0.002) = 0.018;
/** Size of the clouds, in canvas pixels. */
uniform float cloud_scale : hint_range(20.0, 800.0, 1.0) = 260.0;
/** Strength of the faint fibres running across the paper. */
uniform float fibre_strength : hint_range(0.0, 0.2, 0.002) = 0.006;
/** Length of the fibres, in canvas pixels. */
uniform float fibre_scale : hint_range(4.0, 200.0, 1.0) = 24.0;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		total += value_noise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return total;
}

void fragment() {
	vec2 p = UV * page_size;
	float tooth = value_noise(p / tooth_scale) - 0.5;
	float cloud = fbm(p / cloud_scale) - 0.5;
	float fibre = value_noise(vec2(p.x / fibre_scale, p.y / (fibre_scale * 0.15))) - 0.5;
	float shade = 1.0 + tooth * tooth_strength * 2.0 + cloud * cloud_strength * 2.0 + fibre * fibre_strength * 2.0;
	COLOR = vec4(paper_color.rgb * shade, 1.0);
}
