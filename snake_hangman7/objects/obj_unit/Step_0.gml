if (global.paused || global.state != "play") exit;
var _ox = x, _oy = y;
unit_step();
if (x != _ox || y != _oy) walk += 1;
