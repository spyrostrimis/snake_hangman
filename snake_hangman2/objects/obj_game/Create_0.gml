/// Snake Hangman v2: the same game as v1, dressed as the Hangman site's Hall of Fame page.
/// Rules: scr_word_rules. Look: scr_site_style. Local high scores: scr_hall_of_fame.

randomise();
site_style_init();
window_set_caption("Snake Hangman");

// ---------- Layout (pixels, room is 1280 x 720) ----------
cell   = 32;
grid_w = 25;
grid_h = 15;
grid_x = 240;
grid_y = 208;

// ---------- Tuning ----------
board_letter_count  = 6;
start_move_interval = 9;    // frames per step at level 1 (60 frames = 1 second)
min_move_interval   = 4;
speedup_per_letter  = 0.35;
points_per_letter   = 10;

// ---------- Run state ----------
words        = game_word_list();
state        = "title";     // title | play | paused | won | lost
total_points = 0;
level        = 1;
round_points = 0;
round_bonus  = 0;
run_words    = [];          // { word, points } for each word cleared this run
end_reason   = "";
last_word    = "";

// ---------- Local Hall of Fame ----------
hall        = hall_load();
hall_mine   = -1;           // index of this run's row after saving, else -1
naming      = false;        // typing a name for a new Hall of Fame entry
player_name = player_name_load();

// ---------- Round state ----------
word          = "";
guessed       = "";
snake         = [];
letters       = [];
input_queue   = [];
dir_x         = 1;
dir_y         = 0;
grow_pending  = 0;
move_interval = start_move_interval;
move_timer    = 0;
reveal_timers = [];

// ---------- Effects ----------
particles   = [];
shake       = 0;
flash_alpha = 0;
flash_col   = c_white;
frame       = 0;

/// Best saved score, for the capsule.
best_points = function()
{
    return (array_length(hall) > 0) ? hall[0].points : 0;
};

/// Starts a new word. _fresh = true also starts a new run.
start_round = function(_fresh)
{
    if (_fresh)
    {
        total_points = 0;
        level = 1;
        run_words = [];
        hall_mine = -1;
    }

    var _word = words[irandom(array_length(words) - 1)];
    if (array_length(words) > 1)
    {
        while (_word == last_word) _word = words[irandom(array_length(words) - 1)];
    }
    word = _word;
    last_word = _word;
    guessed = "";
    round_points = 0;
    reveal_timers = array_create(string_length(word), 0);

    var _cy = grid_h div 2;
    snake = [{ gx: 6, gy: _cy }, { gx: 5, gy: _cy }, { gx: 4, gy: _cy }];
    dir_x = 1;
    dir_y = 0;
    input_queue = [];
    grow_pending = 0;
    move_interval = max(min_move_interval, start_move_interval - (level - 1) * 0.5);
    move_timer = 0;
    letters = [];
    particles = [];
    refill_letters();
    state = "play";
};

cell_is_free = function(_gx, _gy)
{
    for (var _i = 0; _i < array_length(snake); _i++)
    {
        if (snake[_i].gx == _gx && snake[_i].gy == _gy) return false;
    }
    for (var _i = 0; _i < array_length(letters); _i++)
    {
        if (letters[_i].gx == _gx && letters[_i].gy == _gy) return false;
    }
    return true;
};

/// A random free cell at least 4 steps from the head, or undefined if the field is full.
find_free_cell = function()
{
    var _head = snake[0];
    repeat (400)
    {
        var _gx = irandom(grid_w - 1);
        var _gy = irandom(grid_h - 1);
        if (!cell_is_free(_gx, _gy)) continue;
        if (abs(_gx - _head.gx) + abs(_gy - _head.gy) < 4) continue;
        return { gx: _gx, gy: _gy };
    }
    for (var _gy = 0; _gy < grid_h; _gy++)
    {
        for (var _gx = 0; _gx < grid_w; _gx++)
        {
            if (cell_is_free(_gx, _gy)) return { gx: _gx, gy: _gy };
        }
    }
    return undefined;
};

add_letter = function(_ch)
{
    var _cell = find_free_cell();
    if (is_undefined(_cell)) return false;
    array_push(letters, { gx: _cell.gx, gy: _cell.gy, ch: _ch, age: 0 });
    return true;
};

