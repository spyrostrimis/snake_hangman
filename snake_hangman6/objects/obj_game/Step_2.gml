/// End Step: the camera follows the snake (or pans on the title screen), then the
/// background layers move at their own speeds for the parallax effect.

var _vw = 640;
var _vh = 360;
var _tx = cam_x;
var _ty = cam_y;
if ((state == "play" || state == "paused" || state == "clear") && instance_exists(obj_player))
{
    _tx = obj_player.x - _vw / 2 + obj_player.facing * 70;
    _ty = obj_player.y - _vh / 2 - 20;
    cam_x = lerp(cam_x, _tx, 0.1);
    cam_y = lerp(cam_y, _ty, 0.12);
}
else
{
    // Title, credits, game over: drift along the level and bounce back at its end.
    var _span = lvl_w * TILE - _vw;
    var _t = (title_pan mod (_span * 2));
    cam_x = (_t < _span) ? _t : _span * 2 - _t;
    cam_y = lvl_h * TILE - _vh;
}
cam_x = clamp(cam_x, 0, lvl_w * TILE - _vw);
cam_y = clamp(cam_y, 0, lvl_h * TILE - _vh);
camera_set_view_pos(view_camera[0], round(cam_x), round(cam_y));

// Parallax: the further away a layer is, the more it moves along with the camera.
if (variable_instance_exists(id, "bg_layers"))
{
    layer_x(bg_layers.Mountains, cam_x * 0.82);
    layer_y(bg_layers.Mountains, cam_y * 0.85 + 70);
    layer_x(bg_layers.Clouds, cam_x * 0.9 - frame * 0.15);
    layer_y(bg_layers.Clouds, cam_y * 0.92 + 8);
    layer_x(bg_layers.Hills, cam_x * 0.6);
    layer_y(bg_layers.Hills, cam_y * 0.75 + 190);
}
