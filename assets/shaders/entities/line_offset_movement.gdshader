shader_type canvas_item;

uniform float line_speed = 1.0;
uniform bool line_colliding = false;
uniform bool horizontal_movement = true;

void fragment() {
	vec2 moving_vector;
	if (horizontal_movement == true) {
		moving_vector = vec2(UV.x-(TIME * line_speed), UV.y);
	} else {
		moving_vector = vec2(UV.x, UV.y-(TIME * line_speed));
	}
	
	vec4 in_texture = texture(TEXTURE, moving_vector);
	COLOR = in_texture;
	
	if (line_colliding == true) {
		COLOR = vec4(1.0, 1.0, 1.0, in_texture.a);
	}
}

// Based on MrElipteach tutorial
// Source: https://www.youtube.com/watch?v=Mry6FdWnN7I