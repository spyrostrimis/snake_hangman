switch (weapon)
{
    case "bullet":
        draw_set_colour(make_colour_rgb(255, 236, 140));
        draw_line_width(px, py, x, y, 1);
        draw_set_colour(c_white);
        break;
    case "shell":
        draw_sprite(spr_shell, 0, x, y);
        break;
    case "rocket":
        draw_sprite_ext(spr_rocket, 0, x, y, 1, 1, dir, c_white, 1);
        break;
    case "artillery":
        var _k = min(1, t / max(1, life - 1));
        var _h = sin(_k * pi) * dist * 0.25;
        draw_set_alpha(0.35);
        draw_set_colour(c_black);
        draw_circle(x, y, 1.5, false);
        draw_set_alpha(1);
        draw_set_colour(c_white);
        var _ang = point_direction(px, py - sin(max(0, _k - 0.05) * pi) * dist * 0.25, x, y - _h);
        draw_sprite_ext(spr_rocket, 0, x, y - _h, 1, 1, _ang, c_white, 1);
        break;
}
