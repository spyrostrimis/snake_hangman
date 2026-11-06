/// Fly, break on the ground or walls, and hurt the snake on contact (a rolling ball smashes it).
var _g = obj_game;
if (_g.state != "play") exit;
if (net_mirror())
{
    // Online, the joiner's projectiles copy the host's, and only hit the joiner's snake.
    x = lerp(x, net_tx, 0.5);
    y = lerp(y, net_ty, 0.5);
    var _me = (array_length(_g.pl) == 2) ? _g.pl[_g.my_pid].inst : noone;
    if (instance_exists(_me) && !_me.hidden && abs(_me.x - x) < _me.hw + 7 && abs(_me.y - y) < _me.hh + 7)
    {
        if (_me.ball) _g.burst(x, y, c_white, 6);
        else with (_me) take_hit(sign(x - other.x));
        _g.net_gone[$ string(net_id)] = true;
        _g.net_event({ t: "hazard", i: net_id });
        instance_destroy();
    }
    exit;
}
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
with (obj_player) if (!remote && _hit == noone && abs(x - other.x) < hw + 7 && abs(y - other.y) < hh + 7) _hit = id;
if (_hit != noone)
{
    if (_hit.ball) _g.burst(x, y, c_white, 6);
    else with (_hit) take_hit(sign(x - other.x));
    instance_destroy();
}
