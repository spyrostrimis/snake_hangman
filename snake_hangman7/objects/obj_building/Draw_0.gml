if (!on_screen(x + w * HALF, y + h * HALF, w * CELL)) exit;
if (team != PLAYER && !seen(x + HALF, y + HALF)) exit;
team_shader(team);
var _col = (flash > 0) ? make_colour_rgb(255, 230, 200) : c_white;
var _img = (btype == "wall") ? wall_mask : 0;
if (anim < 1)
{
    // Rises out of the ground, bottom first
    var _ph = h * CELL;
    var _shown = round(_ph * anim);
    draw_sprite_part_ext(def.spr, _img, 0, _ph - _shown, w * CELL, _shown, x, y + _ph - _shown, 1, 1, _col, 1);
    shader_reset();
    draw_set_colour(make_colour_rgb(255, 210, 90));
    draw_set_alpha(0.7);
    draw_line(x, y + _ph - _shown, x + w * CELL, y + _ph - _shown);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    exit;
}
draw_sprite_ext(def.spr, _img, x, y, 1, 1, 0, _col, 1);
if (variable_struct_exists(def, "tur")) draw_sprite_ext(def.tur, round(tface / 11.25) mod 32, x + HALF, y + HALF - 1, 1, 1, 0, _col, 1);
if (btype == "radar") draw_sprite_ext(spr_radar_dish, floor(dish), x + 32, y + 22, 1, 1, 0, _col, 1);
shader_reset();
if (btype == "refinery" && docked != noone && (global.frame div 8) mod 2 == 0)
{
    draw_set_colour(make_colour_rgb(120, 240, 255));
    draw_set_alpha(0.5);
    draw_rectangle(x + 66, y + 42, x + 94, y + 44, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}
