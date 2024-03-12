shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D noise1 : repeat_enable;
uniform sampler2D noise2 : repeat_enable;

uniform vec2 scroll1 = vec2(0.01, 0.01);
uniform vec2 scroll2 = vec2(-0.01, -0.01);

uniform float distortion_strength : hint_range(-1,1) = 0.05;

uniform sampler2D gradient;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float depth = texture(noise1, SCREEN_UV + scroll1 * TIME * 0.1).r *
		texture(noise2, SCREEN_UV + scroll2 * TIME * 0.1).r;
	vec4 screenCol = texture(SCREEN_TEXTURE, 
		SCREEN_UV + distortion_strength * vec2(depth));
	//COLOR = screenCol * tone_color;
	//vec4 screenColor = texture(SCREEN_TEXTURE, UV);
	vec4 gradientColor = texture(gradient, SCREEN_UV + distortion_strength * vec2(depth));
	COLOR = mix(screenCol, gradientColor, 0.25);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
