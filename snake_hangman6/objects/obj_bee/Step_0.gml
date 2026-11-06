// Online, the joiner's creatures copy the host's instead of thinking.
if (net_mirror()) { mirror_step(); exit; }
event_inherited();
var _s = obj_game.state;
if (_s != "play" && _s != "title" && _s != "credits") exit;
image_speed = 0.5;

t += 0.018;
x = base_x + sin(t) * range;
y = base_y + sin(t * 2) * 14;
facing = (cos(t) >= 0) ? 1 : -1;
