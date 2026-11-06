/// Gems spin (by squeezing the sprite sideways); other items just float.
var _xs = spin ? cos(bob * 1.5) : 1;
draw_sprite_ext(sprite_index, 0, x, y, _xs, 1, 0, c_white, 1);
