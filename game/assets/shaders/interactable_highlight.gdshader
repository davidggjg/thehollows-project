shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform bool highlighted = false;
uniform vec4 highlight_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float highlight_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	ALBEDO = (albedo * tex).rgb;
	if (highlighted) {
		float pulse = sin(TIME * 3.0) * 0.5 + 0.5;
		EMISSION = highlight_color.rgb * pulse * highlight_strength;
	} else {
		EMISSION = vec3(0.0);
	}
	ROUGHNESS = 0.8;
	METALLIC  = 0.0;
}
