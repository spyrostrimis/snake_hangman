/// Snake Hangman v5, "Jungle Jam": a side-scrolling platformer tribute to the 90s PC platformers.
/// obj_game owns the run, the levels (grid + tilemap + layers), the camera, music and HUD.

randomise();
// The GUI layer runs at the full window size; Draw GUI scales the HUD 2x and draws text sharp.
display_set_gui_size(1280, 720);
window_set_caption("Snake Hangman: Jungle Jam");
// The blank room's own black background layer would hide the sky and tiles.
var _room_bg = layer_get_id("Background");
if (_room_bg != -1) layer_destroy(_room_bg);

// ---------- Fonts: a bitmap font built from a sprite, plus a Windows system font ----------
glyphs   = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!?.:x-/',%()+";
font_hud = font_add_sprite_ext(spr_font_hud, glyphs, true, 1);
font_body = font_add("Comic Sans MS", 15, true, false, 32, 128);

// ---------- Sound ----------
sfx = sfx_init();
music_stream = -1;
music_id = -1;
music_file = "";
sound_on = true;

play_sfx = function(_e) { if (sound_on) audio_play_sound(_e.sound, 1, false); };

/// Streams an Ogg file from the Included Files, if it is there (the album is not in the repo).
play_music = function(_file)
{
    if (_file == music_file && music_id != -1) return;
    stop_music();
    music_file = _file;
    if (!sound_on || _file == "" || !file_exists(_file)) return;
    music_stream = audio_create_stream(_file);
    music_id = audio_play_sound(music_stream, 10, true);
    audio_sound_gain(music_id, 0.55, 0);
};

stop_music = function()
{
    if (music_id != -1) audio_stop_sound(music_id);
    if (music_stream != -1) audio_destroy_stream(music_stream);
    music_id = -1;
    music_stream = -1;
    music_file = "";
};

// ---------- Particles: GameMaker's particle system, drawn in the world ----------
ps = part_system_create();
part_system_depth(ps, -20);
pt_spark = part_type_create();
part_type_shape(pt_spark, pt_shape_star);
part_type_size(pt_spark, 0.1, 0.25, -0.004, 0);
part_type_speed(pt_spark, 1, 4, -0.08, 0);
part_type_direction(pt_spark, 0, 360, 0, 0);
part_type_alpha2(pt_spark, 1, 0);
part_type_blend(pt_spark, true);
part_type_life(pt_spark, 20, 40);
pt_dust = part_type_create();
part_type_shape(pt_dust, pt_shape_cloud);
part_type_size(pt_dust, 0.08, 0.16, 0.004, 0);
part_type_speed(pt_dust, 0.3, 1.2, -0.02, 0);
part_type_direction(pt_dust, 60, 120, 0, 0);
part_type_colour1(pt_dust, make_colour_rgb(230, 220, 200));
part_type_alpha2(pt_dust, 0.8, 0);
part_type_life(pt_dust, 18, 30);
pt_rock = part_type_create();
part_type_shape(pt_rock, pt_shape_square);
part_type_size(pt_rock, 0.06, 0.12, 0, 0);
part_type_speed(pt_rock, 2, 5, 0, 0);
part_type_direction(pt_rock, 40, 140, 0, 0);
part_type_gravity(pt_rock, 0.3, 270);
part_type_orientation(pt_rock, 0, 360, 8, 0, false);
part_type_colour2(pt_rock, make_colour_rgb(200, 196, 220), make_colour_rgb(100, 96, 130));
part_type_life(pt_rock, 30, 50);

burst = function(_x, _y, _col, _n) { part_particles_create_colour(ps, _x, _y, pt_spark, _col, _n); };

// ---------- Run state ----------
state      = "title";   // title | credits | play | paused | clear | gameover | victory
levels     = level_list();
level_index = 0;
words      = game_word_list();
last_word  = "";
popups     = [];        // world-space floating scores { x, y, text, life }
frame      = 0;
level_time = 0;

// ---------- Players ----------
// One or two snakes. Everything that belongs to one snake (score, lives, hearts, misses,
// checkpoint, camera, messages) lives in its struct in pl; the word is shared.
players_n = 1;          // chosen on the title screen
pl = [];                // built by new_game

make_player = function(_pid, _snake)
{
    return
    {
        pid: _pid,
        skin: snakes[_snake],
        score_now: 0,
        lives_left: 3,
        hearts: 5,
        gems: 0,
        misses: 0,
        miss_letters: "",
        checkpoint_x: 0,
        checkpoint_y: 0,
        out: false,         // out of lives: watches the other snake until the next level
        inst: noone,        // its obj_player
        cam_x: 0,
        cam_y: 0,
        messages: [],       // { text, life }
        bonus: 0,           // level-clear tally
        shown: 0,
    };
};

