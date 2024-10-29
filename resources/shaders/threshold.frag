#ifdef PIXEL
uniform sampler2D PassPrev3Texture;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
   vec3 diff = clamp(Texel(tex, texture_coords).rgb - Texel(PassPrev3Texture, texture_coords).rgb, 0.0, 1.0);
   return vec4(diff, 1.0);
} 
#endif
