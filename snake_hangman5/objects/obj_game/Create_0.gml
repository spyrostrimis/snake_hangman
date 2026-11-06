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
score_now  = 0;
lives      = 3;
hearts     = 5;
gems       = 0;
words      = game_word_list();
last_word  = "";
messages   = [];        // { text, life }
popups     = [];        // world-space floating scores { x, y, text, life }
frame      = 0;
tally      = { bonus: 0, shown: 0, gems: 0, time: 0 };
level_time = 0;

// ---------- Level state ----------
lvl = undefined;
grid = [];
lvl_w = 1;
lvl_h = 1;
word = "";
guessed = "";
misses = 0;
miss_letters = "";
checkpoint_x = 0;
checkpoint_y = 0;
start_x = 0;
start_y = 0;
tilemap = -1;
layers_made = [];
cam_x = 0;
cam_y = 0;
title_pan = 0;

say = function(_text, _frames = 150)
{
    array_push(messages, { text: _text, life: _frames });
};

add_popup = function(_x, _y, _text)
{
    array_push(popups, { x: _x, y: _y, text: _text, life: 50 });
};

add_score = function(_n, _x = undefined, _y = undefined)
{
    score_now += _n;
    if (!is_undefined(_x)) add_popup(_x, _y, string(_n));
};

/// Removes everything a level created: instances, layers, tilemap, particles.
clear_level = function()
{
    with (obj_player) instance_destroy();
    with (obj_enemy) instance_destroy();
    with (obj_pickup) instance_destroy();
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
    misses = 0;
    miss_letters = "";
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
            case "carrot": instance_create_layer(_px, _py, "Instances", obj_carrot); break;
            case "bug":    instance_create_layer(_px, _s.ty * TILE + 32 - 12, "Instances", obj_bug); break;
            case "bee":    instance_create_layer(_px, _py, "Instances", obj_bee); break;
            case "spring": instance_create_layer(_px, _s.ty * TILE + 32, "Instances", obj_spring); break;
            case "flag":   instance_create_layer(_px, _s.ty * TILE + 32, "Instances", obj_flag); break;
            case "door":   instance_create_layer(_px, _s.ty * TILE + 32, "Instances", obj_door); break;
        }
    }

    // Letters: every letter of the word once, the other spots get different wrong letters.
    var _need = word_hidden_letters(word, "");
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

    checkpoint_x = start_x;
    checkpoint_y = start_y;
    if (_with_player)
    {
        instance_create_layer(start_x, start_y, "Instances", obj_player);
        hearts = 5;
    }
    cam_x = max(0, start_x - 200);
    cam_y = max(0, lvl_h * TILE - 360);
    play_music(_with_player ? lvl.music : "music_02.ogg");
};

new_game = function()
{
    score_now = 0;
    lives = 3;
    gems = 0;
    level_index = 0;
    start_level();
};

start_level = function()
{
    load_level(level_index, true);
    state = "play";
    messages = [];
    say(lvl.name, 180);
    say("FIND THE LETTERS. OPEN THE DOOR.", 180);
};

/// The hangman rule: a right letter opens part of the word, a wrong one is a miss.
on_letter = function(_ch, _x, _y)
{
    guessed += _ch;
    if (word_has_letter(word, _ch))
    {
        add_score(500 * word_count_letter(word, _ch), _x, _y - 20);
        burst(_x, _y, make_colour_rgb(80, 255, 120), 18);
        play_sfx(sfx.right);
        with (obj_player) body_len = min(14, body_len + 1);
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
        misses++;
        miss_letters += _ch;
        burst(_x, _y, make_colour_rgb(255, 60, 90), 18);
        play_sfx(sfx.wrong);
        if (misses >= MAX_MISSES)
        {
            say("SIX MISSES! THE WORD GOT AWAY", 160);
            player_died();
        }
        else say("NO " + _ch + " IN THIS WORD", 100);
    }
};

/// Loses a heart; at zero hearts, a life.
hurt_player = function()
{
    hearts--;
    play_sfx(sfx.hurt);
    if (hearts <= 0) player_died();
};

player_died = function()
{
    play_sfx(sfx.die);
    lives--;
    misses = 0;
    if (lives <= 0)
    {
        with (obj_player) instance_destroy();
        state = "gameover";
        stop_music();
        return;
    }
    hearts = 5;
    with (obj_player)
    {
        x = other.checkpoint_x;
        y = other.checkpoint_y;
        vx = 0;
        vy = 0;
        invuln = 120;
        ball = false;
        reset_body();
    }
    say("OUCH! " + string(lives) + " LIVES LEFT", 120);
};

level_complete = function()
{
    state = "clear";
    tally = { bonus: 1000 * string_length(word) + max(0, 300 - floor(level_time / 60)) * 10 + (MAX_MISSES - misses) * 500, shown: 0, misses: misses };
    play_music("music_05.ogg");
    with (obj_player) { vx = 0; vy = 0; }
};

// Start on the title screen, over level 1's scenery.
load_level(0, false);
