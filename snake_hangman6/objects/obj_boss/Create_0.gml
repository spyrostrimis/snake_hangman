/// Parent of the bosses (a child of obj_enemy, so the tongue, the ball and stomps all reach it).
/// A boss guards the end of a level and holds one letter of the secret word: beat it to get it.
event_inherited();
image_speed = 0;
boss_name = "BOSS";
hp_max = 8;
hp = hp_max;
active = false;       // wakes up when the snake comes close
hurt_t = 0;           // flashing and safe after each hit
state = "idle";
timer = 0;
ch = "?";             // the letter it drops (obj_game sets it)
points = 5000;
music = "music_09.ogg";
arena_x1 = x - 360;   // how far it may roam (the level sets these)
arena_x2 = x + 160;
gravity_pull = 0.45;

/// Each hit takes _dmg health; after the last one the boss bursts and drops its letter.
kill = function(_dmg = 1, _by = noone)
{
    if (!active || hurt_t > 0) return;
    var _g = obj_game;
    hurt_t = 50;
    _g.play_sfx(_g.sfx.boss_hit);
    _g.burst(x, y - 10, make_colour_rgb(255, 230, 90), 10);
    // Online, the joiner's hit goes to the host, which keeps the boss's health.
    if (_g.net_mode == "client") { _g.net_event({ t: "hit", i: net_id, d: _dmg }); return; }
    hp -= _dmg;
    if (_g.net_mode == "host")
    {
        var _st = stats_of(_by);
        _g.net_event({ t: "bhit", i: net_id, by: is_undefined(_st) ? 0 : _st.pid });
    }
    if (hp <= 0)
    {
        _g.burst(x, y - 10, make_colour_rgb(255, 120, 80), 40);
        _g.burst(x, y - 10, make_colour_rgb(120, 255, 140), 30);
        _g.add_score(points, x, y - 50, stats_of(_by));
        // The letter appears at the snake's head height, easy to grab.
        var _l = instance_create_layer(x, y + 12, "Instances", obj_letter);
        _l.ch = ch;
        _g.net_spawned(_l, "letter");
        _g.boss_defeated(boss_name);
        if (_g.net_mode == "host") _g.net_event({ t: "kill", i: net_id });
        instance_destroy();
    }
};

/// Throws a projectile (sprite _spr) with velocity (_vx, _vy) and gravity _grav.
shoot = function(_spr, _x, _y, _vx, _vy, _grav)
{
    var _h = instance_create_layer(_x, _y, "Instances", obj_hazard);
    _h.sprite_index = _spr;
    _h.vx = _vx;
    _h.vy = _vy;
    _h.grav = _grav;
    _h.net_id = obj_game.net_next_id++;
    return _h;
};

/// Faces the nearest snake; returns the horizontal distance to it.
face_player = function()
{
    var _p = instance_nearest(x, y, obj_player);
    if (_p == noone) return 9999;
    facing = (_p.x >= x) ? 1 : -1;
    return abs(_p.x - x);
};
