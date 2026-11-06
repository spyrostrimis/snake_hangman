/// Draw GUI, at window resolution: CRT scanlines over the 3x picture (C toggles them).
if (!crt_on) exit;
var _w = display_get_gui_width();
var _h = display_get_gui_height();
draw_set_colour(c_black);
draw_set_alpha(0.22);
for (var _y = 2; _y < _h; _y += 3) draw_line(0, _y, _w, _y);
draw_set_alpha(1);
