shader_type canvas_item;

// Preserve textura/alpha originais; suavizar apenas o terreno da Fazenda.
void fragment() {
	vec4 source = COLOR;
	COLOR = vec4(mix(source.rgb, vec3(0.36, 0.48, 0.25), 0.45), source.a);
}
