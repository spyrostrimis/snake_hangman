/// Craters and scorch marks, drawn on the ground under everything else.
if (global.state != "play" && global.state != "end") exit;
var _n = array_length(global.decals);
for (var _k = 0; _k < _n; _k++)
{
    var _d = global.decals[_k];
    if (!on_screen(_d.x, _d.y, 32)) continue;
    draw_sprite_ext(_d.spr, _d.img, _d.x, _d.y, _d.s, _d.s, _d.ang, c_white, _d.a);
}
