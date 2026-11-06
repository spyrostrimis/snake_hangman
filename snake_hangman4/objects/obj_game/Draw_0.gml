/// Draws the arcade screen at 320 x 240: score bar, word and miss columns, the round, lives.

var _a = global.arc;
var _blink = (frame div 20) mod 2 == 0;
draw_clear(c_black);

// ---------- Score bar ----------
var _high = max(score_now, (array_length(hiscores) > 0) ? hiscores[0].points : 0);
pixel_text(24, 2, "1UP", 1, _a.p1);
pixel_text(72, 10, string(score_now), 1, c_white, fa_right);
pixel_text(160, 2, "HIGH SCORE", 1, _a.hi, fa_center);
pixel_text(160, 10, string(_high), 1, c_white, fa_center);
pixel_text(296, 2, "ROUND", 1, _a.round, fa_right);
pixel_text(296, 10, string(round_num), 1, c_white, fa_right);

if (state == "attract")
{
    // ---------- Attract mode: title page and score table, taking turns ----------
    for (var _i = 0; _i < array_length(attract_bubbles); _i++)
    {
        var _b = attract_bubbles[_i];
        draw_bubble(_b.x + sin(frame * 0.03 + _b.seed) * 3, _b.y, _b.r, _b.col, "", 0.4);
    }
    if ((frame div 360) mod 2 == 0)
    {
        // "SNAKE": one letter per bubble.
        var _title = "SNAKE";
        for (var _i = 0; _i < 5; _i++)
        {
            var _cx = 160 + (_i - 2) * 30;
            var _cy = 52 + round(sin(frame * 0.06 + _i * 0.9) * 3);
            draw_bubble(_cx, _cy, 14, _a.bubbles[_i], "");
            pixel_text_outline(_cx + 1, _cy - 9, string_char_at(_title, _i + 1), 3, c_white, make_colour_rgb(40, 20, 80), fa_center);
        }
        pixel_text_outline(160, 76, "HANGMAN", 4, _a.yellow, make_colour_rgb(140, 20, 40), fa_center, _a.orange);
        pixel_text_outline(160, 112, "* BUBBLE ROUNDS *", 1, _a.pink, c_black, fa_center);

        pixel_text(160, 134, "POP THE BUBBLES THAT SPELL THE SECRET WORD.", 1, c_white, fa_center);
        pixel_text(160, 144, "WRONG LETTERS COST A CHANCE. SIX, AND A LIFE.", 1, c_white, fa_center);
        pixel_text(160, 154, "BRICKS, YOUR TAIL AND FIZZ COST A LIFE TOO.", 1, c_white, fa_center);
        pixel_text(160, 164, "A PERFECT WORD GIVES AN EXTRA LIFE.", 1, _a.p1, fa_center);
        if (_blink) pixel_text_outline(160, 182, "PUSH ENTER TO START", 1, _a.yellow, c_black, fa_center);
        pixel_text(160, 200, "ARROWS MOVE  P PAUSE  M SOUND  C SCANLINES", 1, _a.round, fa_center);
        pixel_text(160, 214, "A TRIBUTE TO THE BUBBLE ARCADES OF THE 80S", 1, make_colour_rgb(150, 150, 170), fa_center);
        pixel_text(160, 224, "MADE WITH GAMEMAKER 2026", 1, make_colour_rgb(150, 150, 170), fa_center);
    }
    else
    {
        pixel_text_outline(160, 40, "BEST 5 PLAYERS", 2, _a.yellow, make_colour_rgb(140, 20, 40), fa_center, _a.orange);
        pixel_text(84, 72, "RANK", 1, _a.hi);
        pixel_text(124, 72, "NAME", 1, _a.hi);
        pixel_text(222, 72, "SCORE", 1, _a.hi, fa_right);
        pixel_text(250, 72, "RD", 1, _a.hi);
        for (var _i = 0; _i < array_length(hiscores); _i++)
        {
            var _e = hiscores[_i];
            var _col = _a.round;
            if (_i == 0) _col = _a.yellow;
            else if (_i == 1) _col = c_white;
            else if (_i == 2) _col = _a.orange;
            var _y = 90 + _i * 18;
            if (_i == hiscore_mine && !_blink) continue;
            pixel_text_outline(84, _y, ordinal(_i + 1), 1, _col, c_black);
            pixel_text_outline(124, _y, _e.initials, 1, _col, c_black);
            pixel_text_outline(222, _y, string(_e.points), 1, _col, c_black, fa_right);
            pixel_text_outline(250, _y, string(_e.round), 1, _col, c_black);
        }
        if (_blink) pixel_text_outline(160, 196, "PUSH ENTER TO START", 1, _a.yellow, c_black, fa_center);
    }
    pixel_text(316, 232, "CREDIT 1", 1, c_white, fa_right);
    exit;
}

// ---------- Left column: the secret word, one bubble per letter ----------
var _n = string_length(word);
for (var _i = 0; _i < _n; _i++)
{
    var _sy = 36 + _i * 17;
    if (state == "transition")
    {
        // The next word stays hidden until its round begins.
        draw_set_colour(make_colour_rgb(90, 90, 110));
        draw_circle(8, _sy, 7, true);
    }
    else if (slot_filled[_i])
    {
        var _col = (state == "clear") ? _a.bubbles[(_i + frame div 6) mod 6] : _a.bubbles[_i mod 6];
        draw_bubble(8, _sy, 7, _col, string_char_at(word, _i + 1));
    }
    else if (state == "gameover" || (state == "dying" && new_word_after_death))
    {
        draw_bubble(8, _sy, 7, make_colour_rgb(70, 70, 80), string_char_at(word, _i + 1));
    }
    else
    {
        draw_set_colour(make_colour_rgb(90, 90, 110));
        draw_circle(8, _sy, 7, true);
        pixel_text(6, _sy - 3, "?", 1, make_colour_rgb(90, 90, 110));
    }
}

