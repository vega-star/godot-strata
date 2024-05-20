// Retro TV Shader | CREATED BY leon4aka / Tomzalat
// SOURCE: https://godotshaders.com/shader/retro-tv-shader/
// Code is heavily changed but still with some few intact regions, currently wanting to add more features and make this the main visual shader of the game
// The code starts below:

shader_type canvas_item;

const float scanline_alpha = 0.5;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform bool show_scanlines = true;
uniform float scanline_count : hint_range(0, 1800) = 50.0;
uniform bool scanline_movement = false;
uniform float scanline_movement_speed = 1.0;
uniform float screen_stability = 2.0;
uniform float chromatic_aberration = 2;

vec2 uv_curve(vec2 uv)
{
	uv = (uv - 0.5) * 2.0;
	
	//You can modify the numbers and try different values
	uv.x *= 1.0 + pow(abs(uv.y) / 5.0, screen_stability);
	uv.y *= 1.0 + pow(abs(uv.x) / 5.0, screen_stability);
	
	//The scale part (you can delete it when you want)
	uv /= 1.0;
	
	uv = (uv/2.0) + 0.5;
	return uv;
}


void fragment()
{
	vec4 scan_line;
	
	//You can modify the *3.0, *-3.0 for a bigger or smaller 
	float r = texture(SCREEN_TEXTURE, uv_curve(SCREEN_UV) + vec2(SCREEN_PIXEL_SIZE.x*0.0), 0.0).r;
	float g = texture(SCREEN_TEXTURE, uv_curve(SCREEN_UV) + vec2(SCREEN_PIXEL_SIZE.x*3.0), 0.0).g;
	float b = texture(SCREEN_TEXTURE, uv_curve(SCREEN_UV) + vec2(SCREEN_PIXEL_SIZE.x*-3.0), 0.0).b;
	
	
	//If you dont want scanlines you can just delete this part
	if ( show_scanlines == true ) {
		float s = sin(uv_curve(SCREEN_UV).y * scanline_count * PI * 2.0);
		s = (s * 0.5 + 0.5) * 0.9 + 0.1;
		scan_line = vec4(vec3(pow(s, 0.25)), scanline_alpha);
	};
	
	
	COLOR = vec4(r, g, b, 1.0) * scan_line;
}