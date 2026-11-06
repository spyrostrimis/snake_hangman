/// A boss projectile (a cheese wedge or a feather). The boss sets sprite, vx, vy and grav.
vx = 0;
vy = 0;
grav = 0;
life = 360;
sway = false;
image_speed = 0;
image_angle = random(360);
t = random(10);
net_id = -1;            // online: the same number on both PCs
net_tx = x;             // joiner: where the host says it is
net_ty = y;
