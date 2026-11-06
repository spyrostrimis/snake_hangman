/// Snake Hangman v4, "Bubble Rounds": an 80s bubble-arcade tribute.
/// The game runs at 320 x 240 and the window shows it at 3x with crisp pixels.

randomise();
pixel_font_init();
arcade_init();
window_set_caption("Snake Hangman: Bubble Rounds");
window_set_size(960, 720);
alarm[0] = 2;   // centre the window and size the GUI layer once it has resized

// ---------- Screen layout (game pixels) ----------
field_x = 16;            // the round (bricks and all) is drawn into a 288 x 208 surface here
field_y = 24;
field_w = 288;
field_h = 208;
surf_field = -1;
surf_old   = -1;         // the previous round, for the scroll between rounds

// ---------- Arcade state ----------
state        = "attract";   // attract | ready | play | paused | clear | transition | dying | gameover | initials
state_timer  = 0;
frame        = 0;
sound_on     = true;
crt_on       = true;
music_id     = -1;
sfx          = sfx_init();
words        = game_word_list();
layouts      = round_layouts();
treats       = treat_list();
hiscores     = hiscore_load();
hiscore_mine = -1;

score_now  = 0;
lives      = 3;
round_num  = 1;
last_word  = "";

// ---------- Round state ----------
layout       = layouts[0];
theme        = global.themes[0];
walls        = layout_walls(layout);
reachable    = layout_reachable(walls);
word         = "";
guessed      = "";
slot_filled  = [];
miss_letters = "";
flyers       = [];
snake        = [];
dir_x        = 1;
dir_y        = 0;
input_queue  = [];
grow_pending = 0;
move_interval = 10;
move_timer   = 0;
bubbles      = [];
treat        = undefined;
eaten_count  = 0;
round_timer  = 0;
hurry        = false;
hurry_flash  = 0;
death_reason = "";
new_word_after_death = false;
clear_bonus  = 0;
perfect      = false;

// ---------- Effects ----------
popups      = [];   // floating score numbers
pops        = [];   // bubble bursts
attract_bubbles = [];
for (var _i = 0; _i < 18; _i++)
{
    array_push(attract_bubbles, { x: random(320), y: random(240), r: irandom_range(4, 9), col: global.arc.bubbles[irandom(5)], spd: random_range(0.2, 0.6), seed: random(10) });
}

// ---------- Initials entry ----------
init_letters = [0, 0, 0];
init_pos     = 0;

// ---------- Helpers ----------
/// Cell centre in field-surface pixels.
cell_px = function(_gx) { return 16 + _gx * CELL; };
cell_py = function(_gy) { return 16 + _gy * CELL; };

play_sfx = function(_e)
{
    if (sound_on) audio_play_sound(_e.sound, 1, false);
};

music_start = function()
{
    music_stop();
    if (sound_on) music_id = audio_play_sound(sfx.music.sound, 0, true);
};

music_stop = function()
{
    if (music_id != -1) audio_stop_sound(music_id);
    music_id = -1;
};

/// True for edges and bricks; _ax, _ay are pixels inside the cell area (0..272 x 0..192).
is_solid = function(_ax, _ay)
{
    if (_ax < 0 || _ay < 0 || _ax >= GRID_W * CELL || _ay >= GRID_H * CELL) return true;
    return walls[floor(_ax / CELL)][floor(_ay / CELL)];
};

/// A new game from round 1.
new_game = function()
{
    score_now = 0;
    lives = 3;
    round_num = 1;
    hiscore_mine = -1;
    setup_round(true);
    enter_ready(150);
};

/// Sets up the round's bricks (if _new_layout) and a fresh word.
setup_round = function(_new_layout)
{
    if (_new_layout)
    {
        layout = layouts[(round_num - 1) mod array_length(layouts)];
        theme = global.themes[(round_num - 1) mod array_length(global.themes)];
        walls = layout_walls(layout);
        reachable = layout_reachable(walls);
    }
    var _word = words[irandom(array_length(words) - 1)];
    while (_word == last_word && array_length(words) > 1) _word = words[irandom(array_length(words) - 1)];
    word = _word;
    last_word = _word;
    guessed = "";
    miss_letters = "";
    slot_filled = array_create(string_length(word), false);
    flyers = [];
    bubbles = [];
    treat = undefined;
    eaten_count = 0;
    round_timer = 0;
    hurry = false;
    popups = [];
    pops = [];
    reset_snake();
    refill_bubbles();
};

