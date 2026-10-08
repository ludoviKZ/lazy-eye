shader_type spatial;
render_mode unshaded, depth_test_disabled, skip_vertex_transform, cull_disabled;
uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

// CONTROLS:
const float curvature = 9.0;
const float horizontal_lines = 180.0;
const float vignette_multiplier = 1.08;
const float bleed = 0.2;
const float static_amount = 0.2;
const float green_tint = 2.5;
const float warm_tint = 1.4;

void vertex() {
	// Pin the quad to cover the whole screen regardless of camera position.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
	vec2 uv_offcet = centered_uv.yx / curvature;
	vec2 warped_uv = centered_uv + centered_uv * uv_offcet * uv_offcet;
	vec3 cutoff = vec3(step(abs(warped_uv.x), 1.0) * step(abs(warped_uv.y), 1.0));
	vec3 lines = vec3(sin(2.0 * warped_uv.y * horizontal_lines) * 0.2 + 0.9);
	vec3 vignette = vec3(length(pow(abs(centered_uv), vec2(4.0)) / 3.0));
	vec3 screen_color = textureLod(screen_texture, (warped_uv + 1.0) / 2.0, bleed).rgb * cutoff * lines;
	screen_color -= vignette * vignette_multiplier;

	// Analog TV static (FRAGCOORD.xy = pixel coordinates)
	screen_color += (fract(sin(dot(FRAGCOORD.xy + TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * static_amount;

	// game boy tint (uncomment to enable)
	//screen_color = mix(vec3(0.1, 0.15, 0.05), vec3(0.6, 0.75, 0.1), (screen_color.r + screen_color.g + screen_color.b) / green_tint);

	// warm tint (uncomment to enable)
	//screen_color *= vec3(warm_tint, 0.98, 0.90);

	ALBEDO = max(screen_color, vec3(0.0));
}
