/// The sky: a vertical gradient filling the camera view, behind every layer.
var _l = obj_game.lvl;
var _cx = camera_get_view_x(view_camera[0]);
var _cy = camera_get_view_y(view_camera[0]);
draw_rectangle_colour(_cx, _cy, _cx + 640, _cy + 360, _l.sky_top, _l.sky_top, _l.sky_bottom, _l.sky_bottom, false);
