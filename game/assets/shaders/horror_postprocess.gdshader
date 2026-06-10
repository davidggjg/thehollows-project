// ═══════════════════════════════════════════════════════
//  HORROR POST-PROCESSING SHADER
//  Driven by FearSystem global shader parameters
//  Effects: vignette, chromatic aberration, noise grain,
//           distortion, desaturation, blur at low sanity
// ═══════════════════════════════════════════════════════
shader_type canvas_item;

global uniform float fear_level   : hint_range(0.0, 1.0) = 0.0;
global uniform float sanity_level : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float time_offset = 0.0;

// ── Noise ────────────────────────────────────────────────
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// ── Chromatic Aberration ─────────────────────────────────
vec3 chromatic_aberration(sampler2D tex, vec2 uv, float strength) {
	vec2 offset = vec2(strength * 0.001, 0.0);
	float r = texture(tex, uv + offset).r;
	float g = texture(tex, uv).g;
	float b = texture(tex, uv - offset).b;
	return vec3(r, g, b);
}

// ── Vignette ─────────────────────────────────────────────
float vignette(vec2 uv, float intensity) {
	uv = (uv - 0.5) * 2.0;
	return clamp(1.0 - dot(uv, uv) * intensity, 0.0, 1.0);
}

// ── Screen Warp (sanity distortion) ──────────────────────
vec2 warp(vec2 uv, float amount, float time) {
	float wave_x = sin(uv.y * 20.0 + time * 3.0) * amount;
	float wave_y = cos(uv.x * 15.0 + time * 2.0) * amount;
	return uv + vec2(wave_x, wave_y);
}

void fragment() {
	float fear   = fear_level;
	float sanity = sanity_level;
	float insane = 1.0 - sanity;
	float time   = TIME + time_offset;

	vec2 uv = SCREEN_UV;

	// ── Warp at low sanity ────────────────────────────────
	if (insane > 0.3) {
		float warp_amount = (insane - 0.3) * 0.008;
		uv = warp(uv, warp_amount, time);
	}

	// ── Chromatic aberration scales with fear ─────────────
	float aberration = fear * 12.0 + insane * 6.0;
	vec3 col = chromatic_aberration(SCREEN_TEXTURE, uv, aberration);

	// ── Film grain ────────────────────────────────────────
	float grain_strength = 0.03 + fear * 0.06 + insane * 0.08;
	float grain = hash(uv + fract(time * 0.1)) * grain_strength;
	col += vec3(grain - grain_strength * 0.5);

	// ── Desaturation at high fear ─────────────────────────
	float desat = fear * 0.5 + insane * 0.3;
	float luma  = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(luma), desat);

	// ── Blood-red tint at extreme fear ────────────────────
	float red_tint = smoothstep(0.7, 1.0, fear);
	col = mix(col, col * vec3(1.2, 0.7, 0.7), red_tint * 0.3);

	// ── Vignette ──────────────────────────────────────────
	float vig_intensity = 0.2 + fear * 1.2 + insane * 0.5;
	col *= vignette(SCREEN_UV, vig_intensity);

	// ── Pulse at heartbeat rate (fear > 0.8) ──────────────
	if (fear > 0.8) {
		float pulse = sin(time * (8.0 + fear * 6.0)) * 0.5 + 0.5;
		float pulse_str = (fear - 0.8) * 5.0 * 0.04;
		col *= 1.0 - pulse * pulse_str;
	}

	// ── Dark flickering at very low sanity ────────────────
	if (insane > 0.8) {
		float flicker = step(0.98, hash(vec2(floor(time * 15.0), 0.0)));
		col *= 1.0 - flicker * 0.7;
	}

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