/// Tops the field up to board_letter_count distinct, uneaten letters;
/// at least two of them (or all that remain) are in the word.
refill_letters = function()
{
    var _on_board = "";
    var _correct_on_board = 0;
    for (var _i = 0; _i < array_length(letters); _i++)
    {
        _on_board += letters[_i].ch;
        if (word_has_letter(word, letters[_i].ch)) _correct_on_board++;
    }

    var _hidden = word_hidden_letters(word, guessed);
    var _want_correct = min(2, array_length(_hidden));
    var _pool = [];
    for (var _i = 0; _i < array_length(_hidden); _i++)
    {
        if (string_pos(_hidden[_i], _on_board) == 0) array_push(_pool, _hidden[_i]);
    }
    while (_correct_on_board < _want_correct && array_length(_pool) > 0)
    {
        var _k = irandom(array_length(_pool) - 1);
        if (!add_letter(_pool[_k])) return;
        _on_board += _pool[_k];
        _correct_on_board++;
        array_delete(_pool, _k, 1);
    }

    _pool = [];
    for (var _c = 0; _c < 26; _c++)
    {
        var _ch = chr(ord("A") + _c);
        if (!letter_is_guessed(guessed, _ch) && string_pos(_ch, _on_board) == 0) array_push(_pool, _ch);
    }
    while (array_length(letters) < board_letter_count && array_length(_pool) > 0)
    {
        var _k = irandom(array_length(_pool) - 1);
        if (!add_letter(_pool[_k])) return;
        array_delete(_pool, _k, 1);
    }
};

queue_direction = function(_dx, _dy)
{
    var _n = array_length(input_queue);
    var _last_x = (_n > 0) ? input_queue[_n - 1][0] : dir_x;
    var _last_y = (_n > 0) ? input_queue[_n - 1][1] : dir_y;
    if (_dx == _last_x && _dy == _last_y) return;
    if (_dx == -_last_x && _dy == -_last_y) return;
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
    if (_nx < 0 || _ny < 0 || _nx >= grid_w || _ny >= grid_h)
    {
        lose_round("You hit the wall");
        return;
    }

    // The tail cell is vacated this step unless the snake is growing.
    var _check = array_length(snake) - ((grow_pending > 0) ? 0 : 1);
    for (var _i = 0; _i < _check; _i++)
    {
        if (snake[_i].gx == _nx && snake[_i].gy == _ny)
        {
            lose_round("You bit your tail");
            return;
        }
    }

    array_insert(snake, 0, { gx: _nx, gy: _ny });
    if (grow_pending > 0) grow_pending--;
    else array_pop(snake);

    for (var _i = 0; _i < array_length(letters); _i++)
    {
        if (letters[_i].gx == _nx && letters[_i].gy == _ny)
        {
            var _ch = letters[_i].ch;
            array_delete(letters, _i, 1);
            eat_letter(_ch, _nx, _ny);
            break;
        }
    }
};

eat_letter = function(_ch, _gx, _gy)
{
    guessed += _ch;
    var _px = grid_x + _gx * cell + cell / 2;
    var _py = grid_y + _gy * cell + cell / 2;
    var _s = global.site;

    if (word_has_letter(word, _ch))
    {
        var _n = word_count_letter(word, _ch);
        grow_pending += _n;
        round_points += points_per_letter * _n;
        total_points += points_per_letter * _n;
        for (var _i = 0; _i < string_length(word); _i++)
        {
            if (string_char_at(word, _i + 1) == _ch) reveal_timers[_i] = 40;
        }
        burst(_px, _py, _s.green, 20);
        flash(_s.green, 0.12);
        move_interval = max(min_move_interval, move_interval - speedup_per_letter);
        if (word_is_solved(word, guessed))
        {
            win_round();
            return;
        }
    }
    else
    {
        burst(_px, _py, _s.magenta, 20);
        flash(_s.magenta, 0.25);
        shake = 8;
        if (word_miss_count(word, guessed) >= MAX_MISSES)
        {
            lose_round("Out of chances");
            return;
        }
    }
    refill_letters();
};

win_round = function()
{
    round_bonus = 50 + (MAX_MISSES - word_miss_count(word, guessed)) * 10;
    round_points += round_bonus;
    total_points += round_bonus;
    array_push(run_words, { word: word, points: round_points });
    var _head = snake[0];
    burst(grid_x + _head.gx * cell + cell / 2, grid_y + _head.gy * cell + cell / 2, global.site.yellow, 40);
    state = "won";
};

