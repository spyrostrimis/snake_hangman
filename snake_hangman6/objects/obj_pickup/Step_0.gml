/// Float gently; when a tongue has it, fly to that snake's mouth.
bob += 0.06;
if (grabbed && !instance_exists(grabber)) { grabbed = false; grabber = noone; x = xstart; }
if (grabbed)
{
    var _mx = grabber.mouth_x();
    var _my = grabber.mouth_y();
    x = lerp(x, _mx, 0.3);
    y = lerp(y, _my, 0.3);
    if (point_distance(x, y, _mx, _my) < 8) collect_now(grabber);
}
else y = base_y + sin(bob) * 3;
