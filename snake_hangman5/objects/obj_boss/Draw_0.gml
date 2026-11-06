/// The boss (flashing white when hit), and the letter bubble it guards above its head.
var _flash = hurt_t > 0 && (hurt_t div 4) mod 2 == 0;
if (_flash) gpu_set_fog(true, c_white, 0, 0);
draw_sprite_ext(sprite_index, image_index, x, y, facing, 1, 0, c_white, 1);
if (_flash) gpu_set_fog(false, c_white, 0, 0);

var _by = y - 74 + sin(obj_game.frame * 0.08) * 3;
draw_sprite_ext(spr_orb, 0, x, _by, 0.8, 0.8, 0, c_white, 0.9);
hud_text(x, _by - 9, "?", 0.45, fa_center);