lose_round = function(_reason)
{
    end_reason = _reason;
    shake = 12;
    flash(global.site.magenta, 0.4);
    state = "lost";
    hall_mine = -1;
    naming = hall_qualifies(hall, total_points);
    if (naming) keyboard_string = player_name;
};

/// Saves this run under the typed name and highlights its row.
save_entry = function()
{
    var _name = clean_player_name(keyboard_string);
    if (string_length(_name) == 0) return;
    player_name = _name;
    player_name_save(_name);
    hall_mine = hall_insert(hall, { name: _name, points: total_points, words: array_length(run_words) });
    hall_save(hall);
    naming = false;
};

burst = function(_x, _y, _col, _count)
{
    repeat (_count)
    {
        var _dir = random(360);
        var _spd = random_range(1.5, 5);
        array_push(particles, {
            px: _x, py: _y,
            vx: lengthdir_x(_spd, _dir), vy: lengthdir_y(_spd, _dir),
            life: 20 + irandom(15), col: _col
        });
    }
};

flash = function(_col, _alpha)
{
    flash_col = _col;
    flash_alpha = _alpha;
};

/// The Hall of Fame table, drawn like the site's: pink headings, dashed rows,
/// podium colours for the top three and this run's row highlighted with a "You" tag.
draw_hall_table = function(_x1, _x2, _y)
{
    var _s = global.site;
    var _f = global.fonts;
    var _rank_r = _x1 + 110;
    var _name_x = _x1 + 130;

    site_text_spaced(_rank_r, _y, "RANK", _f.label, _s.pink, 3, fa_right);
    site_text_spaced(_name_x, _y, "PLAYER", _f.label, _s.pink, 3);
    site_text_spaced(_x2 - 10, _y, "SCORE", _f.label, _s.pink, 3, fa_right);
    draw_set_colour(_s.pink);
    draw_set_alpha(0.33);
    draw_line(_x1, _y + 22, _x2, _y + 22);
    draw_set_alpha(1);

    if (array_length(hall) == 0)
    {
        site_text((_x1 + _x2) / 2, _y + 44, "No scores yet.", _f.mono, _s.text, fa_center);
        return _y + 90;
    }

    var _row_y = _y + 26;
    for (var _i = 0; _i < array_length(hall); _i++)
    {
        var _e = hall[_i];
        var _rank = hall_rank(hall, _i);
        var _h = (_rank == 1) ? 46 : 40;
        var _col = _s.cyan;
        if (_rank == 1) _col = _s.yellow;
        else if (_rank == 2) _col = _s.silver;
        else if (_rank == 3) _col = _s.bronze;
        var _font = (_rank == 1) ? _f.big : _f.row;
        var _ty = _row_y + (_h - ((_rank == 1) ? 30 : 24)) / 2;

        if (_i == hall_mine)
        {
            draw_set_colour(_s.cyan);
            draw_set_alpha(0.12);
            draw_rectangle(_x1, _row_y, _x2, _row_y + _h, false);
            draw_set_alpha(1);
            draw_rectangle(_x1, _row_y, _x1 + 2, _row_y + _h, false);
        }

        if (_rank <= 3) site_text_glow(_rank_r, _ty, ordinal(_rank), _font, _col, 4, 0.06, fa_right);
        else site_text(_rank_r, _ty, ordinal(_rank), _font, _col, fa_right);
        site_text(_name_x, _ty, _e.name, _font, _col);
        if (_rank <= 3) site_text_glow(_x2 - 10, _ty, format_points(_e.points), _font, _col, 4, 0.06, fa_right);
        else site_text(_x2 - 10, _ty, format_points(_e.points), _font, _col, fa_right);

        if (_i == hall_mine)
        {
            // The site's "You" tag: a small cyan pill after the name, centred on the row's text.
            draw_set_font(_font);
            var _tag_x = _name_x + string_width(_e.name) + 12;
            var _mid_y = _ty + string_height("A") * 0.5;
            draw_set_font(_f.label);
            var _tag_w = string_width("YOU") + 12;
            var _tag_h = string_height("YOU") + 2;
            draw_set_colour(_s.cyan);
            draw_roundrect_ext(_tag_x, _mid_y - _tag_h / 2, _tag_x + _tag_w, _mid_y + _tag_h / 2, 4, 4, false);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(make_colour_rgb(11, 12, 16));
            draw_text(_tag_x + _tag_w / 2, _mid_y + 1, "YOU");
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        }

        dashed_line(_x1, _x2, _row_y + _h, _s.line, 0.18);
        _row_y += _h;
    }
    return _row_y;
};
