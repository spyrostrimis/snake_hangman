/// Snake Hangman v3: the homepage look, walls, debris on paths, Han's hint orb,
/// a particle starfield, a shader on the play field and sounds made in code.

randomise();
site_style_init();
window_set_caption("Snake Hangman: Rescue Mission");

// ---------- Layout ----------
cell    = 32;
grid_x  = 280;
grid_y  = 200;
field_w = GRID_W * cell;   // 704
field_h = GRID_H * cell;   // 480
field_surface = -1;

// ---------- Tuning ----------
board_letter_count  = 6;
start_move_interval = 9;
min_move_interval   = 4;
speedup_per_letter  = 0.3;
points_per_letter   = 10;
hint_length         = 360;   // frames a hint lasts (6 s)
hint_orb_life       = 480;   // frames an uneaten orb stays (8 s)

// ---------- Run state ----------
words        = game_word_list();
layouts      = level_layouts();
state        = "title";      // title | play | paused | won | lost
total_points = 0;
level        = 1;
words_cleared = 0;
round_bonus  = 0;
end_reason   = "";
last_word    = "";
new_best     = false;
letters_eaten = 0;
letters_right = 0;
ini_open("snake_hangman3.ini");
best_points = ini_read_real("best", "points", 0);
ini_close();

// ---------- Round state ----------
layout        = layouts[0];
walls         = level_walls(layout);
reachable     = level_reachable(walls, START_GX, START_GY);
word          = "";
guessed       = "";
snake         = [];
letters       = [];
input_queue   = [];
dir_x         = 1;
dir_y         = 0;
launched      = false;
grow_pending  = 0;
move_interval = start_move_interval;
move_timer    = 0;
reveal_timers = [];
hint_orb      = undefined;  // { gx, gy, life }
hint_timer    = 0;
hint_cooldown = 600;
debris_paths  = [];

// ---------- Effects ----------
frame        = 0;
shake        = 0;
hit          = 0;   // shader ripple, 0..1
glow         = 0;   // shader green wash, 0..1
punch        = 0;   // zoom pulse on a cleared word, 0..1
banner_timer = 0;
sound_on     = true;
sfx          = sfx_init();
u_time   = shader_get_uniform(shd_field, "u_time");
u_hit    = shader_get_uniform(shd_field, "u_hit");
u_glow   = shader_get_uniform(shd_field, "u_glow");
u_height = shader_get_uniform(shd_field, "u_height");

// ---------- Particles (GameMaker's built-in particle system) ----------
// Back system: the warp starfield inside the field, like the homepage background.
ps_back = part_system_create();
part_system_automatic_draw(ps_back, false);
part_system_automatic_update(ps_back, false);   // updated in Step, drawn into the field surface
pt_warp = part_type_create();
part_type_shape(pt_warp, pt_shape_line);
part_type_size(pt_warp, 0.05, 0.16, 0.004, 0);
part_type_orientation(pt_warp, 0, 0, 0, 0, true);
part_type_direction(pt_warp, 0, 360, 0, 0);
part_type_speed(pt_warp, 0.2, 0.8, 0.06, 0);
part_type_colour2(pt_warp, c_white, make_colour_rgb(150, 230, 255));
part_type_alpha3(pt_warp, 0, 0.55, 0);
part_type_blend(pt_warp, true);
part_type_life(pt_warp, 70, 120);

// Front system: sparks, rings and the snake's trail.
ps_front = part_system_create();
part_system_automatic_draw(ps_front, false);
part_system_automatic_update(ps_front, false);
pt_spark = part_type_create();
part_type_shape(pt_spark, pt_shape_spark);
part_type_size(pt_spark, 0.08, 0.22, -0.004, 0);
part_type_direction(pt_spark, 0, 360, 0, 0);
part_type_speed(pt_spark, 1.5, 5, -0.12, 0);
part_type_alpha2(pt_spark, 1, 0);
part_type_blend(pt_spark, true);
part_type_life(pt_spark, 20, 38);

pt_ring = part_type_create();
part_type_shape(pt_ring, pt_shape_ring);
part_type_size(pt_ring, 0.12, 0.12, 0.035, 0);
part_type_alpha2(pt_ring, 0.9, 0);
part_type_blend(pt_ring, true);
part_type_life(pt_ring, 24, 24);

pt_trail = part_type_create();
part_type_shape(pt_trail, pt_shape_disk);
part_type_size(pt_trail, 0.05, 0.09, -0.002, 0);
part_type_alpha2(pt_trail, 0.6, 0);
part_type_blend(pt_trail, true);
part_type_life(pt_trail, 18, 28);

/// Pre-fill the starfield so it doesn't start empty.
repeat (160)
{
    part_particles_create(ps_back, field_w / 2 + random_range(-40, 40), field_h / 2 + random_range(-30, 30), pt_warp, 1);
    part_system_update(ps_back);
}

// ---------- Helpers ----------

/// Cell centre in field (surface) coordinates.
cell_cx = function(_gx) { return _gx * cell + cell / 2; };
cell_cy = function(_gy) { return _gy * cell + cell / 2; };

