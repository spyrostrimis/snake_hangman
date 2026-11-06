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
