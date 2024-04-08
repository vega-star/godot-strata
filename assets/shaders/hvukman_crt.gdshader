// CRT Shader | CREATED BY HVukman
// SOURCE: https://github.com/HVukman/Godot
// SOURCE 2: https://godotshaders.com/shader/crt-shader-2/
// A lot of adjustments were made, but I sincerly don't get a lot of sections in the code due to a lot of interpolations, so I kept testing some values until satisfied
// Most of the code is nearly identical, so don't forget to check the source and leave a star on their repository
// The code starts below:

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float screen_stability = 5.0;

vec2 curve(vec2 uv) {
	uv = (uv - 0.5) * 2.0;
	uv *= 1.1;
	uv.x *= 1.0 + pow((abs(uv.y) / screen_stability), 2.0);
	uv.y *= 1.0 + pow((abs(uv.x) / screen_stability), 2.0);
	uv  = (uv / 2.0) + 0.5;
	uv =  uv *0.92 + 0.04;
	return uv;
}

void fragment() {
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 q = FRAGCOORD.xy / iResolution.xy;
	vec2 uv = q;
	uv = curve( uv );
	vec3 oricol = texture(SCREEN_TEXTURE, vec2(q.x,q.y) ).xyz;
	vec3 col;
	float x =  sin(0.3*TIME+uv.y*21.0)*sin(0.7*TIME+uv.y*29.0)*sin(0.3+0.33*TIME+uv.y*31.0)*0.0017;
	
	col.r = texture(SCREEN_TEXTURE,vec2(x+uv.x+0.001,uv.y+0.001)).x+0.05;
	col.g = texture(SCREEN_TEXTURE,vec2(x+uv.x+0.002,uv.y-0.002)).y+0.05;
	col.b = texture(SCREEN_TEXTURE,vec2(x+uv.x-0.002,uv.y+0.000)).z+0.05;
	col.r += 0.08*texture(SCREEN_TEXTURE,0.25*vec2(x+0.025, -0.027)+vec2(uv.x+0.001,uv.y+0.001)).x;
	col.g += 0.05*texture(SCREEN_TEXTURE,0.25*vec2(x+-0.022, -0.02)+vec2(uv.x+0.000,uv.y-0.002)).y;
	col.b += 0.08*texture(SCREEN_TEXTURE,0.25*vec2(x+-0.02, -0.018)+vec2(uv.x-0.002,uv.y+0.000)).z;
	
	col = clamp(col*0.6+0.4*col*col*1.0,0.0,1.0);
	
	float vig = (0.0 + 1.0*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y));
	col *= vec3(pow(vig,0.3));
	
	col *= vec3(0.95,1.05,0.95);
	col *= 2.8;
	
	float scans = clamp( 0.15+0.15*sin(3.5*TIME+uv.y*iResolution.y*0.2), 0.0, 1.2);
	
	float s = pow(scans,2.9);
	col = col*vec3( 0.4+0.7*s) ;
	
	col *= 1.0+0.01*sin(120.0*TIME);
	if (uv.x < 0.0 || uv.x > 1.0)
		col *= 0.0;
	if (uv.y < 0.0 || uv.y > 1.0)
		col *= 0.0;
	
	col*=1.0-0.65*vec3(clamp((mod(FRAGCOORD.x, 2.0)-1.0)*2.0,0.0,1.0));
	
	float comp = smoothstep( 0.1, 0.9, sin(TIME) );
	
	COLOR = vec4(col,1.0);
}