/// Puts the snake back at the start and the fizzes back in their corner.
reset_snake = function()
{
    snake = [{ gx: START_GX, gy: START_GY }, { gx: START_GX - 1, gy: START_GY }, { gx: START_GX - 2, gy: START_GY }];
    dir_x = 1;
    dir_y = 0;
    input_queue = [];
    grow_pending = 0;
    move_timer = 0;
    move_interval = max(5, 10 - (round_num - 1) * 0.4);
    with (obj_fizz) instance_destroy();
    var _count = min(3, layout.fizz + floor((round_num - 1) / array_length(layouts)) + (hurry ? 1 : 0));
    repeat (_count) spawn_fizz();
};

/// A fizz in a free cell far from the snake's head.
spawn_fizz = function()
{
    var _best = undefined;
    repeat (60)
    {
        var _gx = irandom(GRID_W - 1);
        var _gy = irandom(GRID_H - 1);
        if (walls[_gx][_gy]) continue;
        if (abs(_gx - snake[0].gx) + abs(_gy - snake[0].gy) < 8) continue;
        _best = [_gx, _gy];
        break;
    }
    if (is_undefined(_best)) return;
    var _f = instance_create_layer(0, 0, "Instances", obj_fizz);
    _f.px = _best[0] * CELL + CELL / 2;
    _f.py = _best[1] * CELL + CELL / 2;
    _f.fizz_speed = 0.8 + 0.1 * min(5, round_num - 1);
    _f.vx = _f.fizz_speed * choose(-1, 1);
    _f.vy = _f.fizz_speed * choose(-1, 1);
};

enter_ready = function(_frames)
{
    state = "ready";
    state_timer = _frames;
    music_stop();
    play_sfx(sfx.start);
};

cell_is_free = function(_gx, _gy)
{
    if (walls[_gx][_gy] || !reachable[_gx][_gy]) return false;
    for (var _i = 0; _i < array_length(snake); _i++) if (snake[_i].gx == _gx && snake[_i].gy == _gy) return false;
    for (var _i = 0; _i < array_length(bubbles); _i++) if (bubbles[_i].gx == _gx && bubbles[_i].gy == _gy) return false;
    if (!is_undefined(treat) && treat.gx == _gx && treat.gy == _gy) return false;
    return true;
};

find_free_cell = function()
{
    repeat (400)
    {
        var _gx = irandom(GRID_W - 1);
        var _gy = irandom(GRID_H - 1);
        if (!cell_is_free(_gx, _gy)) continue;
        if (abs(_gx - snake[0].gx) + abs(_gy - snake[0].gy) < 3) continue;
        return [_gx, _gy];
    }
    return undefined;
};

add_bubble = function(_ch)
{
    var _c = find_free_cell();
    if (is_undefined(_c)) return false;
    array_push(bubbles, { gx: _c[0], gy: _c[1], ch: _ch, col: global.arc.bubbles[irandom(array_length(global.arc.bubbles) - 1)], age: 0, seed: random(10) });
    return true;
};

/// Five letter bubbles on the field, at least two of them (or all that remain) in the word.
refill_bubbles = function()
{
    var _on = "";
    var _right = 0;
    for (var _i = 0; _i < array_length(bubbles); _i++)
    {
        _on += bubbles[_i].ch;
        if (word_has_letter(word, bubbles[_i].ch)) _right++;
    }
    var _hidden = word_hidden_letters(word, guessed);
    var _pool = [];
    for (var _i = 0; _i < array_length(_hidden); _i++) if (string_pos(_hidden[_i], _on) == 0) array_push(_pool, _hidden[_i]);
    while (_right < min(2, array_length(_hidden)) && array_length(_pool) > 0)
    {
        var _k = irandom(array_length(_pool) - 1);
        if (!add_bubble(_pool[_k])) return;
        _on += _pool[_k];
        _right++;
        array_delete(_pool, _k, 1);
    }
    _pool = [];
    for (var _c = 0; _c < 26; _c++)
    {
        var _ch = chr(ord("A") + _c);
        if (!letter_is_guessed(guessed, _ch) && string_pos(_ch, _on) == 0) array_push(_pool, _ch);
    }
    while (array_length(bubbles) < 5 && array_length(_pool) > 0)
    {
        var _k = irandom(array_length(_pool) - 1);
        if (!add_bubble(_pool[_k])) return;
        array_delete(_pool, _k, 1);
    }
};

