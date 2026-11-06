/// End Step: the cameras. During play each snake has its own camera (with two snakes, the
/// window splits into a top and a bottom view); otherwise one camera pans along the level.
/// The parallax layers are placed per view by the sky layer's begin script.

var _playing = (state == "play" || state == "paused" || state == "clear") && array_length(pl) > 0;
set_split(_playing && array_length(pl) == 2 && net_mode == "");

if (_playing)
{
    var _vw = split_on ? SPLIT_VIEW_W : 640;
    var _vh = split_on ? SPLIT_VIEW_H : 360;
    for (var _k = 0; _k < array_length(pl); _k++)
    {
        // Online, this PC shows only its own snake, in the one full view.
        if (net_mode != "" && _k != my_pid) continue;
        var _view = (net_mode != "") ? 0 : _k;
        var _p = pl[_k];
        // A snake that is out watches the other one.
        var _who = instance_exists(_p.inst) ? _p.inst : noone;
        if (_who == noone)
        {
            var _other = any_player_in();
            if (!is_undefined(_other) && instance_exists(_other.inst)) _who = _other.inst;
        }
        if (_who != noone)
        {
            var _tx = _who.x - _vw / 2 + _who.facing * 70;
            var _ty = _who.y - _vh / 2 - 20;
            _p.cam_x = cam_snap ? _tx : lerp(_p.cam_x, _tx, 0.1);
            _p.cam_y = cam_snap ? _ty : lerp(_p.cam_y, _ty, 0.12);
        }
        _p.cam_x = clamp(_p.cam_x, 0, lvl_w * TILE - _vw);
        _p.cam_y = clamp(_p.cam_y, 0, lvl_h * TILE - _vh);
        camera_set_view_pos(view_camera[_view], round(_p.cam_x), round(_p.cam_y));
    }
    cam_snap = false;
}
else
{
    // Title, credits, game over: drift along the level and bounce back at its end.
    var _span = lvl_w * TILE - 640;
    var _t = (title_pan mod (_span * 2));
    cam_x = (_t < _span) ? _t : _span * 2 - _t;
    cam_y = lvl_h * TILE - 360;
    cam_x = clamp(cam_x, 0, lvl_w * TILE - 640);
    cam_y = clamp(cam_y, 0, lvl_h * TILE - 360);
    camera_set_view_pos(view_camera[0], round(cam_x), round(cam_y));
}

// Online: send this step's news to the other PC.
net_update();
