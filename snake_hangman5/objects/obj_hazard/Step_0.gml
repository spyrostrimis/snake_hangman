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
if (instance_exists(obj_player))
{
    var _p = obj_player;
    if (abs(_p.x - x) < _p.hw + 7 && abs(_p.y - y) < _p.hh + 7)
    {
        if (_p.ball) _g.burst(x, y, c_white, 6);
        else with (_p) take_hit(sign(x - other.x));
        instance_destroy();
    }
}
