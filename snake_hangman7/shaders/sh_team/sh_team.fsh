// Side colours: the art paints side markings in magenta, and this swaps them for the side's colour,
// keeping their shading (the red channel carries the brightness).
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 u_team;

void main()
{
    vec4 t = texture2D(gm_BaseTexture, v_vTexcoord);
    float m = min(t.r, t.b);
    if (m > 0.12 && abs(t.r - t.b) < 0.14 && t.g < 0.45 * m)
    {
        float k = max(t.r, t.b);
        t.rgb = u_team * k * 1.05 + vec3(0.06) * k;
    }
    gl_FragColor = v_vColour * t;
}
