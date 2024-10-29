
#ifdef PIXEL
uniform float gamma; //2.2
uniform float mipBias;
// #define GAMMA 2.2
// uniform ArrayImage mainTex;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
    // return pow( Texel( tex, texture_coords, -10.0 ), vec4(gamma) );
    vec4 t = Texel( tex, texture_coords);
    vec4 t1 = Texel( tex, texture_coords, 1);
    vec4 t2 = Texel( tex, texture_coords, 2);
    vec4 t3 = Texel( tex, texture_coords, 3);
    vec4 t4 = Texel( tex, texture_coords, 4);
    vec4 t5 = Texel( tex, texture_coords, 5);
    vec4 t6 = Texel( tex, texture_coords, 6);
    
    vec4 t6_5 = Texel( tex, texture_coords, 6.5);

    vec4 t7 = Texel( tex, texture_coords, 7);
    vec4 t8 = Texel( tex, texture_coords, 8);
    vec4 t9 = Texel( tex, texture_coords, 9);
    vec4 t10 = Texel( tex, texture_coords, 10);
    vec4 t20 = Texel( tex, texture_coords, 20);

    vec4 dynamic_tap = Texel( tex, texture_coords, mipBias);
    // vec4 taps = (t5 + t10) / 2.0;
    vec4 taps = dynamic_tap;
    return pow(taps, vec4(gamma));
    // return pow( Texel( tex, texture_coords, 5), vec4(gamma) );
}
#endif
