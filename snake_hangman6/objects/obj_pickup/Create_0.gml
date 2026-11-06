/// Parent of every item. Touch it, or pull it in with the tongue, to collect it.
/// Children set on_collect to say what collecting does.
bob = random(2 * pi);
base_y = y;
grabbed = false;
grabber = noone;        // the snake whose tongue has it
spin = false;
image_speed = 0;
on_collect = function(_by) {};

/// Collected by snake _by (an obj_player).
collect_now = function(_by)
{
    on_collect(_by);
    instance_destroy();
};
