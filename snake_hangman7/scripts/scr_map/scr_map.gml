/// The map: terrain, lumen fields, crags, path grids, tilemaps and the shroud.

function in_map(_cx, _cy)
{
    return _cx >= 0 && _cy >= 0 && _cx < global.mw && _cy < global.mh;
}

function cell_of(_px)
{
    return floor(_px / CELL);
}

function is_rock(_cx, _cy)
{
    _cx = clamp(_cx, 0, global.mw - 1);
    _cy = clamp(_cy, 0, global.mh - 1);
    return global.terr[# _cx, _cy] != T_SAND;
}

/// A rough round patch of terrain.
function map_blob(_cx, _cy, _r, _t)
{
    var _p1 = random(6.28), _p2 = random(6.28);
    var _reach = ceil(_r * 1.5) + 1;
    for (var _i = _cx - _reach; _i <= _cx + _reach; _i++)
    {
        for (var _j = _cy - _reach; _j <= _cy + _reach; _j++)
        {
            if (!in_map(_i, _j)) continue;
            var _a = degtorad(point_direction(_cx, _cy, _i, _j));
            var _rr = _r * (1 + 0.22 * sin(_a * 3 + _p1) + 0.12 * sin(_a * 5 + _p2));
            if (point_distance(_cx, _cy, _i, _j) <= _rr && global.terr[# _i, _j] == T_SAND) global.terr[# _i, _j] = _t;
        }
    }
}

function lumen_field(_cx, _cy, _r)
{
    var _p1 = random(6.28);
    var _reach = ceil(_r * 1.4) + 1;
    for (var _i = _cx - _reach; _i <= _cx + _reach; _i++)
    {
        for (var _j = _cy - _reach; _j <= _cy + _reach; _j++)
        {
            if (!in_map(_i, _j) || global.terr[# _i, _j] != T_SAND) continue;
            var _a = degtorad(point_direction(_cx, _cy, _i, _j));
            var _rr = _r * (1 + 0.3 * sin(_a * 3 + _p1));
            var _d = point_distance(_cx, _cy, _i, _j);
            if (_d <= _rr) global.lumen[# _i, _j] = max(global.lumen[# _i, _j], clamp(round(LUMEN_MAX * (1 - _d / (_rr + 1)) + 70 + random(40)), 40, LUMEN_MAX));
        }
    }
    if (in_map(_cx, _cy) && global.terr[# _cx, _cy] == T_SAND)
    {
        global.isvent[# _cx, _cy] = 1;
        global.lumen[# _cx, _cy] = 0;
        array_push(global.vents, [_cx, _cy]);
    }
}

function far_from(_cx, _cy, _points, _dist)
{
    for (var _k = 0; _k < array_length(_points); _k++)
    {
        if (point_distance(_cx, _cy, _points[_k].cx, _points[_k].cy) < _dist) return false;
    }
    return true;
}

function map_create(_m)
{
    var _w = _m.w, _h = _m.h;
    global.mw = _w;
    global.mh = _h;
    global.terr = ds_grid_create(_w, _h);       ds_grid_clear(global.terr, T_SAND);
    global.lumen = ds_grid_create(_w, _h);      ds_grid_clear(global.lumen, 0);
    global.isvent = ds_grid_create(_w, _h);     ds_grid_clear(global.isvent, 0);
    global.bgrid = ds_grid_create(_w, _h);      ds_grid_clear(global.bgrid, noone);
    global.shroud = ds_grid_create(_w, _h);     ds_grid_clear(global.shroud, 0);
    global.vents = [];
    global.lumen_claim = ds_map_create();
    random_set_seed(_m.seed);

    var _bases = [_m.player];
    for (var _k = 0; _k < array_length(_m.enemies); _k++) array_push(_bases, _m.enemies[_k]);

    // Base plateaus
    for (var _k = 0; _k < array_length(_bases); _k++) map_blob(_bases[_k].cx, _bases[_k].cy, 7.5, T_ROCK);

    // Outcrops, some topped with crags
    repeat (_m.outcrops)
    {
        for (var _try = 0; _try < 30; _try++)
        {
            var _cx = irandom_range(3, _w - 4), _cy = irandom_range(3, _h - 4);
            if (!far_from(_cx, _cy, _bases, 12)) continue;
            var _r = random_range(2.2, 4.8);
            map_blob(_cx, _cy, _r, T_ROCK);
            if (_r > 2.8)
            {
                repeat (irandom_range(1, 3))
                {
                    var _a = random(360), _d = random(_r - 1.6);
                    var _gx = round(_cx + lengthdir_x(_d, _a)), _gy = round(_cy + lengthdir_y(_d, _a));
                    if (in_map(_gx, _gy) && global.terr[# _gx, _gy] == T_ROCK) global.terr[# _gx, _gy] = T_CRAG;
                }
            }
            break;
        }
    }

    // A lumen field near each base, facing the middle of the map, then more around the map
    var _fields = [];
    for (var _k = 0; _k < array_length(_bases); _k++)
    {
        var _b = _bases[_k];
        var _a = point_direction(_b.cx, _b.cy, _w / 2, _h / 2) + random_range(-50, 50);
        for (var _try = 0; _try < 20; _try++)
        {
            var _fx = round(_b.cx + lengthdir_x(11, _a)), _fy = round(_b.cy + lengthdir_y(11, _a));
            if (in_map(_fx, _fy) && global.terr[# _fx, _fy] == T_SAND) break;
            _a += 23;
        }
        lumen_field(_fx, _fy, random_range(3.4, 4.4));
        array_push(_fields, { cx: _fx, cy: _fy });
    }
    var _left = _m.fields - array_length(_bases);
    for (var _try = 0; _try < 200 && _left > 0; _try++)
    {
        var _fx = irandom_range(3, _w - 4), _fy = irandom_range(3, _h - 4);
        if (global.terr[# _fx, _fy] != T_SAND || !far_from(_fx, _fy, _bases, 10) || !far_from(_fx, _fy, _fields, 8)) continue;
        lumen_field(_fx, _fy, random_range(2.6, 4.6));
        array_push(_fields, { cx: _fx, cy: _fy });
        _left--;
    }
    randomize();

    map_build_grids();
    map_build_tiles();
}

function map_build_grids()
{
    global.grid_veh = mp_grid_create(0, 0, global.mw, global.mh, CELL, CELL);
    global.grid_inf = mp_grid_create(0, 0, global.mw, global.mh, CELL, CELL);
    for (var _i = 0; _i < global.mw; _i++)
    {
        for (var _j = 0; _j < global.mh; _j++)
        {
            if (global.terr[# _i, _j] == T_CRAG) mp_grid_add_cell(global.grid_veh, _i, _j);
        }
    }
}

function map_build_tiles()
{
    var _w = global.mw, _h = global.mh;
    global.lay_terrain = layer_create(10000, "Terrain");
    global.tm_terrain = layer_tilemap_create(global.lay_terrain, -HALF, -HALF, ts_terrain, _w + 1, _h + 1);
    for (var _i = 0; _i <= _w; _i++)
    {
        for (var _j = 0; _j <= _h; _j++)
        {
            var _mask = (is_rock(_i - 1, _j - 1) ? 1 : 0) | (is_rock(_i, _j - 1) ? 2 : 0) | (is_rock(_i, _j) ? 4 : 0) | (is_rock(_i - 1, _j) ? 8 : 0);
            var _t;
            if (_mask == 0) _t = choose(1, 1, 1, 17, 18, 19);
            else if (_mask == 15) _t = choose(16, 16, 20, 21, 22);
            else _t = _mask + 1;
            tilemap_set(global.tm_terrain, _t, _i, _j);
        }
    }
    global.lay_lumen = layer_create(9900, "Lumen");
    global.tm_lumen = layer_tilemap_create(global.lay_lumen, 0, 0, ts_lumen, _w, _h);
    global.lay_crag = layer_create(9800, "Crags");
    global.tm_crag = layer_tilemap_create(global.lay_crag, 0, 0, ts_crag, _w, _h);
    for (var _i = 0; _i < _w; _i++)
    {
        for (var _j = 0; _j < _h; _j++)
        {
            lumen_tile(_i, _j);
            if (global.terr[# _i, _j] == T_CRAG) tilemap_set(global.tm_crag, 1 + ((_i * 7 + _j * 3) mod 4), _i, _j);
        }
    }
}

function lumen_tile(_cx, _cy)
{
    var _t = 0;
    if (global.isvent[# _cx, _cy]) _t = 7;
    else
    {
        var _a = global.lumen[# _cx, _cy];
        if (_a > 0) _t = ((_a < 110) ? 1 : ((_a < 210) ? 3 : 5)) + ((_cx + _cy) mod 2);
    }
    tilemap_set(global.tm_lumen, _t, _cx, _cy);
    global.minimap_dirty = true;
}

/// Takes up to _amount of lumen from a cell; returns what was taken.
function lumen_take(_cx, _cy, _amount)
{
    var _a = global.lumen[# _cx, _cy];
    var _got = min(_a, _amount);
    if (_got <= 0) return 0;
    var _before = (_a < 110) ? 0 : ((_a < 210) ? 1 : 2);
    _a -= _got;
    global.lumen[# _cx, _cy] = _a;
    var _after = (_a <= 0) ? -1 : ((_a < 110) ? 0 : ((_a < 210) ? 1 : 2));
    if (_after != _before) lumen_tile(_cx, _cy);
    return _got;
}

/// Vents slowly grow new crystals around them.
function lumen_regrow()
{
    for (var _k = 0; _k < array_length(global.vents); _k++)
    {
        if (random(1) > 0.35) continue;
        var _v = global.vents[_k];
        var _cx = _v[0] + irandom_range(-3, 3), _cy = _v[1] + irandom_range(-3, 3);
        if (!in_map(_cx, _cy) || global.terr[# _cx, _cy] != T_SAND || global.isvent[# _cx, _cy] || global.bgrid[# _cx, _cy] != noone) continue;
        var _a = global.lumen[# _cx, _cy];
        if (_a >= LUMEN_MAX) continue;
        global.lumen[# _cx, _cy] = min(LUMEN_MAX, _a + 45);
        lumen_tile(_cx, _cy);
    }
}

function map_destroy()
{
    if (!variable_global_exists("terr") || global.terr == -1) return;
    ds_grid_destroy(global.terr);
    ds_grid_destroy(global.lumen);
    ds_grid_destroy(global.isvent);
    ds_grid_destroy(global.bgrid);
    ds_grid_destroy(global.shroud);
    ds_map_destroy(global.lumen_claim);
    mp_grid_destroy(global.grid_veh);
    mp_grid_destroy(global.grid_inf);
    layer_destroy(global.lay_terrain);
    layer_destroy(global.lay_lumen);
    layer_destroy(global.lay_crag);
    global.terr = -1;
}

/// Is a cell free for this kind of unit ("inf" or "veh")?
function cell_free(_cx, _cy, _kind)
{
    if (!in_map(_cx, _cy)) return false;
    var _g = (_kind == "inf") ? global.grid_inf : global.grid_veh;
    return mp_grid_get_cell(_g, _cx, _cy) == 0;
}

/// The nearest cell to (_cx, _cy) a unit can stand on; _avoid is a ds_map of cells already given out (or -1).
function nearest_free_cell(_cx, _cy, _kind, _avoid)
{
    for (var _r = 0; _r < 14; _r++)
    {
        var _best = -1, _bd = 99999;
        for (var _i = _cx - _r; _i <= _cx + _r; _i++)
        {
            for (var _j = _cy - _r; _j <= _cy + _r; _j++)
            {
                if (max(abs(_i - _cx), abs(_j - _cy)) != _r) continue;
                if (!cell_free(_i, _j, _kind)) continue;
                if (_avoid != -1 && ds_map_exists(_avoid, _j * global.mw + _i)) continue;
                var _d = point_distance(_i, _j, _cx, _cy);
                if (_d < _bd) { _bd = _d; _best = [_i, _j]; }
            }
        }
        if (_best != -1) return _best;
    }
    return [clamp(_cx, 0, global.mw - 1), clamp(_cy, 0, global.mh - 1)];
}

// ---------- Shroud (the player's map is black until seen; it stays revealed) ----------

function shroud_reveal(_cx, _cy, _r)
{
    var _changed = false;
    var _rr = ceil(_r);
    for (var _i = _cx - _rr; _i <= _cx + _rr; _i++)
    {
        for (var _j = _cy - _rr; _j <= _cy + _rr; _j++)
        {
            if (!in_map(_i, _j) || global.shroud[# _i, _j]) continue;
            if (point_distance(_i, _j, _cx, _cy) > _r + 0.3) continue;
            global.shroud[# _i, _j] = 1;
            _changed = true;
            if (surface_exists(global.shroud_surf))
            {
                surface_set_target(global.shroud_surf);
                draw_point_colour(_i + 1, _j + 1, c_white);
                surface_reset_target();
            }
        }
    }
    if (_changed) global.minimap_dirty = true;
}

/// The shroud is a tiny surface (one pixel per cell, with a 1-pixel black border) drawn stretched with filtering, so its edges are soft.
function shroud_surface_check()
{
    if (surface_exists(global.shroud_surf)) return;
    global.shroud_surf = surface_create(global.mw + 2, global.mh + 2);
    surface_set_target(global.shroud_surf);
    draw_clear(c_black);
    for (var _i = 0; _i < global.mw; _i++)
    {
        for (var _j = 0; _j < global.mh; _j++)
        {
            if (global.shroud[# _i, _j]) draw_point_colour(_i + 1, _j + 1, c_white);
        }
    }
    surface_reset_target();
}

function shroud_draw()
{
    shroud_surface_check();
    gpu_set_texfilter(true);
    gpu_set_blendmode_ext(bm_zero, bm_src_colour); // multiply
    draw_surface_ext(global.shroud_surf, -CELL, -CELL, CELL, CELL, 0, c_white, 1);
    gpu_set_blendmode(bm_normal);
    gpu_set_texfilter(false);
}

function seen(_px, _py)
{
    var _cx = clamp(cell_of(_px), 0, global.mw - 1), _cy = clamp(cell_of(_py), 0, global.mh - 1);
    return global.shroud[# _cx, _cy] == 1;
}