add_popup = function(_x, _y, _text, _col)
{
    array_push(popups, { x: _x, y: _y, text: _text, col: _col, life: 60 });
};

add_pop = function(_x, _y, _col)
{
    array_push(pops, { x: _x, y: _y, col: _col, life: 16 });
};

add_score = function(_points)
{
    score_now += _points;
};

queue_direction = function(_dx, _dy)
{
    var _n = array_length(input_queue);
    var _lx = (_n > 0) ? input_queue[_n - 1][0] : dir_x;
    var _ly = (_n > 0) ? input_queue[_n - 1][1] : dir_y;
    if ((_dx == _lx && _dy == _ly) || (_dx == -_lx && _dy == -_ly)) return;
    if (_n < 3) array_push(input_queue, [_dx, _dy]);
};

read_input = function()
{
    if (keyboard_check_pressed(vk_left)  || keyboard_check_pressed(ord("A"))) queue_direction(-1, 0);
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) queue_direction(1, 0);
    if (keyboard_check_pressed(vk_up)    || keyboard_check_pressed(ord("W"))) queue_direction(0, -1);
    if (keyboard_check_pressed(vk_down)  || keyboard_check_pressed(ord("S"))) queue_direction(0, 1);
};

advance_snake = function()
{
    if (array_length(input_queue) > 0)
    {
        dir_x = input_queue[0][0];
        dir_y = input_queue[0][1];
        array_delete(input_queue, 0, 1);
    }
    var _nx = snake[0].gx + dir_x;
    var _ny = snake[0].gy + dir_y;
    // The gap in the top and bottom walls: leave through one, come back through the other.
    if ((_ny < 0 || _ny >= GRID_H) && _nx >= GAP_FROM && _nx <= GAP_TO) _ny = (_ny + GRID_H) mod GRID_H;
    if (_nx < 0 || _ny < 0 || _nx >= GRID_W || _ny >= GRID_H || walls[_nx][_ny])
    {
        lose_life("BONK!", false);
        return;
    }
    var _check = array_length(snake) - ((grow_pending > 0) ? 0 : 1);
    for (var _i = 0; _i < _check; _i++)
    {
        if (snake[_i].gx == _nx && snake[_i].gy == _ny)
        {
            lose_life("OUCH, YOUR TAIL!", false);
            return;
        }
    }
    array_insert(snake, 0, { gx: _nx, gy: _ny });
    if (grow_pending > 0) grow_pending--;
    else array_pop(snake);

    if (!is_undefined(treat) && treat.gx == _nx && treat.gy == _ny)
    {
        var _t = treats[treat.kind];
        add_score(_t.points);
        add_popup(cell_px(_nx), cell_py(_ny) - 6, string(_t.points), global.arc.yellow);
        play_sfx(sfx.treat);
        treat = undefined;
    }

    for (var _i = 0; _i < array_length(bubbles); _i++)
    {
        if (bubbles[_i].gx == _nx && bubbles[_i].gy == _ny)
        {
            var _b = bubbles[_i];
            array_delete(bubbles, _i, 1);
            pop_bubble(_b);
            break;
        }
    }
};

/// The hangman rule, arcade style: right letters fly to the word column, wrong ones to the misses.
pop_bubble = function(_b)
{
    var _x = cell_px(_b.gx);
    var _y = cell_py(_b.gy);
    guessed += _b.ch;
    eaten_count++;
    add_pop(_x, _y, _b.col);
    play_sfx(sfx.pop);

    if (word_has_letter(word, _b.ch))
    {
        var _n = word_count_letter(word, _b.ch);
        grow_pending += _n;
        add_score(500 * _n);
        add_popup(_x, _y - 6, string(500 * _n), c_white);
        play_sfx(sfx.right);
        for (var _i = 0; _i < string_length(word); _i++)
        {
            if (string_char_at(word, _i + 1) == _b.ch)
            {
                array_push(flyers, { ch: _b.ch, col: _b.col, sx: field_x + _x, sy: field_y + _y, slot: _i, t: -_i * 0.08 });
            }
        }
        if (word_is_solved(word, guessed))
        {
            win_word();
            return;
        }
    }
    else
    {
        miss_letters += _b.ch;
        add_popup(_x, _y - 6, "MISS", global.arc.pink);
        play_sfx(sfx.wrong);
        if (string_length(miss_letters) >= MAX_MISSES)
        {
            lose_life("OUT OF CHANCES", true);
            return;
        }
    }

    // A treat after every third bubble.
    if (eaten_count mod 3 == 0 && is_undefined(treat))
    {
        var _c = find_free_cell();
        if (!is_undefined(_c)) treat = { gx: _c[0], gy: _c[1], kind: min(array_length(treats) - 1, irandom(round_num - 1)), life: 600 };
    }
    refill_bubbles();
};

