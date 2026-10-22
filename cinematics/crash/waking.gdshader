shader_type canvas_item;
// Waking up: a dark sheet over the page that clears unevenly, in blotches, from the middle out, the way
// heavy eyes open. The blotch edges start soft and sharpen as the eyes focus, and the pattern drifts.
// The rect's own colour is the darkness.

/** How far the eyes are open: 0 is all dark, 1 is all clear. */
uniform float clear : hint_range(0.0, 1.0, 0.001) = 0.0;
/** How soft the blotch edges are: high is a blur, low is in focus. */
uniform float softness : hint_range(0.0, 0.5, 0.001) = 0.3;
/** How far the blotch pattern has drifted, in canvas pixels. */
uniform vec2 drift = vec2(0.0);
/** Size of the blotches, in canvas pixels. */
uniform float blotch_scale : hint_range(20.0, 1000.0, 1.0) = 260.0;
/** How much the middle band clears before the edges, like eyelids opening. */
uniform float eyelid : hint_range(0.0, 1.0, 0.01) = 0.4;
/** Size of the page in canvas pixels, so the blotches keep their size at any window size. */
uniform vec2 page_size = vec2(1920.0, 1080.0);

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
	// Each octave is turned a little, so the noise's square grid does not line up into blocks.
	const mat2 TURN = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		total += value_noise(p) * amplitude;
		p = TURN * p * 2.07;
		amplitude *= 0.5;
	}
	return total;
}

void fragment() {
	vec2 p = UV * page_size + drift;
	float middle = 1.0 - abs(UV.y - 0.5) * 2.0;
	float field = mix(fbm(p / blotch_scale) * 1.6, middle, eyelid);
	// The field never rises above FIELD_TOP, so at clear 0 nothing opens and at clear 1 everything does.
	const float FIELD_TOP = 1.3;
	float threshold = FIELD_TOP + softness - clear * (FIELD_TOP + softness * 2.0);
	float open = smoothstep(threshold - softness, threshold + softness, field);
	COLOR = vec4(COLOR.rgb, COLOR.a * (1.0 - open));
}