// ---------- Level state ----------
boss = noone;
lvl = undefined;
grid = [];
lvl_w = 1;
lvl_h = 1;
word = "";
guessed = "";           // shared: every letter either snake has picked up
start_x = 0;
start_y = 0;
tilemap = -1;
layers_made = [];
cam_x = 0;              // the single view's camera (title screen, game over...)
cam_y = 0;
cam_snap = false;       // true: cameras jump straight to their snakes (a new level)
title_pan = 0;

// ---------- Views: one full-window view, or two halves (top / bottom) ----------
split_on = false;
split_cam = camera_create_view(0, 0, SPLIT_VIEW_W, SPLIT_VIEW_H);

/// Switches between one view (640 x 360 in the whole window) and two views, one per snake.
set_split = function(_on)
{
    if (_on == split_on) return;
    split_on = _on;
    if (_on)
    {
        camera_set_view_size(view_camera[0], SPLIT_VIEW_W, SPLIT_VIEW_H);
        view_camera[1] = split_cam;
        view_visible[1] = true;
        view_xport[0] = 0; view_yport[0] = 0;   view_wport[0] = 1280; view_hport[0] = 360;
        view_xport[1] = 0; view_yport[1] = 360; view_wport[1] = 1280; view_hport[1] = 360;
    }
    else
    {
        camera_set_view_size(view_camera[0], 640, 360);
        view_visible[1] = false;
        view_xport[0] = 0; view_yport[0] = 0; view_wport[0] = 1280; view_hport[0] = 720;
    }
};

/// Moves the parallax background layers for a camera at (_cx, _cy). Called for each view.
place_parallax = function(_cx, _cy)
{
    if (!variable_instance_exists(id, "bg_layers")) return;
    layer_x(bg_layers.Mountains, _cx * 0.82);
    layer_y(bg_layers.Mountains, _cy * 0.85 + 70);
    layer_x(bg_layers.Clouds, _cx * 0.9 - frame * 0.15);
    layer_y(bg_layers.Clouds, _cy * 0.92 + 8);
    layer_x(bg_layers.Hills, _cx * 0.6);
    layer_y(bg_layers.Hills, _cy * 0.75 + 190);
};

// ---------- Playable snakes (chosen on the title screen with Left / Right) ----------
// Green glides with a spinning tail; Red can jump a second time in the air instead.
snakes =
[
    { name: "GREEN SNAKE", power: "Hold jump in the air to glide.  C: rocket boost upward", double_jump: false, boost: "up",
      head: spr_snake_head, body: spr_snake_body, tail: spr_snake_tail, ball: spr_snake_ball,
      colour: make_colour_rgb(120, 230, 90) },
    { name: "RED SNAKE", power: "Press jump again in the air to double jump.  C: dash boost ahead", double_jump: true, boost: "dash",
      head: sprite_swap_red_green(spr_snake_head), body: sprite_swap_red_green(spr_snake_body),
      tail: sprite_swap_red_green(spr_snake_tail), ball: sprite_swap_red_green(spr_snake_ball),
      colour: make_colour_rgb(255, 110, 90) },
];
character = 0;         // player 1's snake; with two players, player 2 gets the other one

/// Shows a message in the middle of a snake's screen; without _p, on every snake's screen.
say = function(_text, _frames = 150, _p = undefined)
{
    for (var _k = 0; _k < array_length(pl); _k++)
    {
        if (is_undefined(_p) || pl[_k] == _p) array_push(pl[_k].messages, { text: _text, life: _frames });
    }
};

clear_messages = function()
{
    for (var _k = 0; _k < array_length(pl); _k++) pl[_k].messages = [];
};

add_popup = function(_x, _y, _text)
{
    array_push(popups, { x: _x, y: _y, text: _text, life: 50 });
};

/// Adds _n points to snake _p (a struct from pl), with a floating score at (_x, _y).
add_score = function(_n, _x = undefined, _y = undefined, _p = undefined)
{
    if (!is_undefined(_p)) _p.score_now += _n;
    if (!is_undefined(_x)) add_popup(_x, _y, string(_n));
};

/// The first snake still playing, or undefined.
any_player_in = function()
{
    for (var _k = 0; _k < array_length(pl); _k++) if (!pl[_k].out) return pl[_k];
    return undefined;
};

