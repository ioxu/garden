local ShaderComponents = {}
-- routines to build shaders from


-- https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
ShaderComponents.rgb2hsv_function = [[
// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

]]


ShaderComponents.uv_grid_fragment = [[
#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    float modx = abs(mod(texture_coords.x*0.01, 1.0) - 0.5) ;
    float mody = abs(mod(texture_coords.y*0.01, 1.0) - 0.5) ;
    float grads = 1-(max(modx,  mody )*2) - 0.1;
    vec2 combine = 1.0 - clamp( grads / fwidth(texture_coords*0.05), 0.0, 1.0 );
    
    // visualising fwidth at different scales (because mesh UVs == world units atm)
    //vec3 grid_c = hsv2rgb( vec3(fwidth(texture_coords*1.0).x, 0.75, 0.5) );
    //vec4 cc = mix(vec4( 0.065, 0.065, 0.065, 1.0 ), vec4( grid_c.r, grid_c.g, grid_c.b, 1.0 ), combine.x );
    
    vec4 cc = mix(vec4( 0.065, 0.065, 0.065, 1.0 ), vec4( 0.12, 0.12, 0.12, 1.0 ), combine.x );
	return cc;
}
#endif
]]

return ShaderComponents