win_word = function()
{
    perfect = string_length(miss_letters) == 0;
    clear_bonus = 1000 * string_length(word) + (perfect ? 5000 : 0);
    add_score(clear_bonus);
    if (perfect && lives < 5) lives++;
    music_stop();
    play_sfx(perfect ? sfx.extra : sfx.clear);
    state = "clear";
    state_timer = 180;
};

lose_life = function(_reason, _new_word)
{
    death_reason = _reason;
    new_word_after_death = _new_word;
    lives--;
    music_stop();
    play_sfx(sfx.death);
    state = "dying";
    state_timer = 90;
};

/// Draws a round's field (bricks, bubbles, treat, snake, fizzes, effects) at _ox, _oy
/// in the current target. Used for the live round and for the scroll between rounds.
draw_field = function(_ox, _oy)
{
    var _a = global.arc;
    draw_set_colour(c_black);
    draw_rectangle(_ox, _oy, _ox + field_w, _oy + field_h, false);

    // Brick shadows first (down and right), then the bricks: the 3D look of the cabinet era.
    draw_set_colour(theme.shadow);
    for (var _gx = 0; _gx < GRID_W; _gx++)
    {
        for (var _gy = 0; _gy < GRID_H; _gy++)
        {
            if (walls[_gx][_gy]) draw_rectangle(_ox + 8 + _gx * CELL + 4, _oy + 8 + _gy * CELL + 4, _ox + 8 + _gx * CELL + 20, _oy + 8 + _gy * CELL + 20, false);
        }
    }
    draw_rectangle(_ox + 8, _oy + 8, _ox + 12, _oy + field_h - 8, false);
    draw_rectangle(_ox + 8, _oy + 8, _ox + field_w - 8, _oy + 12, false);
    for (var _gx = 0; _gx < GRID_W; _gx++)
    {
        for (var _gy = 0; _gy < GRID_H; _gy++)
        {
            if (!walls[_gx][_gy]) continue;
            var _bx = _ox + 8 + _gx * CELL;
            var _by = _oy + 8 + _gy * CELL;
            draw_brick(_bx, _by, theme);
            draw_brick(_bx + 8, _by, theme);
            draw_brick(_bx, _by + 8, theme);
            draw_brick(_bx + 8, _by + 8, theme);
        }
    }
    // The border wall, with a gap top and bottom that the snake can wrap through.
    for (var _x = 0; _x < field_w; _x += 8)
    {
        var _gap = _x >= 8 + GAP_FROM * CELL && _x < 8 + (GAP_TO + 1) * CELL;
        if (!_gap) draw_brick(_ox + _x, _oy, theme);
        if (!_gap) draw_brick(_ox + _x, _oy + field_h - 8, theme);
    }
    for (var _y = 0; _y < field_h; _y += 8)
    {
        draw_brick(_ox, _oy + _y, theme);
        draw_brick(_ox + field_w - 8, _oy + _y, theme);
    }
    // The round number in the top-left corner.
    draw_set_colour(c_black);
    draw_rectangle(_ox + 1, _oy + 1, _ox + 2 + pixel_text_width(string(round_num), 1) + 1, _oy + 9, false);
    pixel_text(_ox + 2, _oy + 2, string(round_num), 1, _a.yellow);

    // Letter bubbles, bobbing.
    for (var _i = 0; _i < array_length(bubbles); _i++)
    {
        var _b = bubbles[_i];
        var _r = min(7, 1 + _b.age / 3);
        draw_bubble(_ox + cell_px(_b.gx), _oy + cell_py(_b.gy) + round(sin(frame * 0.08 + _b.seed) * 1.5), _r, _b.col, (_r >= 7) ? _b.ch : "");
    }

    // The treat (blinks before it goes).
    if (!is_undefined(treat) && (treat.life > 120 || (frame div 5) mod 2 == 0))
    {
        var _t = treats[treat.kind];
        var _w = string_length(_t.rows[0]);
        pixel_map(_ox + cell_px(treat.gx) - _w div 2, _oy + cell_py(treat.gy) - array_length(_t.rows) div 2 + round(sin(frame * 0.1)), _t.rows, _t.palette);
    }

    // The snake: a cheerful green snake with big arcade eyes.
    var _len = array_length(snake);
    var _flash = state == "dying" && (frame div 4) mod 2 == 0;
    for (var _i = _len - 1; _i >= 0; _i--)
    {
        var _s = snake[_i];
        var _cx = _ox + cell_px(_s.gx);
        var _cy = _oy + cell_py(_s.gy);
        var _r = (_i == 0) ? 7 : ((_i == _len - 1) ? 5 : 6);
        draw_set_colour(_flash ? c_white : _a.snake_dark);
        draw_circle(_cx, _cy, _r, false);
        draw_set_colour(_flash ? c_white : _a.snake);
        draw_circle(_cx, _cy, _r - 1, false);
        draw_set_colour(_a.snake_light);
        draw_rectangle(_cx - 3, _cy - 4, _cx - 1, _cy - 2, false);
        if (_i > 0 && _i mod 2 == 0)
        {
            draw_set_colour(_a.yellow);
            draw_rectangle(_cx, _cy, _cx + 2, _cy + 2, false);
        }
    }
    if (_len > 0)
    {
        var _hx = _ox + cell_px(snake[0].gx);
        var _hy = _oy + cell_py(snake[0].gy);
        if (state == "dying")
        {
            // Dizzy stars round the head.
            for (var _k = 0; _k < 3; _k++)
            {
                var _ang = frame * 8 + _k * 120;
                pixel_text(_hx + lengthdir_x(9, _ang) - 2, _hy - 6 + lengthdir_y(4, _ang), "*", 1, _a.yellow);
            }
        }
        else
        {
            // Two big eyes looking the way it moves, and a tongue that flicks now and then.
            for (var _e = -1; _e <= 1; _e += 2)
            {
                var _ex = _hx + dir_x * 2 + (-dir_y) * 3 * _e;
                var _ey = _hy + dir_y * 2 + dir_x * 3 * _e - 1;
                draw_set_colour(c_white);
                draw_circle(_ex, _ey, 2.5, false);
                draw_set_colour(c_black);
                draw_rectangle(_ex + dir_x, _ey + dir_y, _ex + dir_x + 1, _ey + dir_y + 1, false);
            }
            if ((frame mod 90) < 12)
            {
                draw_set_colour(make_colour_rgb(255, 60, 80));
                draw_line(_hx + dir_x * 7, _hy + dir_y * 7, _hx + dir_x * 11, _hy + dir_y * 11);
            }
        }
    }

    // Fizzes: spiky sparks with grumpy eyes.
    with (obj_fizz)
    {
        var _fx = _ox + 8 + px;
        var _fy = _oy + 8 + py;
        draw_set_colour(make_colour_rgb(255, 60, 40));
        for (var _k = 0; _k < 8; _k++)
        {
            var _ang = spin + _k * 45;
            draw_line(_fx, _fy, _fx + lengthdir_x(7, _ang), _fy + lengthdir_y(7, _ang));
        }
        draw_set_colour(make_colour_rgb(255, 220, 40));
        draw_circle(_fx, _fy, 4, false);
        draw_set_colour(c_black);
        draw_rectangle(_fx - 2, _fy - 1, _fx - 1, _fy, false);
        draw_rectangle(_fx + 1, _fy - 1, _fx + 2, _fy, false);
        draw_line(_fx - 3, _fy - 3, _fx - 1, _fy - 2);
        draw_line(_fx + 3, _fy - 3, _fx + 1, _fy - 2);
    }

    // Bursts and floating scores.
    for (var _i = 0; _i < array_length(pops); _i++)
    {
        var _p = pops[_i];
        var _r = 4 + (16 - _p.life) * 0.7;
        draw_set_colour(_p.col);
        draw_circle(_ox + _p.x, _oy + _p.y, _r, true);
        for (var _k = 0; _k < 4; _k++)
        {
            var _ang = 45 + _k * 90;
            pixel_text(_ox + _p.x + lengthdir_x(_r + 2, _ang) - 2, _oy + _p.y + lengthdir_y(_r + 2, _ang) - 3, "+", 1, c_white, fa_left, _p.life / 16);
        }
    }
    for (var _i = 0; _i < array_length(popups); _i++)
    {
        var _p = popups[_i];
        pixel_text_outline(_ox + _p.x, _oy + _p.y, _p.text, 1, _p.col, c_black, fa_center, undefined, false);
    }
};
