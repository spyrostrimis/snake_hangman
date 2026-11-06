/// Draws everything: background, HUD, field, letters, snake, effects and overlays.

// Screen shake moves the whole scene through the world matrix.
var _ox = (shake > 0) ? round(random_range(-shake, shake)) : 0;
var _oy = (shake > 0) ? round(random_range(-shake, shake)) : 0;
matrix_set(matrix_world, matrix_build(_ox, _oy, 0, 0, 0, 0, 1, 1, 1));

var _pulse = 0.5 + 0.5 * sin(frame * 0.08);
var _gx2 = grid_x + grid_w * cell - 1;
var _gy2 = grid_y + grid_h * cell - 1;

// ---------- Background ----------
draw_set_alpha(1);
draw_set_colour(col_bg);
draw_rectangle(-16, -16, room_width + 16, room_height + 16, false);

// ---------- HUD panel ----------
draw_set_colour(col_panel);
draw_rectangle(16, 12, room_width - 17, 143, false);
draw_neon_rect(16, 12, room_width - 17, 143, col_violet, 0.6);

draw_neon_text(36, 24, "SCORE " + string(total_score), 2, col_text, 0.25);
draw_neon_text(room_width / 2, 24, "SNAKE / HANGMAN", 2, col_magenta, 0.5, fa_center);
draw_neon_text(room_width - 36, 24, "BEST " + string(best_score), 2, col_dim, 0.15, fa_right);

// The hidden word: one slot per letter.
var _n = string_length(word);
if (_n > 0)
{
    var _pitch = 44;
    var _wx = room_width / 2 - (_n * _pitch - 12) / 2;
    for (var _i = 0; _i < _n; _i++)
    {
        var _ch = string_char_at(word, _i + 1);
        var _sx = _wx + _i * _pitch;
        var _shown = letter_is_guessed(guessed, _ch);
        draw_set_colour(_shown ? col_cyan : col_dim);
        draw_rectangle(_sx, 92, _sx + 31, 95, false);
        if (_shown)
        {
            var _col = (reveal_timers[_i] > 0) ? merge_colour(col_text, col_good, reveal_timers[_i] / 40) : col_text;
            draw_neon_text(_sx + 3, 50 - reveal_timers[_i] div 8, _ch, 5, _col, 0.4);
        }
        else if (state == "lost")
        {
            draw_neon_text(_sx + 3, 50, _ch, 5, col_bad, 0.3);
        }
    }
}

// Letters eaten so far: green if in the word, red if not.
draw_pixel_text(36, 112, "USED", 2, col_dim);
var _used_x = 36 + pixel_text_width("USED ", 2) + 6;
for (var _i = 1; _i <= string_length(guessed); _i++)
{
    var _ch = string_char_at(guessed, _i);
    draw_pixel_text(_used_x, 112, _ch, 2, word_has_letter(word, _ch) ? col_good : col_bad);
    _used_x += 18;
}

