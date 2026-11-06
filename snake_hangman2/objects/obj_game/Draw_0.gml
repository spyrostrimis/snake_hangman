/// Draws the game as the site's Hall of Fame page: moonlit sky, yellow capsule,
/// neon title, pink table headings, dashed rows, cyan and podium colours.

var _s = global.site;
var _f = global.fonts;

// Screen shake moves the whole scene through the world matrix.
var _ox = (shake > 0) ? round(random_range(-shake, shake)) : 0;
var _oy = (shake > 0) ? round(random_range(-shake, shake)) : 0;
matrix_set(matrix_world, matrix_build(_ox, _oy, 0, 0, 0, 0, 1, 1, 1));

var _pulse = 0.5 + 0.5 * sin(frame * 0.08);
var _gx2 = grid_x + grid_w * cell;
var _gy2 = grid_y + grid_h * cell;
var _misses = word_miss_count(word, guessed);

// ---------- Background: the Hall of Fame moon, multiplied over #999 as on the site ----------
draw_set_colour(make_colour_rgb(24, 32, 40));
draw_rectangle(-16, -16, room_width + 16, room_height + 16, false);
draw_sprite_ext(spr_bg, 0, 0, 0, 1, 1, 0, make_colour_rgb(153, 153, 153), 1);

// ---------- Navigation capsule, holding the run's stats ----------
site_capsule(150, 12, 1130, 64);
var _nx = 186;
site_text_glow(_nx, 27, "Snake Hangman", _f.nav, _s.yellow, 3, 0.05);
draw_set_font(_f.nav);
var _active_w = string_width("Snake Hangman");
glow_roundrect(_nx, 52, _nx + _active_w, 54, 1, _s.neon, 0.8, 4);
draw_set_colour(_s.yellow);
draw_rectangle(_nx, 52, _nx + _active_w, 54, false);
_nx += _active_w + 40;
var _items = ["Level " + string(level), "Words " + string(array_length(run_words)), "Best " + format_points(max(best_points(), total_points))];
for (var _i = 0; _i < array_length(_items); _i++)
{
    site_text_glow(_nx, 27, _items[_i], _f.nav, _s.yellow, 3, 0.05);
    draw_set_font(_f.nav);
    _nx += string_width(_items[_i]) + 40;
}
draw_set_colour(_s.line);
draw_set_alpha(0.3);
draw_line(900, 16, 900, 60);
draw_set_alpha(1);
site_text(1100, 20, (player_name == "") ? "guest" : player_name, _f.mono_sm, _s.text, fa_right);
site_text_glow(1100, 38, format_points(total_points) + " pts", _f.small, _s.cyan, 3, 0.07, fa_right);

// ---------- Title, as on the Hall of Fame page ----------
site_text_glow(640, 64, "Snake Hangman", _f.title, _s.neon, 8, 0.07, fa_center);
site_text_spaced(640, 128, "Every right letter earns 10 points", _f.small, _s.subtitle, 2, fa_center);

// ---------- The hidden word ----------
var _n = string_length(word);
if (_n > 0)
{
    var _pitch = 46;
    var _wx = 640 - (_n * _pitch - 10) / 2;
    for (var _i = 0; _i < _n; _i++)
    {
        var _ch = string_char_at(word, _i + 1);
        var _sx = _wx + _i * _pitch;
        var _shown = letter_is_guessed(guessed, _ch);
        draw_set_colour(_shown ? _s.cyan : _s.pink);
        draw_set_alpha(_shown ? 0.9 : 0.5);
        draw_rectangle(_sx, 195, _sx + 35, 196, false);
        draw_set_alpha(1);
        if (_shown)
        {
            var _col = (reveal_timers[_i] > 0) ? merge_colour(_s.yellow, _s.green, reveal_timers[_i] / 40) : _s.yellow;
            site_text_glow(_sx + 18, 150 - reveal_timers[_i] div 8, _ch, _f.word, _col, 5, 0.08, fa_center);
        }
        else if (state == "lost")
        {
            site_text(_sx + 18, 150, _ch, _f.word, _s.magenta, fa_center);
        }
    }
}

// ---------- Left column: chances, used letters, Artsy ----------
site_text_spaced(40, 212, "CHANCES", _f.label, _s.muted, 2);
site_power_cells(40, 232, MAX_MISSES - _misses, MAX_MISSES);

site_text_spaced(40, 286, "USED LETTERS", _f.label, _s.muted, 2);
for (var _i = 1; _i <= string_length(guessed); _i++)
{
    var _ch = string_char_at(guessed, _i);
    var _ux = 40 + ((_i - 1) mod 6) * 28;
    var _uy = 306 + ((_i - 1) div 6) * 30;
    site_text(_ux, _uy, _ch, _f.tile, word_has_letter(word, _ch) ? _s.green : _s.magenta);
}

