// The play field is drawn to a surface, then through this shader:
// - u_hit (0..1): a wrong letter or a crash makes the pane ripple and split its colours;
// - u_glow (0..1): a right letter washes it with a little green;
// - a faint moving scanline, like the site's CRT screens.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;
uniform float u_hit;
uniform float u_glow;
uniform float u_height;

void main()
{
    vec2 uv = v_vTexcoord;
    uv.x += sin(uv.y * 38.0 + u_time * 14.0) * 0.006 * u_hit;

    float split = 0.007 * u_hit;
    vec4 base = texture2D(gm_BaseTexture, uv);
    float r = texture2D(gm_BaseTexture, uv + vec2(split, 0.0)).r;
    float b = texture2D(gm_BaseTexture, uv - vec2(split, 0.0)).b;
    vec4 col = vec4(r, base.g, b, base.a);

    float scan = 0.95 + 0.05 * sin(uv.y * u_height * 1.5708 + u_time * 3.0);
    col.rgb *= scan;
    col.rgb += vec3(0.24, 0.88, 0.48) * u_glow * 0.18;

    gl_FragColor = v_vColour * col;
}
