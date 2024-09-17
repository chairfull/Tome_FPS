shader_type canvas_item;

//uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blend : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float a = 0.0;
	float c = 0.0;
	for (float x = -3.0; x <= 3.0; x += 1.0) {
		for (float y = -3.0; y <= 3.0; y += 1.0) {
			a += textureLod(TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE * vec2(x, y) * 2.0, 2.0).a;
			c += 1.0;
		}
	}
	float da = texture(TEXTURE, UV).a;
	COLOR.rgb = vec3(1.0, 0.5, 0.0);
	COLOR.a = clamp(clamp(((a / c) - da) * 2.0, 0.0, 1.0) + da * .25, 0.0, 1.0)  * blend;
}