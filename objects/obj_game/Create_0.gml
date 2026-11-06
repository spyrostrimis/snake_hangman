/// Snake / Hangman: one controller object owns the whole game.
/// The word rules live in scr_word_rules; the text drawing in scr_pixel_font.

randomise();
pixel_font_init();
window_set_caption("Snake / Hangman");

// ---------- Layout (pixels) ----------
cell = 32;
grid_w = 28;
grid_h = 14;
grid_x = 32;
grid_y = 160;

// ---------- Neon palette ----------
col_bg      = make_colour_rgb(10, 6, 22);
col_panel   = make_colour_rgb(18, 10, 36);
col_tile_a  = make_colour_rgb(21, 13, 42);
col_tile_b  = make_colour_rgb(26, 16, 51);
col_cyan    = make_colour_rgb(64, 240, 255);
col_magenta = make_colour_rgb(255, 64, 200);
col_violet  = make_colour_rgb(150, 90, 255);
col_good    = make_colour_rgb(90, 255, 140);
col_bad     = make_colour_rgb(255, 70, 90);
col_text    = make_colour_rgb(232, 226, 255);
col_dim     = make_colour_rgb(115, 100, 165);

// ---------- Tuning ----------
board_letter_count  = 6;    // letters on the field at once
start_move_interval = 9;    // frames per snake step at level 1 (60 frames = 1 second)
min_move_interval   = 4;    // fastest the snake ever gets
speedup_per_letter  = 0.35; // frames shaved off per correct letter

// ---------- Run state ----------
words       = game_word_list();
state       = "title";      // title | play | paused | won | lost
total_score = 0;
best_score  = 0;
level       = 1;
round_bonus = 0;
end_reason  = "";
last_word   = "";

// ---------- Round state (filled by start_round) ----------
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

/// Starts a new word. _fresh = true also resets score and level.
start_round = function(_fresh)
{
    if (_fresh)
    {
        total_score = 0;
        level = 1;
    }

    var _word = words[irandom(array_length(words) - 1)];
    if (array_length(words) > 1)
    {
        while (_word == last_word) _word = words[irandom(array_length(words) - 1)];
    }
    word = _word;
    last_word = _word;
    guessed = "";
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

/// True if no snake segment and no letter occupies grid cell (_gx, _gy).
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

/// A random free cell at least 4 steps from the snake's head, or undefined.
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

/// Places letter _ch on a free cell. Returns false if the field is full.
add_letter = function(_ch)
{
    var _cell = find_free_cell();
    if (is_undefined(_cell)) return false;
    array_push(letters, { gx: _cell.gx, gy: _cell.gy, ch: _ch, age: 0 });
    return true;
};

/// Tops the field up to board_letter_count distinct, uneaten letters.
/// At least two of them (or all that remain) are in the word, so a right answer is always on the field.
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

    // The rest: any uneaten letter, right or wrong, so the field gives nothing away.
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

/// Queues a turn, ignoring repeats and direct reversals (max 3 queued).
queue_direction = function(_dx, _dy)
{
    var _n = array_length(input_queue);
    var _last_x = (_n > 0) ? input_queue[_n - 1][0] : dir_x;
    var _last_y = (_n > 0) ? input_queue[_n - 1][1] : dir_y;
    if (_dx == _last_x && _dy == _last_y) return;
    if (_dx == -_last_x && _dy == -_last_y) return;
    if (_n < 3) array_push(input_queue, [_dx, _dy]);
};

/// Reads arrow keys and WASD.
read_input = function()
{
    if (keyboard_check_pressed(vk_left)  || keyboard_check_pressed(ord("A"))) queue_direction(-1, 0);
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) queue_direction(1, 0);
    if (keyboard_check_pressed(vk_up)    || keyboard_check_pressed(ord("W"))) queue_direction(0, -1);
    if (keyboard_check_pressed(vk_down)  || keyboard_check_pressed(ord("S"))) queue_direction(0, 1);
};

/// Moves the snake one cell: walls, self-bites and letters are checked here.
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
        lose_round("YOU HIT THE WALL");
        return;
    }

    // The tail cell is vacated this step unless the snake is growing.
    var _check = array_length(snake) - ((grow_pending > 0) ? 0 : 1);
    for (var _i = 0; _i < _check; _i++)
    {
        if (snake[_i].gx == _nx && snake[_i].gy == _ny)
        {
            lose_round("YOU BIT YOURSELF");
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

/// Applies the hangman rule to an eaten letter.
eat_letter = function(_ch, _gx, _gy)
{
    guessed += _ch;
    var _px = grid_x + _gx * cell + cell / 2;
    var _py = grid_y + _gy * cell + cell / 2;

    if (word_has_letter(word, _ch))
    {
        var _n = word_count_letter(word, _ch);
        grow_pending += _n;
        total_score += 10 * _n;
        for (var _i = 0; _i < string_length(word); _i++)
        {
            if (string_char_at(word, _i + 1) == _ch) reveal_timers[_i] = 40;
        }
        burst(_px, _py, col_good, 20);
        flash(col_good, 0.15);
        move_interval = max(min_move_interval, move_interval - speedup_per_letter);
        if (word_is_solved(word, guessed))
        {
            win_round();
            return;
        }
    }
    else
    {
        burst(_px, _py, col_bad, 20);
        flash(col_bad, 0.3);
        shake = 8;
        if (word_miss_count(word, guessed) >= MAX_MISSES)
        {
            lose_round("OUT OF MISSES");
            return;
        }
    }
    refill_letters();
};

win_round = function()
{
    round_bonus = 50 + (MAX_MISSES - word_miss_count(word, guessed)) * 10;
    total_score += round_bonus;
    best_score = max(best_score, total_score);
    var _head = snake[0];
    burst(grid_x + _head.gx * cell + cell / 2, grid_y + _head.gy * cell + cell / 2, col_cyan, 40);
    state = "won";
};

lose_round = function(_reason)
{
    end_reason = _reason;
    best_score = max(best_score, total_score);
    shake = 12;
    flash(col_bad, 0.45);
    state = "lost";
};

// ---------- Effects helpers ----------
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

/// Neon rectangle outline with an additive glow.
draw_neon_rect = function(_x1, _y1, _x2, _y2, _col, _glow)
{
    gpu_set_blendmode(bm_add);
    draw_set_colour(_col);
    for (var _g = 5; _g >= 1; _g--)
    {
        draw_set_alpha(_glow * (1 - _g / 6) * 0.45);
        draw_rectangle(_x1 - _g, _y1 - _g, _x2 + _g, _y2 + _g, true);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_rectangle(_x1, _y1, _x2, _y2, true);
    draw_rectangle(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, true);
};
