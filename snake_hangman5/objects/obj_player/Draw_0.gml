/// The snake: body segments along the head's path, then the head, then the tongue.
/// While hurt it blinks; as a ball it is one rolling coil.

if (invuln > 0 && (invuln div 4) mod 2 == 0) exit;
var _g = obj_game;

if (ball)
{
    draw_sprite_ext(spr_snake_ball, 0, x, y - 4, 1, 1, ball_angle, c_white, 1);
    exit;
}

// Body: from the tail forward, so the segments nearest the head are on top.
var _moving = abs(vx) > 0.3 && on_ground;
var _n = body_len;
for (var _k = _n; _k >= 1; _k--)
{
    var _p = segs[_k - 1];
    var _wiggle = _moving ? sin(_g.frame * 0.35 + _k * 1.1) * 1.5 : 0;
    var _scale = 1 - (_k / (_n + 2)) * 0.45;
    // A swallowed egg: a bulge that travels from the neck to the tail.
    if (gulp_t > 0 && _k == clamp(ceil((1 - gulp_t / 45) * _n), 1, _n)) _scale *= 1.45;
    if (_k == _n)
    {
        draw_sprite_ext(spr_snake_tail, 0, _p[0], _p[1] + _wiggle, _scale + 0.2, _scale + 0.2, 0, c_white, 1);
        if (copter)
        {
            // The tail spins like a propeller to glide down gently.
            var _spin = _g.frame * 0.9;
            draw_set_colour(make_colour_rgb(150, 230, 110));
            draw_set_alpha(0.75);
            draw_ellipse(_p[0] - 14 * abs(cos(_spin)), _p[1] - 16, _p[0] + 14 * abs(cos(_spin)), _p[1] - 10, false);
            draw_set_alpha(1);
        }
    }
    else draw_sprite_ext(spr_snake_body, 0, _p[0], _p[1] + _wiggle, _scale, _scale, 0, c_white, 1);
}

// Head (facing left or right), with a little bob while running.
var _bob = (on_ground && abs(vx) > 0.5) ? sin(_g.frame * 0.4) : 0;
draw_sprite_ext(spr_snake_head, image_index, x, y - 3 + _bob, facing, 1, 0, c_white, 1);

// Tongue: a long pink ribbon with a forked tip.
if (tongue_len > 0)
{
    var _mx = mouth_x();
    var _my = mouth_y();
    var _tx = _mx + facing * tongue_len;
    draw_set_colour(make_colour_rgb(140, 10, 40));
    draw_line_width(_mx, _my, _tx, _my, 5);
    draw_set_colour(make_colour_rgb(255, 90, 130));
    draw_line_width(_mx, _my - 1, _tx, _my - 1, 3);
    draw_line_width(_tx, _my, _tx + facing * 7, _my - 5, 3);
    draw_line_width(_tx, _my, _tx + facing * 7, _my + 5, 3);
}
