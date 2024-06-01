shader_type canvas_item;
// Thanks Jon Topielski and his 3 minute tutorial. Source: https://www.youtube.com/watch?v=ZuWUzlb1TmM

uniform float height = 5.0;
uniform float frequency = 3.0;
uniform float speed = 5.0;

void vertex() {
	VERTEX.y += height * sin((frequency * UV.x) + (speed * TIME));
}