// Misses: six pips that turn red.
var _misses = word_miss_count(word, guessed);
var _pip_x = room_width - 36 - (MAX_MISSES * 22 - 6);
draw_pixel_text(_pip_x - 12, 112, "MISSES", 2, col_dim, 1, fa_right);
for (var _i = 0; _i < MAX_MISSES; _i++)
{
    var _x1 = _pip_x + _i * 22;
    if (_i < _misses)
    {
        draw_set_colour(col_bad);
        draw_rectangle(_x1, 110, _x1 + 15, 125, false);
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.25);
        draw_rectangle(_x1 - 3, 107, _x1 + 18, 128, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
    else
    {
        draw_set_colour(col_dim);
        draw_rectangle(_x1, 110, _x1 + 15, 125, true);
    }
}

// ---------- Field ----------
for (var _gy = 0; _gy < grid_h; _gy++)
{
    for (var _gx = 0; _gx < grid_w; _gx++)
    {
        draw_set_colour(((_gx + _gy) mod 2 == 0) ? col_tile_a : col_tile_b);
        var _x1 = grid_x + _gx * cell;
        var _y1 = grid_y + _gy * cell;
        draw_rectangle(_x1, _y1, _x1 + cell - 1, _y1 + cell - 1, false);
    }
}
draw_neon_rect(grid_x - 3, grid_y - 3, _gx2 + 3, _gy2 + 3, col_magenta, 0.7 + 0.3 * _pulse);

// ---------- Letters (all drawn alike, so the field gives no hints) ----------
for (var _i = 0; _i < array_length(letters); _i++)
{
    var _l = letters[_i];
    var _x1 = grid_x + _l.gx * cell;
    var _y1 = grid_y + _l.gy * cell;
    var _a = min(1, _l.age / 15);
    draw_set_alpha(_a);
    draw_set_colour(make_colour_rgb(30, 12, 48));
    draw_rectangle(_x1 + 3, _y1 + 3, _x1 + cell - 4, _y1 + cell - 4, false);
    gpu_set_blendmode(bm_add);
    draw_set_colour(col_magenta);
    draw_set_alpha(_a * (0.15 + 0.15 * _pulse));
    draw_rectangle(_x1 + 1, _y1 + 1, _x1 + cell - 2, _y1 + cell - 2, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(_a);
    draw_rectangle(_x1 + 3, _y1 + 3, _x1 + cell - 4, _y1 + cell - 4, true);
    draw_pixel_text(_x1 + cell / 2 + 1, _y1 + 6, _l.ch, 3, col_text, _a, fa_center);
}
draw_set_alpha(1);

// ---------- Snake (tail first, so the head is on top) ----------
var _len = array_length(snake);
for (var _i = _len - 1; _i >= 0; _i--)
{
    var _s = snake[_i];
    var _x1 = grid_x + _s.gx * cell;
    var _y1 = grid_y + _s.gy * cell;
    var _col = merge_colour(col_cyan, col_violet, (_len > 1) ? _i / (_len - 1) : 0);

    gpu_set_blendmode(bm_add);
    draw_set_colour(_col);
    draw_set_alpha(0.18);
    draw_rectangle(_x1 - 2, _y1 - 2, _x1 + cell + 1, _y1 + cell + 1, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_rectangle(_x1 + 2, _y1 + 2, _x1 + cell - 3, _y1 + cell - 3, false);
    draw_set_colour(merge_colour(_col, c_white, 0.35));
    draw_rectangle(_x1 + 2, _y1 + 2, _x1 + cell - 3, _y1 + 5, false);

    if (_i == 0)
    {
        // Eyes look the way the snake is heading.
        var _cx = _x1 + cell / 2;
        var _cy = _y1 + cell / 2;
        var _sx = -dir_y;
        var _sy = dir_x;
        for (var _e = -1; _e <= 1; _e += 2)
        {
            var _ex = _cx + dir_x * 5 + _sx * 7 * _e;
            var _ey = _cy + dir_y * 5 + _sy * 7 * _e;
            draw_set_colour(c_white);
            draw_rectangle(_ex - 3, _ey - 3, _ex + 3, _ey + 3, false);
            draw_set_colour(col_bg);
            draw_rectangle(_ex - 1 + dir_x * 2, _ey - 1 + dir_y * 2, _ex + 1 + dir_x * 2, _ey + 1 + dir_y * 2, false);
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
    draw_rectangle(_p.px - 2, _p.py - 2, _p.px + 2, _p.py + 2, false);
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
if (state != "play")
{
    draw_set_colour(col_bg);
    draw_set_alpha(0.78);
    draw_rectangle(grid_x, grid_y, _gx2, _gy2, false);
    draw_set_alpha(1);

    var _mx = grid_x + grid_w * cell / 2;
    var _my = grid_y + grid_h * cell / 2;
    var _blink = (frame div 30) mod 2 == 0;

    switch (state)
    {
        case "title":
            draw_neon_text(_mx, _my - 160, "SNAKE / HANGMAN", 6, col_magenta, 0.5, fa_center);
            draw_pixel_text(_mx, _my - 70, "A WORD IS HIDDEN IN THE BLANKS ABOVE.", 2, col_text, 1, fa_center);
            draw_pixel_text(_mx, _my - 44, "STEER INTO THE LETTERS YOU THINK ARE IN IT.", 2, col_text, 1, fa_center);
            draw_pixel_text(_mx, _my - 6, "RIGHT LETTER: IT IS REVEALED AND YOU GROW.", 2, col_good, 1, fa_center);
            draw_pixel_text(_mx, _my + 20, "WRONG LETTER: ONE MISS.", 2, col_bad, 1, fa_center);
            draw_pixel_text(_mx, _my + 46, "SIX MISSES, A WALL OR YOUR OWN TAIL ENDS THE RUN.", 2, col_bad, 1, fa_center);
            draw_pixel_text(_mx, _my + 90, "ARROWS OR WASD TO MOVE    P TO PAUSE", 2, col_dim, 1, fa_center);
            if (_blink) draw_neon_text(_mx, _my + 140, "PRESS ENTER TO START", 3, col_cyan, 0.5, fa_center);
            break;

        case "paused":
            draw_neon_text(_mx, _my - 40, "PAUSED", 6, col_cyan, 0.5, fa_center);
            draw_pixel_text(_mx, _my + 30, "PRESS P TO RESUME", 2, col_dim, 1, fa_center);
            break;

        case "won":
            draw_neon_text(_mx, _my - 120, "WORD CLEAR!", 6, col_good, 0.5, fa_center);
            draw_neon_text(_mx, _my - 40, word, 5, col_text, 0.4, fa_center);
            draw_pixel_text(_mx, _my + 30, "+" + string(round_bonus) + " BONUS    SCORE " + string(total_score), 2, col_cyan, 1, fa_center);
            if (_blink) draw_neon_text(_mx, _my + 90, "PRESS ENTER FOR THE NEXT WORD", 3, col_cyan, 0.5, fa_center);
            break;

        case "lost":
            draw_neon_text(_mx, _my - 120, end_reason, 5, col_bad, 0.5, fa_center);
            draw_pixel_text(_mx, _my - 50, "THE WORD WAS", 2, col_dim, 1, fa_center);
            draw_neon_text(_mx, _my - 26, word, 5, col_text, 0.4, fa_center);
            draw_pixel_text(_mx, _my + 40, "SCORE " + string(total_score) + "    BEST " + string(best_score), 2, col_cyan, 1, fa_center);
            if (_blink) draw_neon_text(_mx, _my + 90, "PRESS ENTER TO PLAY AGAIN", 3, col_cyan, 0.5, fa_center);
            break;
    }
}

// ---------- CRT scanlines over everything ----------
draw_set_colour(c_black);
draw_set_alpha(0.07);
for (var _y = 0; _y < room_height; _y += 3)
{
    draw_line(-16, _y, room_width + 16, _y);
}
draw_set_alpha(1);

matrix_set(matrix_world, matrix_build_identity());
