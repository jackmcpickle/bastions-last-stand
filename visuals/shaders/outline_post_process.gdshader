shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform float depth_threshold : hint_range(0.0, 0.01) = 0.001;
uniform float normal_threshold : hint_range(0.0, 1.0) = 0.5;
uniform vec4 outline_color : source_color = vec4(0.1, 0.1, 0.15, 1.0);
uniform float outline_width : hint_range(1.0, 3.0) = 1.0;

float get_depth(vec2 uv) {
	return texture(depth_texture, uv).r;
}

void fragment() {
	vec2 pixel_size = SCREEN_PIXEL_SIZE * outline_width;
	vec4 color = texture(screen_texture, SCREEN_UV);

	// Sample depth in cardinal directions
	float depth_center = get_depth(SCREEN_UV);
	float depth_up = get_depth(SCREEN_UV + vec2(0.0, -pixel_size.y));
	float depth_down = get_depth(SCREEN_UV + vec2(0.0, pixel_size.y));
	float depth_left = get_depth(SCREEN_UV + vec2(-pixel_size.x, 0.0));
	float depth_right = get_depth(SCREEN_UV + vec2(pixel_size.x, 0.0));

	// Calculate depth difference
	float depth_diff = 0.0;
	depth_diff += abs(depth_center - depth_up);
	depth_diff += abs(depth_center - depth_down);
	depth_diff += abs(depth_center - depth_left);
	depth_diff += abs(depth_center - depth_right);

	// Edge detection
	float edge = step(depth_threshold, depth_diff);

	// Mix outline
	COLOR = mix(color, outline_color, edge);
}
