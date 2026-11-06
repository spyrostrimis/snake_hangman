/// Float gently; when the tongue has it, fly to the snake's mouth.
bob += 0.06;
if (grabbed && instance_exists(obj_player))
{
    var _mx = obj_player.mouth_x();
    var _my = obj_player.mouth_y();
    x = lerp(x, _mx, 0.3);
    y = lerp(y, _my, 0.3);
    if (point_distance(x, y, _mx, _my) < 8) collect_now();
}
else y = base_y + sin(bob) * 3;
