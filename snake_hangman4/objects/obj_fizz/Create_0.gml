/// Fizz: a grumpy spark-ball that bounces diagonally round the round and off every brick.
/// Positions are in pixels inside the cell area (0..272 x 0..192). obj_game draws it.
visible = false;
px = 0;
py = 0;
fizz_speed = 0.8;
vx = fizz_speed * choose(-1, 1);
vy = fizz_speed * choose(-1, 1);
spin = 0;
fizz_radius = 5;
