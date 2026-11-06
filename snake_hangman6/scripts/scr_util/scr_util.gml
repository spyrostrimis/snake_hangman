/// Tile collision shared by the snake and the enemies. The level is a grid of tile types
/// (obj_game.grid); the GameMaker tilemap only draws it.

#macro TILE 32
#macro T_EMPTY 0
#macro T_SOLID 1
#macro T_ONEWAY 2
#macro T_SPIKES 3
#macro T_CRACK 4

/// Tile type at grid cell (_tx, _ty). The level's sides are walls; above and below are open.
function grid_type(_tx, _ty)
{
    var _g = obj_game;
    if (_tx < 0 || _tx >= _g.lvl_w) return T_SOLID;
    if (_ty < 0 || _ty >= _g.lvl_h) return T_EMPTY;
    return _g.grid[_tx][_ty];
}

function tile_at(_px, _py)
{
    return grid_type(floor(_px / TILE), floor(_py / TILE));
}

function is_blocking(_t)
{
    return _t == T_SOLID || _t == T_CRACK;
}

/// True if any tile in the column at _px, between _y1 and _y2, blocks.
function col_blocked(_px, _y1, _y2)
{
    var _tx = floor(_px / TILE);
    for (var _ty = floor(_y1 / TILE); _ty <= floor(_y2 / TILE); _ty++) if (is_blocking(grid_type(_tx, _ty))) return true;
    return false;
}

/// True if any tile in the row at _py, between _x1 and _x2, blocks.
function row_blocked(_py, _x1, _x2)
{
    var _ty = floor(_py / TILE);
    for (var _tx = floor(_x1 / TILE); _tx <= floor(_x2 / TILE); _tx++) if (is_blocking(grid_type(_tx, _ty))) return true;
    return false;
}

function row_oneway(_py, _x1, _x2)
{
    var _ty = floor(_py / TILE);
    for (var _tx = floor(_x1 / TILE); _tx <= floor(_x2 / TILE); _tx++) if (grid_type(_tx, _ty) == T_ONEWAY) return true;
    return false;
}

/// Moves the calling instance by (vx, vy) against the tiles, one axis at a time.
/// The instance needs x, y (centre), hw, hh (half size), vx, vy and drop_through.
/// Sets on_ground, hit_wall (-1, 0 or 1) and hit_ceiling.
function entity_move()
{
    on_ground = false;
    hit_wall = 0;
    hit_ceiling = false;

    var _nx = x + vx;
    if (vx > 0 && col_blocked(_nx + hw, y - hh + 1, y + hh - 1))
    {
        _nx = floor((_nx + hw) / TILE) * TILE - hw - 0.01;
        hit_wall = 1;
        vx = 0;
    }
    else if (vx < 0 && col_blocked(_nx - hw, y - hh + 1, y + hh - 1))
    {
        _nx = (floor((_nx - hw) / TILE) + 1) * TILE + hw + 0.01;
        hit_wall = -1;
        vx = 0;
    }
    x = _nx;

    var _ny = y + vy;
    if (vy >= 0)
    {
        var _foot_old = y + hh;
        var _foot = _ny + hh;
        var _row_top = floor(_foot / TILE) * TILE;
        var _land = row_blocked(_foot, x - hw + 1, x + hw - 1);
        // One-way logs: only land on them from above, unless dropping through.
        if (!_land && !drop_through && _foot_old <= _row_top + 0.5) _land = row_oneway(_foot, x - hw + 1, x + hw - 1);
        if (_land)
        {
            _ny = _row_top - hh;
            vy = 0;
            on_ground = true;
        }
    }
    else if (row_blocked(_ny - hh, x - hw + 1, x + hw - 1))
    {
        _ny = (floor((_ny - hh) / TILE) + 1) * TILE + hh + 0.01;
        vy = 0;
        hit_ceiling = true;
    }
    y = _ny;
}

/// True if the calling instance's box overlaps a spike tile.
function touching_spikes()
{
    return tile_at(x - hw + 2, y + hh - 2) == T_SPIKES || tile_at(x + hw - 2, y + hh - 2) == T_SPIKES || tile_at(x, y + hh - 6) == T_SPIKES;
}

/// Moves _value towards _target by at most _step.
function approach(_value, _target, _step)
{
    return (_value < _target) ? min(_value + _step, _target) : max(_value - _step, _target);
}

/// Shortest distance from point (_px, _py) to the segment (_x1, _y1)-(_x2, _y2).
function point_segment_distance(_px, _py, _x1, _y1, _x2, _y2)
{
    var _dx = _x2 - _x1;
    var _dy = _y2 - _y1;
    var _len2 = _dx * _dx + _dy * _dy;
    var _t = (_len2 == 0) ? 0 : clamp(((_px - _x1) * _dx + (_py - _y1) * _dy) / _len2, 0, 1);
    return point_distance(_px, _py, _x1 + _t * _dx, _y1 + _t * _dy);
}