play_sfx = function(_effect)
{
    if (sound_on) sfx_play(_effect);
};

/// Starts a word on the stage for the current level. _fresh = true also starts a new run.
start_round = function(_fresh)
{
    if (_fresh)
    {
        total_points = 0;
        level = 1;
        words_cleared = 0;
        letters_eaten = 0;
        letters_right = 0;
        new_best = false;
    }

    layout = layouts[(level - 1) mod array_length(layouts)];
    walls = level_walls(layout);
    reachable = level_reachable(walls, START_GX, START_GY);

    var _word = words[irandom(array_length(words) - 1)];
    if (array_length(words) > 1)
    {
        while (_word == last_word) _word = words[irandom(array_length(words) - 1)];
    }
    word = _word;
    last_word = _word;
    guessed = "";
    reveal_timers = array_create(string_length(word), 0);

    snake = [{ gx: START_GX, gy: START_GY }, { gx: START_GX - 1, gy: START_GY }, { gx: START_GX - 2, gy: START_GY }];
    dir_x = 1;
    dir_y = 0;
    launched = false;
    input_queue = [];
    grow_pending = 0;
    move_interval = max(min_move_interval, start_move_interval - (level - 1) * 0.4);
    move_timer = 0;
    letters = [];
    hint_orb = undefined;
    hint_timer = 0;
    hint_cooldown = 600;
    part_particles_clear(ps_front);
    spawn_debris();
    refill_letters();
    banner_timer = 150;
    state = "play";
};

/// Removes old debris and their paths, then launches this stage's debris along new paths.
spawn_debris = function()
{
    with (obj_debris) instance_destroy();
    for (var _i = 0; _i < array_length(debris_paths); _i++) path_delete(debris_paths[_i]);
    debris_paths = [];

    var _faster = 1 + floor((level - 1) / array_length(layouts)) * 0.25;
    for (var _i = 0; _i < array_length(layout.debris); _i++)
    {
        var _d = layout.debris[_i];
        var _path = path_add();
        for (var _k = 0; _k < array_length(_d.points); _k++)
        {
            path_add_point(_path, grid_x + cell_cx(_d.points[_k][0]), grid_y + cell_cy(_d.points[_k][1]), 100);
        }
        path_set_closed(_path, _d.closed);
        path_set_kind(_path, _d.closed ? 1 : 0);   // smooth curves for loops
        array_push(debris_paths, _path);
        var _inst = instance_create_layer(0, 0, "Instances", obj_debris);
        with (_inst)
        {
            path_start(_path, _d.speed * _faster, _d.closed ? path_action_restart : path_action_reverse, true);
            path_position = random(1);
            cruise_speed = path_speed;
        }
    }
};

/// Stops or resumes every piece of debris (pause, overlays).
set_debris_moving = function(_moving)
{
    with (obj_debris) path_speed = _moving ? cruise_speed : 0;
};

cell_is_free = function(_gx, _gy)
{
    if (walls[_gx][_gy] || !reachable[_gx][_gy]) return false;
    for (var _i = 0; _i < array_length(snake); _i++)
    {
        if (snake[_i].gx == _gx && snake[_i].gy == _gy) return false;
    }
    for (var _i = 0; _i < array_length(letters); _i++)
    {
        if (letters[_i].gx == _gx && letters[_i].gy == _gy) return false;
    }
    if (!is_undefined(hint_orb) && hint_orb.gx == _gx && hint_orb.gy == _gy) return false;
    return true;
};

/// A random free, reachable cell at least 4 steps from the head, or undefined.
find_free_cell = function()
{
    var _head = snake[0];
    repeat (500)
    {
        var _gx = irandom(GRID_W - 1);
        var _gy = irandom(GRID_H - 1);
        if (!cell_is_free(_gx, _gy)) continue;
        if (abs(_gx - _head.gx) + abs(_gy - _head.gy) < 4) continue;
        return { gx: _gx, gy: _gy };
    }
    for (var _gy = 0; _gy < GRID_H; _gy++)
    {
        for (var _gx = 0; _gx < GRID_W; _gx++)
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
    array_push(letters, { gx: _cell.gx, gy: _cell.gy, ch: _ch, age: 0, seed: random(10) });
    part_particles_create_colour(ps_front, cell_cx(_cell.gx), cell_cy(_cell.gy), pt_ring, global.site.cyan, 1);
    return true;
};

/// Tops the field up to board_letter_count distinct, uneaten letters; at least two are in the word.
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

/// Queues a turn; returns true if it was accepted (not a repeat or a reversal).
queue_direction = function(_dx, _dy)
{
    var _n = array_length(input_queue);
    var _last_x = (_n > 0) ? input_queue[_n - 1][0] : dir_x;
    var _last_y = (_n > 0) ? input_queue[_n - 1][1] : dir_y;
    if (_dx == -_last_x && _dy == -_last_y) return false;
    if (_dx == _last_x && _dy == _last_y) return true;
    if (_n < 3) array_push(input_queue, [_dx, _dy]);
    return true;
};

/// Arrow keys and WASD. The first accepted direction launches the snake.
read_input = function()
{
    var _accepted = false;
    if (keyboard_check_pressed(vk_left)  || keyboard_check_pressed(ord("A"))) _accepted = queue_direction(-1, 0) || _accepted;
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) _accepted = queue_direction(1, 0) || _accepted;
    if (keyboard_check_pressed(vk_up)    || keyboard_check_pressed(ord("W"))) _accepted = queue_direction(0, -1) || _accepted;
    if (keyboard_check_pressed(vk_down)  || keyboard_check_pressed(ord("S"))) _accepted = queue_direction(0, 1) || _accepted;
    if (_accepted && !launched)
    {
        launched = true;
        move_timer = move_interval;   // move straight away
    }
};