var _online = (state == "won");
draw_sprite(_online ? spr_artsy : spr_artsygray, 0, 24, 494);
site_text(120, 666, _online ? "Artsy is back online" : "Artsy is offline", _f.mono_sm, _online ? _s.green : _s.muted, fa_center);

// ---------- Right column: this run, as a small Hall of Fame table ----------
var _tx1 = 1064;
var _tx2 = 1248;
site_text_spaced(_tx1, 212, "THIS RUN", _f.label, _s.pink, 3);
site_text_spaced(_tx2, 212, "PTS", _f.label, _s.pink, 3, fa_right);
draw_set_colour(_s.pink);
draw_set_alpha(0.33);
draw_line(_tx1, 232, _tx2, 232);
draw_set_alpha(1);

var _rows = [];
var _first = max(0, array_length(run_words) - 9);
for (var _i = _first; _i < array_length(run_words); _i++) array_push(_rows, run_words[_i]);
var _ry = 236;
for (var _i = 0; _i < array_length(_rows); _i++)
{
    site_text(_tx1 + 8, _ry + 8, _rows[_i].word, _f.nav, _s.cyan);
    site_text(_tx2 - 4, _ry + 8, string(_rows[_i].points), _f.nav, _s.cyan, fa_right);
    dashed_line(_tx1, _tx2, _ry + 36, _s.line, 0.18);
    _ry += 36;
}
if (state == "play" || state == "paused")
{
    // The word in progress: highlighted like the signed-in player's row.
    draw_set_colour(_s.cyan);
    draw_set_alpha(0.12);
    draw_rectangle(_tx1, _ry, _tx2, _ry + 36, false);
    draw_set_alpha(1);
    draw_rectangle(_tx1, _ry, _tx1 + 2, _ry + 36, false);
    var _masked = "";
    for (var _i = 1; _i <= _n; _i++)
    {
        var _ch = string_char_at(word, _i);
        _masked += letter_is_guessed(guessed, _ch) ? _ch : "_";
    }
    site_text(_tx1 + 8, _ry + 8, _masked, _f.nav, _s.yellow);
    site_text(_tx2 - 4, _ry + 8, string(round_points), _f.nav, _s.yellow, fa_right);
    _ry += 36;
}
site_text_spaced(_tx1, _ry + 14, "TOTAL", _f.label, _s.muted, 2);
site_text_glow(_tx2 - 4, _ry + 8, format_points(total_points), _f.nav, _s.yellow, 3, 0.06, fa_right);

// ---------- Field: a dark pane over the moon, ruled like the table ----------
draw_set_colour(_s.space);
draw_set_alpha(0.45);
draw_rectangle(grid_x, grid_y, _gx2, _gy2, false);
draw_set_alpha(1);
for (var _gy = 1; _gy < grid_h; _gy++)
{
    dashed_line(grid_x, _gx2, grid_y + _gy * cell, _s.line, 0.08, 4, 6);
}
draw_set_colour(_s.pink);
draw_set_alpha(0.45);
draw_rectangle(grid_x, grid_y, _gx2, _gy2, true);
draw_set_alpha(1);

// ---------- Letters (all alike, so the field gives no hints) ----------
for (var _i = 0; _i < array_length(letters); _i++)
{
    var _l = letters[_i];
    var _x1 = grid_x + _l.gx * cell;
    var _y1 = grid_y + _l.gy * cell;
    var _a = min(1, _l.age / 15);
    draw_set_colour(_s.space);
    draw_set_alpha(0.75 * _a);
    draw_roundrect_ext(_x1 + 2, _y1 + 2, _x1 + cell - 3, _y1 + cell - 3, 6, 6, false);
    draw_set_colour(_s.silver);
    draw_set_alpha((0.3 + 0.15 * _pulse) * _a);
    draw_roundrect_ext(_x1 + 2, _y1 + 2, _x1 + cell - 3, _y1 + cell - 3, 6, 6, true);
    draw_set_alpha(1);
    site_text(_x1 + cell / 2, _y1 + 5, _l.ch, _f.tile, _s.silver, fa_center, _a);
}