/// Cartoon text with the HUD bitmap font (font_add_sprite_ext), scaled.
function hud_text(_x, _y, _text, _scale = 0.5, _halign = fa_left, _col = c_white, _alpha = 1)
{
    draw_set_font(obj_game.font_hud);
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    draw_text_transformed_colour(_x, _y, string_upper(_text), _scale, _scale, 0, _col, _col, _col, _col, _alpha);
    draw_set_halign(fa_left);
}

/// Plain readable text (Comic Sans MS from Windows) with a dark outline. Coordinates are in
/// the 640 x 360 HUD space; the text itself is drawn at full window resolution so it stays sharp.
function body_text(_x, _y, _text, _col = c_white, _halign = fa_left)
{
    var _m = matrix_get(matrix_world);
    matrix_set(matrix_world, matrix_build_identity());
    _x *= 2;
    _y *= 2;
    draw_set_font(obj_game.font_body);
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    draw_set_colour(make_colour_rgb(16, 26, 64));
    for (var _dx = -2; _dx <= 2; _dx += 2) for (var _dy = -2; _dy <= 2; _dy += 2) if (_dx != 0 || _dy != 0) draw_text(_x + _dx, _y + _dy, _text);
    draw_set_colour(_col);
    draw_text(_x, _y, _text);
    draw_set_halign(fa_left);
    matrix_set(matrix_world, _m);
}

/// Makes a copy of sprite _spr with its red and green colour channels swapped (a green snake
/// becomes a red one; whites, blacks and blues stay as they are). Every frame and the origin
/// are kept. Used to build the red snake's sprites at start-up.
function sprite_swap_red_green(_spr)
{
    var _w = sprite_get_width(_spr);
    var _h = sprite_get_height(_spr);
    var _xo = sprite_get_xoffset(_spr);
    var _yo = sprite_get_yoffset(_spr);
    var _surf = surface_create(_w, _h);
    var _buf = buffer_create(_w * _h * 4, buffer_fixed, 1);

    // Surface bytes are RGBA on some platforms and BGRA on others: find where red lives.
    surface_set_target(_surf);
    draw_clear_alpha(c_red, 1);
    surface_reset_target();
    buffer_get_surface(_buf, _surf, 0);
    var _ri = (buffer_peek(_buf, 0, buffer_u8) > 127) ? 0 : 2;

    var _new = -1;
    for (var _f = 0; _f < sprite_get_number(_spr); _f++)
    {
        // Copy the frame exactly, alpha included.
        surface_set_target(_surf);
        draw_clear_alpha(c_black, 0);
        gpu_set_blendmode_ext(bm_one, bm_zero);
        draw_sprite(_spr, _f, _xo, _yo);
        gpu_set_blendmode(bm_normal);
        surface_reset_target();

        buffer_get_surface(_buf, _surf, 0);
        for (var _i = 0; _i < _w * _h * 4; _i += 4)
        {
            var _r = buffer_peek(_buf, _i + _ri, buffer_u8);
            buffer_poke(_buf, _i + _ri, buffer_u8, buffer_peek(_buf, _i + 1, buffer_u8));
            buffer_poke(_buf, _i + 1, buffer_u8, _r);
        }
        buffer_set_surface(_buf, _surf, 0);

        if (_f == 0) _new = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, _xo, _yo);
        else sprite_add_from_surface(_new, _surf, 0, 0, _w, _h, false, false);
    }
    buffer_delete(_buf);
    surface_free(_surf);
    return _new;
}

// ---------- Two players: controls, gamepads and split screen ----------

// Each half of the split screen shows this much of the level (a little more than half of
// the 640 x 360 single view, so the shorter view still shows a good jump's height).
#macro SPLIT_VIEW_W 800
#macro SPLIT_VIEW_H 225

/// The gamepads plugged in now (GameMaker slots 0-11), in slot order.
function gamepads_connected()
{
    var _pads = [];
    for (var _i = 0; _i < gamepad_get_device_count(); _i++) if (gamepad_is_connected(_i)) array_push(_pads, _i);
    return _pads;
}

/// The gamepad slot player _pid uses, or -1. Alone, any gamepad plays. With two players,
/// one gamepad goes to player 2 (a friend on Parsec shows up as a gamepad); two give one each.
function player_pad(_pid, _players)
{
    var _pads = gamepads_connected();
    var _n = array_length(_pads);
    if (_n == 0) return -1;
    if (_players == 1) return _pads[0];
    if (_pid == 1) return _pads[_n - 1];
    return (_n >= 2) ? _pads[0] : -1;
}