advance_snake = function()
{
    if (array_length(input_queue) > 0)
    {
        if (input_queue[0][0] != dir_x || input_queue[0][1] != dir_y) play_sfx(sfx.turn);
        dir_x = input_queue[0][0];
        dir_y = input_queue[0][1];
        array_delete(input_queue, 0, 1);
    }

    var _old = snake[0];
    var _nx = _old.gx + dir_x;
    var _ny = _old.gy + dir_y;
    if (_nx < 0 || _ny < 0 || _nx >= GRID_W || _ny >= GRID_H)
    {
        lose_round("You hit the edge");
        return;
    }
    if (walls[_nx][_ny])
    {
        lose_round("You hit a wall");
        return;
    }
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
    part_particles_create_colour(ps_front, cell_cx(_old.gx), cell_cy(_old.gy), pt_trail, global.site.cyan, 2);

    if (!is_undefined(hint_orb) && hint_orb.gx == _nx && hint_orb.gy == _ny)
    {
        hint_orb = undefined;
        hint_timer = hint_length;
        hint_cooldown = 900;
        play_sfx(sfx.hint);
        part_particles_create_colour(ps_front, cell_cx(_nx), cell_cy(_ny), pt_ring, global.site.han, 3);
        part_particles_create_colour(ps_front, cell_cx(_nx), cell_cy(_ny), pt_spark, global.site.han, 20);
    }

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
    letters_eaten++;
    var _px = cell_cx(_gx);
    var _py = cell_cy(_gy);
    var _s = global.site;

    if (word_has_letter(word, _ch))
    {
        letters_right++;
        var _n = word_count_letter(word, _ch);
        grow_pending += _n;
        total_points += points_per_letter * _n;
        for (var _i = 0; _i < string_length(word); _i++)
        {
            if (string_char_at(word, _i + 1) == _ch) reveal_timers[_i] = 40;
        }
        glow = 1;
        play_sfx(sfx.right);
        part_particles_create_colour(ps_front, _px, _py, pt_spark, _s.green, 24);
        part_particles_create_colour(ps_front, _px, _py, pt_ring, _s.green, 2);
        move_interval = max(min_move_interval, move_interval - speedup_per_letter);
        if (word_is_solved(word, guessed))
        {
            win_round();
            return;
        }
    }
    else
    {
        hit = 1;
        shake = 8;
        play_sfx(sfx.wrong);
        part_particles_create_colour(ps_front, _px, _py, pt_spark, _s.magenta, 24);
        if (word_miss_count(word, guessed) >= MAX_MISSES)
        {
            lose_round("Out of power cells");
            return;
        }
    }
    refill_letters();
};

win_round = function()
{
    round_bonus = 50 + (MAX_MISSES - word_miss_count(word, guessed)) * 10;
    total_points += round_bonus;
    words_cleared++;
    punch = 1;
    play_sfx(sfx.clear);
    var _h = snake[0];
    part_particles_create_colour(ps_front, cell_cx(_h.gx), cell_cy(_h.gy), pt_spark, global.site.yellow, 50);
    part_particles_create_colour(ps_front, cell_cx(_h.gx), cell_cy(_h.gy), pt_ring, global.site.yellow, 4);
    save_best();
    set_debris_moving(false);
    state = "won";
};

lose_round = function(_reason)
{
    end_reason = _reason;
    shake = 14;
    hit = 1;
    play_sfx(sfx.crash);
    var _h = snake[0];
    part_particles_create_colour(ps_front, cell_cx(_h.gx), cell_cy(_h.gy), pt_spark, global.site.pink, 40);
    save_best();
    set_debris_moving(false);
    state = "lost";
};

save_best = function()
{
    if (total_points > best_points)
    {
        best_points = total_points;
        new_best = true;
        ini_open("snake_hangman3.ini");
        ini_write_real("best", "points", best_points);
        ini_close();
    }
};

/// Fraction of the word's distinct letters found so far (Artsy's revival).
revival = function()
{
    if (word == "") return 0;
    var _hidden = array_length(word_hidden_letters(word, ""));
    var _left = array_length(word_hidden_letters(word, guessed));
    return (_hidden == 0) ? 0 : 1 - _left / _hidden;
};
