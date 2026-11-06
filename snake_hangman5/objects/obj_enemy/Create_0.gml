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

/// Knocked out by the tongue, a ball or a stomp: a puff of stars, points and a gem left behind.
kill = function(_dmg = 1)
{
    var _g = obj_game;
    _g.burst(x, y, make_colour_rgb(255, 230, 90), 16);
    _g.play_sfx(_g.sfx.pop);
    _g.add_score(points, x, y - 20);
    if (irandom(1) == 0) instance_create_layer(x, y, "Instances", obj_gem);
    instance_destroy();
};