/// Removes everything a level created: instances, layers, tilemap, particles.
clear_level = function()
{
    with (obj_player) instance_destroy();
    with (obj_enemy) instance_destroy();
    with (obj_hazard) instance_destroy();
    with (obj_pickup) instance_destroy();
    boss = noone;
    with (obj_spring) instance_destroy();
    with (obj_door) instance_destroy();
    with (obj_flag) instance_destroy();
    with (obj_sky) instance_destroy();
    for (var _i = 0; _i < array_length(layers_made); _i++) layer_destroy(layers_made[_i]);
    layers_made = [];
    part_particles_clear(ps);
    popups = [];
};

/// The tile to show for each grid cell: grass on top of ground, rounded ends, dirt below.
auto_tile = function(_tx, _ty)
{
    var _t = grid[_tx][_ty];
    switch (_t)
    {
        case T_ONEWAY: return 7;
        case T_CRACK:  return 8;
        case T_SPIKES: return 9;
        case T_SOLID:
            var _open_above = !is_blocking(grid_type(_tx, _ty - 1));
            if (_open_above)
            {
                var _l = !is_blocking(grid_type(_tx - 1, _ty)) || _tx == 0;
                var _r = !is_blocking(grid_type(_tx + 1, _ty)) || _tx == lvl_w - 1;
                if (_tx == 0) _l = false;
                if (_tx == lvl_w - 1) _r = false;
                if (_l && _r) return 10;
                if (_l) return 4;
                if (_r) return 5;
                return 1;
            }
            if (_ty < lvl_h - 1 && !is_blocking(grid_type(_tx, _ty + 1))) return 6;
            return ((_tx * 7 + _ty * 3) mod 2 == 0) ? 2 : 3;
    }
    return 0;
};

