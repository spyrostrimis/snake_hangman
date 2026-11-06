/// Fly, break on the ground or walls, and hurt the snake on contact (a rolling ball smashes it).
var _g = obj_game;
if (_g.state != "play") exit;
t += 0.1;
vy += grav;
x += vx + (sway ? sin(t) * 1.2 : 0);
y += vy;
image_angle += sway ? sin(t) * 3 : vx * 5;
life--;

var _t = tile_at(x, y + 6);
if (life <= 0 || is_blocking(_t) || y > _g.lvl_h * TILE)
{
    part_particles_create(_g.ps, x, y, _g.pt_dust, 3);
    instance_destroy();
    exit;
}
// The first snake it touches.
var _hit = noone;
with (obj_player) if (_hit == noone && abs(x - other.x) < hw + 7 && abs(y - other.y) < hh + 7) _hit = id;
if (_hit != noone)
{
    if (_hit.ball) _g.burst(x, y, c_white, 6);
    else with (_hit) take_hit(sign(x - other.x));
    instance_destroy();
}
