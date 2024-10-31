
#ifdef PIXEL
uniform float mipBias;
// #define GAMMA 2.2
// uniform ArrayImage mainTex;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
    vec4 dynamic_tap = Texel( tex, texture_coords, mipBias);
    return dynamic_tap;
}
#endif
