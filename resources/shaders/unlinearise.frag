uniform float gamma; //2.2
//#define GAMMA 2.2
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
    return pow( Texel( tex, texture_coords ), vec4(1.0/gamma) );
}
