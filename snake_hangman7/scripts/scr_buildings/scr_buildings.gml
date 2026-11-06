/// Structures: placement rules, building, turrets, repair, selling and destruction.

/// Can _team put a _type with its top-left cell at (_cx, _cy)?
/// Structures go on bare rock, on no unit, and within two cells of one of the team's own structures.
function can_place(_team, _type, _cx, _cy)
{
    var _d = global.bdef[$ _type];
    for (var _i = 0; _i < _d.w; _i++)
    {
        for (var _j = 0; _j < _d.h; _j++)
        {
            var _c = _cx + _i, _r = _cy + _j;
            if (!in_map(_c, _r)) return false;
            if (global.terr[# _c, _r] != T_ROCK) return false;
            if (global.bgrid[# _c, _r] != noone) return false;
            if (_team == PLAYER && !global.shroud[# _c, _r]) return false;
        }
    }
    if (collision_rectangle(_cx * CELL + 1, _cy * CELL + 1, (_cx + _d.w) * CELL - 2, (_cy + _d.h) * CELL - 2, obj_unit, false, true) != noone) return false;
    var _near = false;
    with (obj_building)
    {
        if (team != _team) continue;
        var _gx = max(_cx - (cx + w), cx - (_cx + _d.w), 0);
        var _gy = max(_cy - (cy + h), cy - (_cy + _d.h), 0);
        if (max(_gx, _gy) <= 2) { _near = true; break; }
    }
    return _near;
}

function place_building(_team, _type, _cx, _cy, _instant)
{
    var _d = global.bdef[$ _type];
    var _b = instance_create_depth(_cx * CELL, _cy * CELL, DEPTH_BASE - _cy * CELL - 8, obj_building,
        { team: _team, btype: _type, cx: _cx, cy: _cy, built: _instant });
    for (var _i = 0; _i < _d.w; _i++)
    {
        for (var _j = 0; _j < _d.h; _j++)
        {
            var _c = _cx + _i, _r = _cy + _j;
            if (_type == "refinery" && _i == 2 && _j == 1) continue; // the docking pad stays drivable
            global.bgrid[# _c, _r] = _b;
            mp_grid_add_cell(global.grid_veh, _c, _r);
            mp_grid_add_cell(global.grid_inf, _c, _r);
            if (global.lumen[# _c, _r] > 0) { global.lumen[# _c, _r] = 0; lumen_tile(_c, _r); }
        }
    }
    if (_team == PLAYER) shroud_reveal(_cx + _d.w div 2, _cy + _d.h div 2, _d.sight + max(_d.w, _d.h) / 2);
    if (_type == "wall") walls_refresh(_cx, _cy);
    global.minimap_dirty = true;
    return _b;
}

/// Called by a structure when it finishes going up.
function building_complete()
{
    if (btype == "refinery")
    {
        var _h = spawn_unit(team, "harvester", dock_x, dock_y, 180);
        _h.htask = "seek";
    }
}

/// Recomputes the joined shape of the walls around a cell.
function walls_refresh(_cx, _cy)
{
    for (var _i = _cx - 1; _i <= _cx + 1; _i++)
    {
        for (var _j = _cy - 1; _j <= _cy + 1; _j++)
        {
            if (!in_map(_i, _j)) continue;
            var _w = global.bgrid[# _i, _j];
            if (_w == noone || !instance_exists(_w) || _w.btype != "wall") continue;
            _w.wall_mask = (wall_at(_i, _j - 1) ? 1 : 0) | (wall_at(_i + 1, _j) ? 2 : 0) | (wall_at(_i, _j + 1) ? 4 : 0) | (wall_at(_i - 1, _j) ? 8 : 0);
        }
    }
}

function wall_at(_cx, _cy)
{
    if (!in_map(_cx, _cy)) return false;
    var _w = global.bgrid[# _cx, _cy];
    return _w != noone && instance_exists(_w) && _w.btype == "wall";
}

function building_destroy(_b, _killer_team)
{
    with (_b)
    {
        var _big = (w * h >= 4) ? 2 : 1;
        for (var _i = 0; _i < w; _i++)
        {
            for (var _j = 0; _j < h; _j++) fx_explode(x + _i * CELL + HALF + random_range(-6, 6), y + _j * CELL + HALF + random_range(-6, 6), (_i + _j == 0) ? _big : 1);
        }
        if (btype != "wall" && anim >= 1 && random(1) < 0.5)
        {
            var _c = nearest_free_cell(cx + w div 2, cy + h, "inf", -1);
            spawn_unit(team, "trooper", _c[0] * CELL + HALF, _c[1] * CELL + HALF);
        }
        global.teams[team].stats.blost++;
        if (_killer_team >= 0) global.teams[_killer_team].stats.bkilled++;
        if (team == PLAYER) msg(def.name + " destroyed.");
        instance_destroy();
    }
}

/// Frees the cells of a structure that is going away (CleanUp).
function building_free_cells()
{
    for (var _i = 0; _i < w; _i++)
    {
        for (var _j = 0; _j < h; _j++)
        {
            var _c = cx + _i, _r = cy + _j;
            if (!in_map(_c, _r) || global.bgrid[# _c, _r] != id) continue;
            global.bgrid[# _c, _r] = noone;
            mp_grid_clear_cell(global.grid_veh, _c, _r);
            mp_grid_clear_cell(global.grid_inf, _c, _r);
        }
    }
    if (btype == "wall") walls_refresh(cx, cy);
    if (docked != noone && instance_exists(docked)) docked.htask = "return";
    global.minimap_dirty = true;
}

function building_sell(_b)
{
    with (_b)
    {
        global.teams[team].credits += floor(def.cost * 0.5 * hp / maxhp);
        part_particles_create(global.ps, x + w * HALF, y + h * HALF, global.pt_dust, 10);
        play_at("place", x, y);
        instance_destroy();
    }
}

/// Behaviour of a finished turret (called from obj_building's Step).
function turret_step()
{
    if (target != noone && (!instance_exists(target) || target_dist(target, x + HALF, y + HALF) > def.range * CELL)) target = noone;
    think--;
    if (think <= 0)
    {
        think = 10;
        if (target == noone) target = find_target(x + HALF, y + HALF, team, def.range * CELL, 0);
    }
    reload = max(0, reload - (global.teams[team].power_low ? 0.5 : 1));
    if (target == noone) return;
    var _want = point_direction(x + HALF, y + HALF, aim_x(target, x + HALF), aim_y(target, y + HALF));
    var _diff = angle_difference(_want, tface);
    tface = (tface + clamp(_diff, -5, 5) + 360) mod 360;
    if (abs(_diff) < 8 && reload <= 0)
    {
        fire_weapon(target, def.weapon, def.dmg, x + HALF + lengthdir_x(12, tface), y + HALF + lengthdir_y(12, tface), 1);
        reload = def.reload;
    }
}
