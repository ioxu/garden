#define GLOW_FALLOFF 0.15//0.35//0.35
#define TAPS 8.
#define kernel(x) exp(-GLOW_FALLOFF * (x) * (x))
#define SCREEN_WIDTH love_ScreenSize.x

#ifdef PIXEL
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
	vec3 col = vec3(0.0);
	float dx = 1.0/SCREEN_WIDTH;

	float k_total = 0.;
	for (float i = -TAPS; i <= TAPS; i++)
		{
		float k = kernel(i);
		k_total += k;
		col += k * Texel(tex, texture_coords + vec2(float(i) * dx, 0.0)).rgb;
		}
   return vec4(col / k_total, 1.0);
}
#endif