/// Player _pid's controls this step, as a struct. Keys (two players share one keyboard):
///   one player : arrows / WASD, Z / Space / Up / W jump, X / J tongue, Shift roll, C boost
///   player 1   : A D move, W jump, S down, F tongue, G roll (hold), H boost
///   player 2   : arrows move, Up jump, Down down, J tongue, K roll (hold), L boost
///   gamepad    : stick / D-pad, A jump, X tongue, RB / LB / Y roll (hold), B boost
function read_controls(_pid, _players)
{
    var _c = { left: false, right: false, down: false, jump_pressed: false, jump_held: false, tongue: false, roll_held: false, boost: false };
    if (_players == 1)
    {
        _c.left  = keyboard_check(vk_left)  || keyboard_check(ord("A"));
        _c.right = keyboard_check(vk_right) || keyboard_check(ord("D"));
        _c.down  = keyboard_check(vk_down)  || keyboard_check(ord("S"));
        _c.jump_pressed = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"));
        _c.jump_held    = keyboard_check(ord("Z")) || keyboard_check(vk_space) || keyboard_check(vk_up) || keyboard_check(ord("W"));
        _c.tongue    = keyboard_check_pressed(ord("X")) || keyboard_check_pressed(ord("J"));
        _c.roll_held = keyboard_check(vk_shift);
        _c.boost     = keyboard_check_pressed(ord("C"));
    }
    else if (_pid == 0)
    {
        _c.left  = keyboard_check(ord("A"));
        _c.right = keyboard_check(ord("D"));
        _c.down  = keyboard_check(ord("S"));
        _c.jump_pressed = keyboard_check_pressed(ord("W"));
        _c.jump_held    = keyboard_check(ord("W"));
        _c.tongue    = keyboard_check_pressed(ord("F"));
        _c.roll_held = keyboard_check(ord("G"));
        _c.boost     = keyboard_check_pressed(ord("H"));
    }
    else
    {
        _c.left  = keyboard_check(vk_left);
        _c.right = keyboard_check(vk_right);
        _c.down  = keyboard_check(vk_down);
        _c.jump_pressed = keyboard_check_pressed(vk_up);
        _c.jump_held    = keyboard_check(vk_up);
        _c.tongue    = keyboard_check_pressed(ord("J"));
        _c.roll_held = keyboard_check(ord("K"));
        _c.boost     = keyboard_check_pressed(ord("L"));
    }

    var _pad = player_pad(_pid, _players);
    if (_pad >= 0)
    {
        var _ax = gamepad_axis_value(_pad, gp_axislh);
        var _ay = gamepad_axis_value(_pad, gp_axislv);
        _c.left  |= gamepad_button_check(_pad, gp_padl) || _ax < -0.4;
        _c.right |= gamepad_button_check(_pad, gp_padr) || _ax > 0.4;
        _c.down  |= gamepad_button_check(_pad, gp_padd) || _ay > 0.5;
        _c.jump_pressed |= gamepad_button_check_pressed(_pad, gp_face1);
        _c.jump_held    |= gamepad_button_check(_pad, gp_face1);
        _c.tongue    |= gamepad_button_check_pressed(_pad, gp_face3);
        _c.roll_held |= gamepad_button_check(_pad, gp_shoulderr) || gamepad_button_check(_pad, gp_shoulderl) || gamepad_button_check(_pad, gp_face4);
        _c.boost     |= gamepad_button_check_pressed(_pad, gp_face2);
    }
    return _c;
}

/// True if any gamepad pressed button _btn this step.
function any_pad_pressed(_btn)
{
    var _pads = gamepads_connected();
    for (var _i = 0; _i < array_length(_pads); _i++) if (gamepad_button_check_pressed(_pads[_i], _btn)) return true;
    return false;
}

/// "OK" on the menus: Enter or Space, or A / Start on any gamepad.
function menu_confirm()
{
    return keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || any_pad_pressed(gp_face1) || any_pad_pressed(gp_start);
}

/// The run state (score, lives, hearts...) of the snake instance _inst. Without one
/// (a creature hit by nothing in particular) it falls back to player 1, or undefined.
function stats_of(_inst)
{
    if (_inst != noone && instance_exists(_inst)) return _inst.stats;
    var _g = obj_game;
    return (array_length(_g.pl) > 0) ? _g.pl[0] : undefined;
}

/// Layer begin script of the sky layer: runs before each view draws, and moves the
/// parallax background layers for that view's camera (each half has its own).
function parallax_for_view()
{
    var _cam = view_camera[view_current];
    obj_game.place_parallax(camera_get_view_x(_cam), camera_get_view_y(_cam));
}

/// A small arrow on the title screen pointing left (_dir -1) or right (1), centred on (_x, _y).
function title_arrow(_x, _y, _dir, _col)
{
    draw_set_colour(make_colour_rgb(16, 26, 64));
    draw_triangle(_x - _dir * 8, _y - 10, _x - _dir * 8, _y + 10, _x + _dir * 10, _y, false);
    draw_set_colour(_col);
    draw_triangle(_x - _dir * 6, _y - 7, _x - _dir * 6, _y + 7, _x + _dir * 7, _y, false);
    draw_set_colour(c_white);
}
