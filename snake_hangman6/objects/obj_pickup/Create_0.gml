/// Parent of every item. Touch it, or pull it in with the tongue, to collect it.
/// Children set on_collect to say what collecting does.
bob = random(2 * pi);
base_y = y;
grabbed = false;
grabber = noone;        // the snake whose tongue has it
spin = false;
image_speed = 0;
net_id = -1;            // online: the same number on both PCs
on_collect = function(_by) {};
/// Online, on the joiner's PC: the sound and sparkle of collecting it (the host does the rest).
client_fx = function(_by) {};

/// Collected by snake _by (an obj_player).
collect_now = function(_by)
{
    var _g = obj_game;
    if (_g.net_mode == "client")
    {
        // Online, the host decides what it does; here it goes at once.
        client_fx(_by);
        _g.net_event({ t: "collect", i: net_id });
        instance_destroy();
        return;
    }
    on_collect(_by);
    if (_g.net_mode == "host") _g.net_event({ t: "took", i: net_id });
    instance_destroy();
};
