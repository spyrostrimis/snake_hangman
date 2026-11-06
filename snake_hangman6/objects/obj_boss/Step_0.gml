/// Shared boss logic: wake up when the snake arrives, count down the hurt flash,
/// stay inside the arena. Each child adds its own attacks after event_inherited().
if (obj_game.state != "play") exit;
if (hurt_t > 0) hurt_t--;
if (!active)
{
    var _p = instance_nearest(x, y, obj_player);
    if (_p != noone && abs(_p.x - x) < 300 && abs(_p.y - y) < 200)
    {
        active = true;
        obj_game.boss_start(id);
    }
}
x = clamp(x, arena_x1, arena_x2);
