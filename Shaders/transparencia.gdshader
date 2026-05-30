shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (color.r > 0.8 && color.b > 0.8 && color.g < 0.5) {
		color.a = 0.0;
	}
	COLOR = color;
}
