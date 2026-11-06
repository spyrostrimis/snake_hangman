/// Post Draw: put the half-size world on screen at 2x (times the window scale), below the top bar and left of the sidebar.
draw_clear(c_black);
if (global.state != "play" && global.state != "end") exit;
var _s = global.view_s;
draw_surface_ext(application_surface, global.view_ox, global.view_oy + TOP_H * _s, ZOOM * _s, ZOOM * _s, 0, c_white, 1);