/// Builds level _i: grid, tilemap, decorations, parallax layers and every creature and item.
/// With _with_player false (title screen) the level is only scenery.
load_level = function(_i, _with_player)
{
    clear_level();
    lvl = levels[_i]();
    grid = lvl.grid;
    lvl_w = lvl.w;
    lvl_h = lvl.h;

    // Sky (an object drawing a gradient) and three parallax background layers.
    var _sky_layer = layer_create(1000, "Sky");
    array_push(layers_made, _sky_layer);
    instance_create_layer(0, 0, _sky_layer, obj_sky);
    // The sky draws first in every view: place the parallax layers for that view's camera.
    layer_script_begin(_sky_layer, parallax_for_view);
    var _defs = [["Mountains", 900, spr_bg_mountains], ["Clouds", 950, spr_bg_clouds], ["Hills", 800, spr_bg_hills]];
    bg_layers = {};
    for (var _k = 0; _k < 3; _k++)
    {
        var _lay = layer_create(_defs[_k][1], _defs[_k][0]);
        var _bg = layer_background_create(_lay, _defs[_k][2]);
        layer_background_htiled(_bg, true);
        bg_layers[$ _defs[_k][0]] = _lay;
        array_push(layers_made, _lay);
    }

    // The level's tiles, in a real GameMaker tilemap.
    var _tile_layer = layer_create(100, "Tiles");
    array_push(layers_made, _tile_layer);
    tilemap = layer_tilemap_create(_tile_layer, 0, 0, ts_jungle, lvl_w, lvl_h);
    for (var _x = 0; _x < lvl_w; _x++) for (var _y = 0; _y < lvl_h; _y++) tilemap_set(tilemap, auto_tile(_x, _y), _x, _y);

    // Plants on the grass and vines under the ledges, as sprites on an asset layer.
    var _deco = layer_create(95, "Deco");
    array_push(layers_made, _deco);
    random_set_seed(1000 + _i);
    for (var _x = 1; _x < lvl_w - 1; _x++)
    {
        for (var _y = 1; _y < lvl_h; _y++)
        {
            var _here = grid[_x][_y];
            if (_here == T_SOLID && grid[_x][_y - 1] == T_EMPTY)
            {
                var _roll = irandom(9);
                if (_roll == 0) layer_sprite_create(_deco, _x * TILE + 16, _y * TILE + 4, spr_flower);
                else if (_roll == 1) layer_sprite_create(_deco, _x * TILE + 16, _y * TILE + 4, spr_mushroom);
                else if (_roll == 2 && grid[_x + 1][_y] == T_SOLID && grid[_x + 1][_y - 1] == T_EMPTY) layer_sprite_create(_deco, _x * TILE + 32, _y * TILE + 6, spr_bush);
            }
            if (_here == T_SOLID && _y < lvl_h - 1 && grid[_x][_y + 1] == T_EMPTY && irandom(3) == 0) layer_sprite_create(_deco, _x * TILE + 16, (_y + 1) * TILE - 4, spr_vine);
        }
    }
    randomise();

    // A new word, and every spawn from the level plan.
    var _word = words[irandom(array_length(words) - 1)];
    while (_word == last_word && array_length(words) > 1) _word = words[irandom(array_length(words) - 1)];
    word = _word;
    last_word = _word;
    guessed = "";
    level_time = 0;

    var _letter_spots = [];
    for (var _k = 0; _k < array_length(lvl.spawns); _k++)
    {
        var _s = lvl.spawns[_k];
        var _px = _s.tx * TILE + 16;
        var _py = _s.ty * TILE + 16;
        switch (_s.kind)
        {
            case "start":  start_x = _px; start_y = _s.ty * TILE + 32 - 12; break;
            case "letter": array_push(_letter_spots, instance_create_layer(_px, _py, "Instances", obj_letter)); break;
            case "gem":    instance_create_layer(_px, _py, "Instances", obj_gem); break;
            case "egg":    instance_create_layer(_px, _py, "Instances", obj_egg); break;
            case "boss_mouse":
            case "boss_hen":
                boss = instance_create_layer(_px, _s.ty * TILE + 32 - 26, "Instances", (_s.kind == "boss_mouse") ? obj_boss_mouse : obj_boss_hen);
                boss.arena_x1 = lvl.arena[0] * TILE + 32;
                boss.arena_x2 = lvl.arena[1] * TILE;
                break;
            case "bug":    instance_create_layer(_px, _s.ty * TILE + 32 - 12, "Instances", obj_bug); break;
            case "bee":    instance_create_layer(_px, _py, "Instances", obj_bee); break;
            case "spring": instance_create_layer(_px, _s.ty * TILE + 32, "Instances", obj_spring); break;
            case "flag":   instance_create_layer(_px, _s.ty * TILE + 32, "Instances", obj_flag); break;
            case "door":   instance_create_layer(_px, _s.ty * TILE + 32, "Instances", obj_door); break;
        }
    }

    // Letters: every letter of the word once, the other spots get different wrong letters.
    // A boss keeps one letter of the word for itself; beating it is the only way to get it.
    var _need = word_hidden_letters(word, "");
    if (instance_exists(boss) && array_length(_need) > 1)
    {
        var _b = irandom(array_length(_need) - 1);
        boss.ch = _need[_b];
        array_delete(_need, _b, 1);
    }
    var _pool = [];
    for (var _c = 0; _c < 26; _c++)
    {
        var _ch = chr(ord("A") + _c);
        if (!word_has_letter(word, _ch)) array_push(_pool, _ch);
    }
    for (var _k = array_length(_letter_spots) - 1; _k > 0; _k--)
    {
        var _j = irandom(_k);
        var _tmp = _letter_spots[_k];
        _letter_spots[_k] = _letter_spots[_j];
        _letter_spots[_j] = _tmp;
    }
    for (var _k = 0; _k < array_length(_letter_spots); _k++)
    {
        if (_k < array_length(_need)) _letter_spots[_k].ch = _need[_k];
        else
        {
            var _p = irandom(array_length(_pool) - 1);
            _letter_spots[_k].ch = _pool[_p];
            array_delete(_pool, _p, 1);
        }
    }

    if (_with_player)
    {
        // Each snake starts a level with full hearts and no misses; player 2 a step behind.
        for (var _k = 0; _k < array_length(pl); _k++)
        {
            var _p = pl[_k];
            _p.hearts = 5;
            _p.misses = 0;
            _p.miss_letters = "";
            _p.checkpoint_x = start_x - _k * 26;
            _p.checkpoint_y = start_y;
            _p.inst = _p.out ? noone : instance_create_layer(_p.checkpoint_x, start_y, "Instances", obj_player, { pid: _k });
        }
    }
    cam_x = max(0, start_x - 200);
    cam_y = max(0, lvl_h * TILE - 360);
    cam_snap = true;
    play_music(_with_player ? lvl.music : "music_02.ogg");
};

new_game = function(_first_level = 0)
{
    // Player 1 has the snake chosen on the title screen; player 2 the other one.
    pl = [];
    for (var _k = 0; _k < players_n; _k++) array_push(pl, make_player(_k, (_k == 0) ? character : 1 - character));
    level_index = _first_level;
    start_level();
};

/// Level skip: jumps straight to the next level (or the victory screen after the last).
skip_level = function()
{
    audio_resume_all();
    level_index++;
    if (level_index >= array_length(levels))
    {
        state = "victory";
        play_music("music_02.ogg");
    }
    else start_level();
};

