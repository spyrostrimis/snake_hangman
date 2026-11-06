/// Shared boss logic: wake up when the snake arrives, count down the hurt flash,
/// stay inside the arena. Each child adds its own attacks after event_inherited().
if (obj_game.state != "play") exit;
if (hurt_t > 0) hurt_t--;
if (!active)
{
    if (instance_exists(obj_player) && abs(obj_player.x - x) < 300 && abs(obj_player.y - y) < 200)
    {
        active = true;
        obj_game.boss_start(id);
    }
}
x = clamp(x, arena_x1, arena_x2);
