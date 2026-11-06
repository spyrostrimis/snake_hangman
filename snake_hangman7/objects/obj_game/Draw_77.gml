/// Post Draw: put the half-size world on screen at 2x, below the top bar and left of the sidebar.
draw_clear(c_black);
if (global.state != "play" && global.state != "end") exit;
var _sx = window_get_width() / GUI_W, _sy = window_get_height() / GUI_H;
draw_surface_ext(application_surface, 0, TOP_H * _sy, ZOOM * _sx, ZOOM * _sy, 0, c_white, 1);
