shader_type canvas_item;

// Pixel-art smoothing upscaler (xBR level 1 + level 2 edge detection).
// Reads the low-res game image from SCREEN_TEXTURE and redraws it at the full
// window resolution, rounding diagonal staircase edges. The blended
// edge pixels add new in-between colors that the original sprites don't have.

uniform vec2 resolution = vec2(398.0, 224.0); // logical game resolution
uniform float strength : hint_range(0.0, 1.0) = 1.0; // 0 = original, 1 = full smoothing
uniform float edge_softness : hint_range(0.0, 2.0) = 1.0; // anti-aliasing width, in screen pixels
uniform float equal_threshold : hint_range(0.0, 0.5) = 0.06; // colors closer than this count as "the same"
uniform float corner_coverage : hint_range(0.0, 0.5) = 0.0; // pushes rounded corners further into the pixel
uniform float shade_blend : hint_range(0.0, 1.0) = 0.0; // blends similar neighboring colors into smooth gradients
uniform float shade_threshold : hint_range(0.0, 0.5) = 0.12; // max color difference that counts as "shading" (outlines are left alone)

const vec3 LUMA = vec3(0.299, 0.587, 0.114);

vec3 px(sampler2D tex, vec2 cell, vec2 offset) {
	return textureLod(tex, (cell + offset + vec2(0.5)) / resolution, 0.0).rgb;
}

// Perceptual color distance (weighted toward brightness, like xBR's YUV metric).
float df(vec3 a, vec3 b) {
	vec3 d = abs(a - b);
	return dot(d, LUMA) * 0.7 + (d.r + d.g + d.b) * 0.1;
}

bool eq(vec3 a, vec3 b) {
	return df(a, b) < equal_threshold;
}

void fragment() {
	vec2 pos = SCREEN_UV * resolution; // position in logical pixels
	vec2 cell = floor(pos);
	vec2 fp = pos - cell; // position inside the logical pixel, 0..1

	// Handle only the pixel quadrant we are in, mirrored so it always looks
	// like the bottom-right corner. dir points toward that corner.
	vec2 dir = vec2(fp.x < 0.5 ? -1.0 : 1.0, fp.y < 0.5 ? -1.0 : 1.0);
	vec2 local = vec2(dir.x > 0.0 ? fp.x : 1.0 - fp.x, dir.y > 0.0 ? fp.y : 1.0 - fp.y);
	vec2 dx = vec2(dir.x, 0.0);
	vec2 dy = vec2(0.0, dir.y);

	//      B1 C1
	//   A  B  C  C4
	//   D  E  F  F4
	//   G  H  I  I4
	//      H5 I5
	vec3 E  = px(SCREEN_TEXTURE, cell, vec2(0.0));
	vec3 F  = px(SCREEN_TEXTURE, cell, dx);
	vec3 H  = px(SCREEN_TEXTURE, cell, dy);
	vec3 I  = px(SCREEN_TEXTURE, cell, dx + dy);
	vec3 B  = px(SCREEN_TEXTURE, cell, -dy);
	vec3 D  = px(SCREEN_TEXTURE, cell, -dx);
	vec3 C  = px(SCREEN_TEXTURE, cell, dx - dy);
	vec3 G  = px(SCREEN_TEXTURE, cell, dy - dx);
	vec3 F4 = px(SCREEN_TEXTURE, cell, 2.0 * dx);
	vec3 H5 = px(SCREEN_TEXTURE, cell, 2.0 * dy);
	vec3 I4 = px(SCREEN_TEXTURE, cell, 2.0 * dx + dy);
	vec3 I5 = px(SCREEN_TEXTURE, cell, dx + 2.0 * dy);

	// Shading blend: bilinear-filter toward the 3 nearest neighbors, but only
	// those close in color to E, so outlines stay sharp while stepped
	// shading becomes a smooth gradient.
	vec2 t = local - vec2(0.5);
	vec3 sF = df(E, F) < shade_threshold ? F : E;
	vec3 sH = df(E, H) < shade_threshold ? H : E;
	vec3 sI = df(E, I) < shade_threshold ? I : E;
	vec3 shaded = mix(mix(E, sF, t.x), mix(sH, sI, t.x), t.y);
	vec3 base = mix(E, shaded, shade_blend);

	vec3 result = base;

	if (!eq(E, F) && !eq(E, H)) {
		// Weighted edge strength along the two diagonals.
		float e = df(E, C) + df(E, G) + df(I, F4) + df(I, H5) + 4.0 * df(H, F);
		float i = df(H, D) + df(H, I5) + df(F, I4) + df(F, B) + 4.0 * df(E, I);

		// Don't round corners that are part of deliberate patterns (dithering, 1px details).
		bool lv1 = (!eq(F, B) && !eq(H, D)) || (eq(E, I) && !eq(F, I4) && !eq(H, I5)) || eq(E, G) || eq(E, C);

		if (e < i && lv1) {
			// Screen pixels per logical pixel -> anti-aliasing width in local units.
			float aa = max(edge_softness * length(SCREEN_PIXEL_SIZE * resolution), 0.001);

			float a45 = smoothstep(-aa, aa, local.x + local.y - 1.5 + corner_coverage);
			float alpha = a45;

			// Level 2: shallower / steeper slopes spanning two pixels.
			bool shallow = 2.0 * df(F, G) <= df(H, C) && !eq(E, G) && !eq(D, G);
			bool steep = 2.0 * df(H, C) <= df(F, G) && !eq(E, C) && !eq(B, C);
			if (shallow) {
				alpha = max(alpha, smoothstep(-aa, aa, (local.x + 2.0 * local.y - 2.0 + corner_coverage) * 0.5));
			}
			if (steep) {
				alpha = max(alpha, smoothstep(-aa, aa, (2.0 * local.x + local.y - 2.0 + corner_coverage) * 0.5));
			}

			vec3 edge_color = df(E, F) <= df(E, H) ? F : H;
			result = mix(base, edge_color, alpha * strength);
		}
	}

	COLOR = vec4(result, 1.0);
}
