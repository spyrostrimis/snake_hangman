if (global.paused || global.state != "play") exit;
px = x;
py = y;
t++;
var _hit = false;
if (weapon == "rocket")
{
    // Rockets speed up and steer a little towards a target that moves
    spd = min(5.5, spd + 0.12);
    if (target != noone && instance_exists(target))
    {
        tx = aim_x(target, x);
        ty = aim_y(target, y);
    }
    var _want = point_direction(x, y, tx, ty);
    dir += clamp(angle_difference(_want, dir), -6, 6);
    x += lengthdir_x(spd, dir);
    y += lengthdir_y(spd, dir);
    if (t mod 2 == 0) part_particles_create(global.ps, x - lengthdir_x(4, dir), y - lengthdir_y(4, dir), global.pt_trail, 1);
    if (point_distance(x, y, tx, ty) <= spd + 1 || t >= life) _hit = true;
}
else
{
    var _k = min(1, t / max(1, life - 1));
    x = lerp(sx, tx, _k);
    y = lerp(sy, ty, _k);
    if (weapon == "artillery" && t mod 2 == 0) part_particles_create(global.ps, x, y - sin(_k * pi) * dist * 0.25, global.pt_trail, 1);
    if (_k >= 1) _hit = true;
}
if (!_hit) exit;

// Impact
if (splash > 0)
{
    var _r = splash;
    var _team = team, _w = weapon, _dmg = dmg, _src = owner, _ix = x, _iy = y;
    var _victims = [];
    with (obj_unit) if (team != _team && point_distance(x, y, _ix, _iy) <= _r + radius * 0.5) array_push(_victims, id);
    with (obj_building) if (team != _team && bld_dist(id, _ix, _iy) <= _r * 0.5) array_push(_victims, id);
    // A direct hit on the intended target always counts
    if (target != noone && instance_exists(target) && array_get_index(_victims, target) < 0 && target_dist(target, _ix, _iy) < 10) array_push(_victims, target);
    for (var _k2 = 0; _k2 < array_length(_victims); _k2++)
    {
        var _v = _victims[_k2];
        if (!instance_exists(_v)) continue;
        var _fall = (_v == target) ? 1 : 0.6;
        deal_damage(_v, _dmg * _fall, _w, _team, _src);
    }
    fx_explode(x, y, (weapon == "artillery") ? 1 : 0);
}
else
{
    if (target != noone && instance_exists(target) && target_dist(target, x, y) < 9) deal_damage(target, dmg, weapon, team, owner);
    part_particles_create(global.ps, x, y, global.pt_spark, 1);
    if (random(1) < 0.3) part_particles_create(global.ps, x, y, global.pt_dust, 1);
}
instance_destroy();
