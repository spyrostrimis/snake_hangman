/// Parent of every item. Touch it, or pull it in with the tongue, to collect it.
/// Children set on_collect to say what collecting does.
bob = random(2 * pi);
base_y = y;
grabbed = false;
spin = false;
image_speed = 0;
on_collect = function() {};

collect_now = function()
{
    on_collect();
    instance_destroy();
};
