shader_type canvas_item;

// Simple CRT look: scanlines, aperture-grille mask, vignette and optional
// screen curvature. Reads the finished frame (after a BackBufferCopy).

uniform vec2 resolution = vec2(398.0, 224.0);
uniform float scanline : hint_range(0.0, 1.0) = 0.2;
uniform float curvature : hint_range(0.0, 0.2) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.2;
uniform float mask : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 uv = SCREEN_UV;
	if (curvature > 0.0) {
		vec2 c = uv * 2.0 - 1.0;
		c *= 1.0 + curvature * vec2(c.y * c.y, c.x * c.x);
		uv = c * 0.5 + 0.5;
	}
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 color = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;

		float wave = sin(uv.y * resolution.y * 6.2831853) * 0.5 + 0.5;
		color *= 1.0 - scanline * wave;

		int column = int(mod(FRAGCOORD.x, 3.0));
		vec3 grille = vec3(1.0 - mask);
		if (column == 0) { grille.r = 1.0 + mask; }
		else if (column == 1) { grille.g = 1.0 + mask; }
		else { grille.b = 1.0 + mask; }
		color *= grille;

		float v = 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
		color *= mix(1.0, pow(clamp(v, 0.0, 1.0), 0.3), vignette);

		COLOR = vec4(color, 1.0);
	}
}
