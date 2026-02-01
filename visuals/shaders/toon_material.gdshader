shader_type spatial;
render_mode ambient_light_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_softness : hint_range(0.0, 0.2) = 0.02;
uniform vec4 shadow_color : source_color = vec4(0.2, 0.2, 0.3, 1.0);

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);
	ALBEDO = tex_color.rgb * albedo_color.rgb;
	ALPHA = tex_color.a * albedo_color.a;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float light_amount = smoothstep(
		shadow_threshold - shadow_softness,
		shadow_threshold + shadow_softness,
		NdotL
	);

	vec3 lit_color = ALBEDO * LIGHT_COLOR * ATTENUATION;
	vec3 shadow_result = ALBEDO * shadow_color.rgb;

	DIFFUSE_LIGHT += mix(shadow_result, lit_color, light_amount);
}