start_level = function()
{
    // A snake that ran out of lives comes back for the new level with one life.
    for (var _k = 0; _k < array_length(pl); _k++)
    {
        if (pl[_k].out) { pl[_k].out = false; pl[_k].lives_left = 1; }
    }
    load_level(level_index, true);
    state = "play";
    clear_messages();
    say(lvl.name, 180);
    say("FIND THE LETTERS. OPEN THE DOOR.", 180);
};

/// The hangman rule: a right letter opens part of the word, a wrong one is a miss.
/// The hangman rule: a right letter opens part of the word for both snakes; a wrong one
/// is a miss for the snake _by (an obj_player) that picked it up.
on_letter = function(_ch, _x, _y, _by)
{
    var _p = stats_of(_by);
    guessed += _ch;
    if (word_has_letter(word, _ch))
    {
        add_score(500 * word_count_letter(word, _ch), _x, _y - 20, _p);
        burst(_x, _y, make_colour_rgb(80, 255, 120), 18);
        play_sfx(sfx.right);
        if (instance_exists(_by)) with (_by) body_len = min(14, body_len + 1);
        if (word_is_solved(word, guessed))
        {
            with (obj_door) open = true;
            play_sfx(sfx.door);
            say("THE WORD IS " + word + "! THE DOOR IS OPEN!", 200);
        }
        else say("YES! " + _ch + " IS IN THE WORD", 100);
    }
    else
    {
        _p.misses++;
        _p.miss_letters += _ch;
        burst(_x, _y, make_colour_rgb(255, 60, 90), 18);
        play_sfx(sfx.wrong);
        if (_p.misses >= MAX_MISSES)
        {
            say("SIX MISSES! THE WORD GOT AWAY", 160, _p);
            player_died(_by);
        }
        else say("NO " + _ch + " IN THIS WORD", 100, _p);
    }
};

/// Snake _inst loses a heart; at zero hearts, a life.
hurt_player = function(_inst)
{
    var _p = _inst.stats;
    _p.hearts--;
    play_sfx(sfx.hurt);
    if (_p.hearts <= 0) player_died(_inst);
};

/// Snake _inst loses a life and goes back to its own checkpoint. Out of lives, it is out
/// until the next level; when no snake is left, the game is over.
player_died = function(_inst)
{
    if (!instance_exists(_inst)) return;
    var _p = _inst.stats;
    play_sfx(sfx.die);
    _p.lives_left--;
    _p.misses = 0;
    _p.miss_letters = "";
    if (_p.lives_left <= 0)
    {
        _p.out = true;
        _p.inst = noone;
        instance_destroy(_inst);
        if (is_undefined(any_player_in()))
        {
            state = "gameover";
            stop_music();
            return;
        }
        say(_p.skin.name + " IS OUT! BACK NEXT LEVEL", 180);
    }
    else
    {
        _p.hearts = 5;
        with (_inst)
        {
            x = _p.checkpoint_x;
            y = _p.checkpoint_y;
            vx = 0;
            vy = 0;
            invuln = 120;
            ball = false;
            boost_t = 0;
            reset_body();
        }
        say("OUCH! " + string(_p.lives_left) + " LIVES LEFT", 120, _p);
    }
    // A boss goes back to sleep (keeping its damage) until a snake returns.
    if (instance_exists(boss) && boss.active)
    {
        var _b = boss;
        var _near = false;
        with (obj_player) if (id != _inst && abs(x - _b.x) < 300 && abs(y - _b.y) < 200) _near = true;
        if (!_near)
        {
            boss.active = false;
            with (obj_hazard) instance_destroy();
            play_music(lvl.music);
        }
    }
};

/// A boss has noticed a snake: its own music and a warning.
boss_start = function(_b)
{
    play_music(_b.music);
    clear_messages();
    say("WATCH OUT! IT'S " + _b.boss_name + "!", 150);
    say("IT HOLDS A LETTER OF THE WORD", 120);
};

boss_defeated = function(_name)
{
    play_sfx(sfx.boss_win);
    play_music(lvl.music);
    clear_messages();
    say(_name + " IS BEATEN! GRAB THE LETTER!", 180);
};

/// A snake went through the open door: the level is done for both. Each snake still in
/// gets its own bonus: letters, time, and 500 for every miss it saved.
level_complete = function()
{
    state = "clear";
    var _base = 1000 * string_length(word) + max(0, 300 - floor(level_time / 60)) * 10;
    for (var _k = 0; _k < array_length(pl); _k++)
    {
        var _p = pl[_k];
        _p.bonus = _p.out ? 0 : _base + (MAX_MISSES - _p.misses) * 500;
        _p.shown = 0;
    }
    play_music("music_05.ogg");
    with (obj_player) { vx = 0; vy = 0; }
};

// Start on the title screen, over level 1's scenery.
load_level(0, false);
