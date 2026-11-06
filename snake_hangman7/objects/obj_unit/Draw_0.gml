if (!on_screen(x, y, 24)) exit;
if (team != PLAYER && !seen(x, y)) exit;
var _f = round(face / 11.25) mod 32;
var _bob = (kind == "inf") ? -abs(sin(walk / 5)) * 1.2 : 0;
team_shader(team);
var _col = (flash > 0) ? make_colour_rgb(255, 230, 200) : c_white;
draw_sprite_ext(def.spr, _f, round(x), round(y + _bob), 1, 1, 0, _col, 1);
if (def.tur != -1)
{
    var _tf = round(tface / 11.25) mod 32;
    var _off = (utype == "launcher") ? -3 : -1;
    draw_sprite_ext(def.tur, _tf, round(x + lengthdir_x(_off, face)), round(y + lengthdir_y(_off, face)), 1, 1, 0, _col, 1);
}
shader_reset();
