#define GLOW_FALLOFF 0.15//0.35//0.35
#define TAPS 8.
#define kernel(x) exp(-GLOW_FALLOFF * (x) * (x))
#define SCREEN_HEIGHT love_ScreenSize.y

#ifdef PIXEL
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
	vec3 col = vec3(0.0);
	float dy = 1.0/SCREEN_HEIGHT;

	float k_total = 0.;
	for (float i = -TAPS; i <= TAPS; i++)
		{
		float k = kernel(i);
		k_total += k;
		col += k * Texel(tex, texture_coords + vec2(0.0, float(i) * dy)).rgb;
		}
   return vec4(col / k_total, 1.0);
}
#endif
