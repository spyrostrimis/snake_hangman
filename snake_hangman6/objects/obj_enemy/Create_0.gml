/// Parent of every creature. Children (obj_bug, obj_bee) call event_inherited() first,
/// then set their own size and movement.
hw = 12;
hh = 12;
vx = 0;
vy = 0;
facing = -1;
on_ground = false;
hit_wall = 0;
hit_ceiling = false;
drop_through = false;
points = 200;
image_speed = 0.15;
net_id = -1;            // online: the same number on both PCs (its index in the level plan)
net_seen = 0;           // joiner: the last world update that had it
net_tx = x;             // joiner: where the host says it is
net_ty = y;

/// Online, on the joiner's PC: creatures don't think, they glide to where the host's are.
mirror_step = function()
{
    image_speed = 0;
    x = lerp(x, net_tx, 0.4);
    y = lerp(y, net_ty, 0.4);
};

/// Knocked out by the tongue, a boost or a stomp of snake _by: a puff of stars, points for
/// that snake and a gem left behind.
kill = function(_dmg = 1, _by = noone)
{
    var _g = obj_game;
    _g.burst(x, y, make_colour_rgb(255, 230, 90), 16);
    _g.play_sfx(_g.sfx.pop);
    if (_g.net_mode == "client")
    {
        // Online, the host keeps the score; here it goes at once.
        _g.add_popup(x, y - 20, string(points));
        _g.net_event({ t: "hit", i: net_id, d: _dmg });
        instance_destroy();
        return;
    }
    _g.add_score(points, x, y - 20, stats_of(_by));
    if (irandom(1) == 0) _g.net_spawned(instance_create_layer(x, y, "Instances", obj_gem), "gem");
    if (_g.net_mode == "host") _g.net_event({ t: "kill", i: net_id });
    instance_destroy();
};
