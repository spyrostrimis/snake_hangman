/// The sky: a vertical gradient filling the camera view being drawn, behind every layer.
var _l = obj_game.lvl;
var _cam = view_camera[view_current];
var _cx = camera_get_view_x(_cam);
var _cy = camera_get_view_y(_cam);
var _cw = camera_get_view_width(_cam);
var _ch = camera_get_view_height(_cam);
draw_rectangle_colour(_cx, _cy, _cx + _cw, _cy + _ch, _l.sky_top, _l.sky_top, _l.sky_bottom, _l.sky_bottom, false);