// ---------- Snake: a yellow head (1st place) and a cyan body ----------
var _len = array_length(snake);
for (var _i = _len - 1; _i >= 0; _i--)
{
    var _seg = snake[_i];
    var _x1 = grid_x + _seg.gx * cell;
    var _y1 = grid_y + _seg.gy * cell;
    var _col = (_i == 0) ? _s.yellow : _s.cyan;
    var _alpha = (_i == 0) ? 1 : 1 - 0.45 * (_i / max(1, _len - 1));
    glow_roundrect(_x1 + 3, _y1 + 3, _x1 + cell - 4, _y1 + cell - 4, 8, _col, 0.5 * _alpha, 5);
    draw_set_colour(_col);
    draw_set_alpha(_alpha);
    draw_roundrect_ext(_x1 + 3, _y1 + 3, _x1 + cell - 4, _y1 + cell - 4, 8, 8, false);
    draw_set_alpha(1);

    if (_i == 0)
    {
        var _cx = _x1 + cell / 2;
        var _cy = _y1 + cell / 2;
        var _sx = -dir_y;
        var _sy = dir_x;
        for (var _e = -1; _e <= 1; _e += 2)
        {
            var _ex = _cx + dir_x * 4 + _sx * 6 * _e;
            var _ey = _cy + dir_y * 4 + _sy * 6 * _e;
            draw_set_colour(_s.space);
            draw_circle(_ex, _ey, 3.5, false);
            draw_set_colour(c_white);
            draw_circle(_ex + dir_x * 1.5, _ey + dir_y * 1.5, 1.2, false);
        }
    }
}

// ---------- Particles and flash ----------
gpu_set_blendmode(bm_add);
for (var _i = 0; _i < array_length(particles); _i++)
{
    var _p = particles[_i];
    draw_set_colour(_p.col);
    draw_set_alpha(min(1, _p.life / 20));
    draw_circle(_p.px, _p.py, 2.5, false);
}
if (flash_alpha > 0)
{
    draw_set_colour(flash_col);
    draw_set_alpha(flash_alpha);
    draw_rectangle(grid_x, grid_y, _gx2, _gy2, false);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

// ---------- Overlays ----------
var _blink = (frame div 30) mod 2 == 0;
if (state != "play")
{
    draw_set_colour(_s.space);
    draw_set_alpha(0.82);
    draw_rectangle(grid_x + 1, grid_y + 1, _gx2 - 1, _gy2 - 1, false);
    draw_set_alpha(1);

    switch (state)
    {
        case "title":
            site_text(640, 228, "Let's get competitive! Steer the snake into the letters of the hidden word.", _f.mono, _s.text, fa_center);
            site_text(640, 250, "Right letters make you grow; six wrong ones, a wall or your tail end the run.", _f.mono, _s.text, fa_center);
            var _end = draw_hall_table(400, 880, 292);
            site_button(640, _end + 22, "Press Enter to play", true, _pulse);
            site_text(640, _end + 84, "Arrows or WASD to move.  P to pause.", _f.mono_sm, _s.muted, fa_center);
            break;

        case "paused":
            site_text_glow(640, 380, "Paused", _f.title, _s.neon, 8, 0.09, fa_center);
            site_text(640, 446, "Press P to resume.", _f.mono, _s.text, fa_center);
            break;

        case "won":
            site_text_glow(640, 300, "Word clear", _f.title, _s.neon, 8, 0.09, fa_center);
            site_text_glow(640, 370, word, _f.word, _s.cyan, 5, 0.07, fa_center);
            site_text(640, 432, "+" + string(round_bonus) + " bonus. Your total is " + format_points(total_points) + " points.", _f.mono, _s.cyan, fa_center);
            site_button(640, 480, "Next word", true, _pulse);
            break;

        case "lost":
            site_text_glow(640, 228, end_reason, _f.big, _s.pink, 5, 0.08, fa_center);
            site_text(640, 276, "The word was", _f.mono, _s.muted, fa_center);
            site_text_glow(640, 298, word, _f.row, _s.yellow, 3, 0.06, fa_center);
            if (naming)
            {
                site_text(640, 356, "A new high score: " + format_points(total_points) + " points. Type your name:", _f.mono, _s.cyan, fa_center);
                var _typed = keyboard_string;
                site_text(640, 392, _typed, _f.big, _s.text, fa_center);
                draw_set_font(_f.big);
                var _cw = string_width(_typed);
                draw_set_colour(_s.cyan);
                draw_rectangle(490, 432, 790, 434, false);
                if (_blink)
                {
                    draw_set_colour(_s.yellow);
                    draw_rectangle(640 + _cw / 2 + 4, 394, 640 + _cw / 2 + 6, 424, false);
                }
                site_text(640, 448, "Letters or numbers. Enter to save, Esc to skip.", _f.mono_sm, _s.muted, fa_center);
            }
            else
            {
                var _line = "You scored " + format_points(total_points) + " points.";
                if (hall_mine >= 0) _line = "You are " + ordinal(hall_rank(hall, hall_mine)) + " with " + format_points(total_points) + " points.";
                site_text(640, 334, _line, _f.mono, _s.cyan, fa_center);
                var _end = draw_hall_table(400, 880, 362);
                site_button(640, _end + 16, "Play again", true, _pulse);
            }
            break;
    }
}
else
{
    site_text(640, 696, "Arrows or WASD to move.  P to pause.", _f.mono_sm, _s.muted, fa_center);
}

matrix_set(matrix_world, matrix_build_identity());