// ---------- Right column: six chances; a miss fills one with a burst grey bubble ----------
for (var _i = 0; _i < MAX_MISSES; _i++)
{
    var _sy = 36 + _i * 17;
    if (_i < string_length(miss_letters))
    {
        draw_bubble(312, _sy, 7, make_colour_rgb(110, 110, 120), string_char_at(miss_letters, _i + 1));
        draw_set_colour(_a.hi);
        draw_line(305, _sy + 6, 319, _sy - 6);
    }
    else
    {
        draw_set_colour(_a.p1);
        draw_circle(312, _sy, 7, true);
    }
}

// ---------- The round (drawn into a surface; scrolls up between rounds) ----------
if (!surface_exists(surf_field)) surf_field = surface_create(field_w, field_h);
surface_set_target(surf_field);
draw_clear(c_black);
if (state == "transition" && surface_exists(surf_old))
{
    var _t = 1 - state_timer / 70;
    _t = _t * _t * (3 - 2 * _t);
    draw_surface(surf_old, 0, round(-_t * field_h));
    draw_field(0, round(field_h * (1 - _t)));
}
else
{
    draw_field(0, 0);
}
surface_reset_target();
draw_surface(surf_field, field_x, field_y);

// ---------- Letters flying from the field to the word column ----------
for (var _i = 0; _i < array_length(flyers); _i++)
{
    var _f = flyers[_i];
    var _t = clamp(_f.t, 0, 1);
    var _e = 1 - power(1 - _t, 2);
    var _tx = 8;
    var _ty = 36 + _f.slot * 17;
    draw_bubble(lerp(_f.sx, _tx, _e), lerp(_f.sy, _ty, _e) - sin(_t * pi) * 24, 7, _f.col, _f.ch);
}

// ---------- Messages over the round ----------
var _mx = field_x + field_w / 2;
var _my = field_y + field_h / 2;
switch (state)
{
    case "ready":
        pixel_text_outline(_mx, _my - 18, "ROUND " + string(round_num), 2, c_white, c_black, fa_center);
        pixel_text_outline(_mx, _my - 2, layout.name, 1, _a.round, c_black, fa_center);
        if (_blink) pixel_text_outline(_mx, _my + 10, "READY!", 2, _a.yellow, c_black, fa_center);
        break;
    case "paused":
        pixel_text_outline(_mx, _my - 8, "PAUSE", 2, _a.yellow, c_black, fa_center);
        break;
    case "clear":
        pixel_text_outline(_mx, _my - 26, perfect ? "PERFECT!" : "WORD CLEAR!", 2, _a.yellow, make_colour_rgb(140, 20, 40), fa_center, _a.orange);
        pixel_text_outline(_mx, _my - 6, word, 2, c_white, c_black, fa_center);
        pixel_text_outline(_mx, _my + 14, "BONUS " + string(clear_bonus), 1, _a.p1, c_black, fa_center);
        if (perfect) pixel_text_outline(_mx, _my + 26, "EXTRA LIFE!", 1, _a.pink, c_black, fa_center);
        break;
    case "dying":
        pixel_text_outline(_mx, _my - 8, death_reason, 2, _a.pink, c_black, fa_center);
        break;
    case "gameover":
        pixel_text_outline(_mx, _my - 20, "GAME OVER", 3, _a.hi, c_black, fa_center);
        pixel_text_outline(_mx, _my + 10, "THE WORD WAS " + word, 1, c_white, c_black, fa_center);
        break;
    case "initials":
        draw_set_colour(c_black);
        draw_set_alpha(0.75);
        draw_rectangle(field_x, field_y, field_x + field_w, field_y + field_h, false);
        draw_set_alpha(1);
        pixel_text_outline(_mx, _my - 50, "NEW HIGH SCORE!", 2, _a.yellow, make_colour_rgb(140, 20, 40), fa_center, _a.orange);
        pixel_text_outline(_mx, _my - 28, string(score_now), 2, c_white, c_black, fa_center);
        pixel_text(_mx, _my - 6, "ENTER YOUR INITIALS", 1, _a.round, fa_center);
        for (var _i = 0; _i < 3; _i++)
        {
            var _lx = _mx - 30 + _i * 30;
            var _show = _i != init_pos || _blink;
            if (_show) pixel_text_outline(_lx, _my + 8, chr(ord("A") + init_letters[_i]), 3, (_i == init_pos) ? _a.yellow : c_white, c_black, fa_center);
            draw_set_colour((_i == init_pos) ? _a.yellow : _a.round);
            draw_rectangle(_lx - 8, _my + 34, _lx + 8, _my + 35, false);
        }
        pixel_text(_mx, _my + 46, "TYPE OR USE ARROWS, THEN ENTER", 1, make_colour_rgb(150, 150, 170), fa_center);
        break;
}
if (state == "play" && hurry_flash > 0 && (hurry_flash div 8) mod 2 == 0)
{
    pixel_text_outline(_mx, _my - 8, "HURRY UP!", 2, _a.hi, c_black, fa_center);
}

// ---------- Lives and credit ----------
for (var _i = 0; _i < lives; _i++) draw_life_icon(2 + _i * 10, 234);
pixel_text(316, 233, "CREDIT 1", 1, c_white, fa_right);
