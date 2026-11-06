/// Bounce: move one axis at a time and reflect off the edges and the bricks.
if (obj_game.state != "play") exit;
spin += 6;

var _nx = px + vx;
if (obj_game.is_solid(_nx + sign(vx) * fizz_radius, py - 3) || obj_game.is_solid(_nx + sign(vx) * fizz_radius, py + 3)) vx = -vx;
else px = _nx;

var _ny = py + vy;
if (obj_game.is_solid(px - 3, _ny + sign(vy) * fizz_radius) || obj_game.is_solid(px + 3, _ny + sign(vy) * fizz_radius)) vy = -vy;
else py = _ny;
