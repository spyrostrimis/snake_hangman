/// Units: moving along mp_grid paths, finding and shooting targets, harvesting, taking damage.

#macro HARV_CAP 700

function spawn_unit(_team, _type, _x, _y, _face = 270)
{
    var _u = instance_create_depth(_x, _y, DEPTH_BASE - _y, obj_unit, { team: _team, utype: _type, face: _face });
    return _u;
}

// ---------- Movement ----------

function unit_grid()
{
    return (kind == "inf") ? global.grid_inf : global.grid_veh;
}

/// Finds a path to the free cell nearest (_px, _py). Returns true if the unit is now moving.
function unit_path_to(_px, _py)
{
    var _tcx = clamp(cell_of(_px), 0, global.mw - 1), _tcy = clamp(cell_of(_py), 0, global.mh - 1);
    if (!cell_free(_tcx, _tcy, kind))
    {
        var _c = nearest_free_cell(_tcx, _tcy, kind, -1);
        _tcx = _c[0];
        _tcy = _c[1];
    }
    goal_x = _tcx * CELL + HALF;
    goal_y = _tcy * CELL + HALF;
    stuck_t = 0;
    stuck_d = point_distance(x, y, goal_x, goal_y);
    if (mp_grid_path(unit_grid(), path, x, y, goal_x, goal_y, true))
    {
        path_i = 1;
        moving = true;
        return true;
    }
    if (!cell_free(cell_of(x), cell_of(y), kind))
    {
        // Standing somewhere blocked (a building went up around us): walk straight out.
        var _c2 = nearest_free_cell(cell_of(x), cell_of(y), kind, -1);
        path_clear_points(path);
        path_add_point(path, x, y, 100);
        path_add_point(path, _c2[0] * CELL + HALF, _c2[1] * CELL + HALF, 100);
        path_i = 1;
        moving = true;
        return true;
    }
    moving = false;
    return false;
}

function unit_follow()
{
    if (!moving) return;
    var _n = path_get_number(path);
    if (path_i >= _n) { moving = false; return; }
    var _px = path_get_point_x(path, path_i), _py = path_get_point_y(path, path_i);
    var _d = point_distance(x, y, _px, _py);
    var _dir = point_direction(x, y, _px, _py);
    var _sp = def.spd;
    if (_d > 0.5)
    {
        if (kind == "inf") face = _dir;
        else
        {
            var _diff = angle_difference(_dir, face);
            face = (face + clamp(_diff, -def.turn, def.turn) + 360) mod 360;
            if (abs(_diff) > 55) return; // turn on the spot first
            if (abs(_diff) > 20) _sp *= 0.5;
        }
        var _st = min(_sp, _d);
        x += lengthdir_x(_st, _dir);
        y += lengthdir_y(_st, _dir);
    }
    if (_d <= _sp + 0.5)
    {
        path_i++;
        if (path_i >= _n) moving = false;
    }
    stuck_t++;
    if (stuck_t >= 75)
    {
        var _gd = point_distance(x, y, goal_x, goal_y);
        if (stuck_d - _gd < 8)
        {
            repaths++;
            if (repaths > 3) { moving = false; repaths = 0; }
            else
            {
                var _gx = goal_x, _gy = goal_y;
                unit_path_to(_gx, _gy);
            }
        }
        else repaths = 0;
        stuck_d = _gd;
        stuck_t = 0;
    }
}

/// Keeps units from piling on one spot; vehicles run over enemy infantry.
function unit_separate()
{
    if ((global.frame + phase) mod 2 != 0) return;
    var _list = global.tmp_list;
    ds_list_clear(_list);
    var _n = collision_circle_list(x, y, radius + 14, obj_unit, false, true, _list, false);
    for (var _k = 0; _k < _n; _k++)
    {
        var _o = _list[| _k];
        var _d = point_distance(x, y, _o.x, _o.y);
        if (kind == "veh" && moving && _o.kind == "inf" && _o.team != team && _d < radius * 0.8)
        {
            play_at("crunch", _o.x, _o.y);
            unit_kill(_o, team);
            continue;
        }
        var _min = (kind == "inf" && _o.kind == "inf") ? 6 : (radius + _o.radius) * 0.75;
        if (_d >= _min) continue;
        var _push = min(1.2, (_min - _d) * 0.3);
        if (!moving) _push *= 0.6;
        var _dir = (_d < 0.01) ? random(360) : point_direction(_o.x, _o.y, x, y);
        var _nx = x + lengthdir_x(_push, _dir), _ny = y + lengthdir_y(_push, _dir);
        if (cell_free(cell_of(_nx), cell_of(_ny), kind)) { x = _nx; y = _ny; }
    }
}

function unit_after_move()
{
    depth = DEPTH_BASE - y;
    var _cx = cell_of(x), _cy = cell_of(y);
    if (_cx != cell_x || _cy != cell_y)
    {
        cell_x = _cx;
        cell_y = _cy;
        if (team == PLAYER) shroud_reveal(_cx, _cy, def.sight);
    }
}

// ---------- Targets ----------

function bld_dist(_b, _px, _py)
{
    var _nx = clamp(_px, _b.x, _b.x + _b.w * CELL), _ny = clamp(_py, _b.y, _b.y + _b.h * CELL);
    return point_distance(_px, _py, _nx, _ny);
}

function target_dist(_t, _px, _py)
{
    if (_t.object_index == obj_building) return bld_dist(_t, _px, _py);
    return point_distance(_px, _py, _t.x, _t.y);
}

function aim_x(_t, _px)
{
    if (_t.object_index == obj_building) return clamp(_px, _t.x + 6, _t.x + _t.w * CELL - 6);
    return _t.x;
}

function aim_y(_t, _py)
{
    if (_t.object_index == obj_building) return clamp(_py, _t.y + 6, _t.y + _t.h * CELL - 6);
    return _t.y;
}

/// The nearest enemy within _range pixels: units first, then structures (walls last).
function find_target(_px, _py, _team, _range, _min_range)
{
    var _best = noone, _bd = _range;
    with (obj_unit)
    {
        if (team == _team) continue;
        var _d = point_distance(x, y, _px, _py);
        if (_d < _bd && _d >= _min_range) { _bd = _d; _best = id; }
    }
    if (_best != noone) return _best;
    var _wall = noone;
    with (obj_building)
    {
        if (team == _team) continue;
        var _d = bld_dist(id, _px, _py);
        if (_d >= _bd || _d < _min_range) continue;
        if (btype == "wall") { _wall = id; continue; }
        _bd = _d;
        _best = id;
    }
    return (_best != noone) ? _best : _wall;
}

/// Fires the weapon of a unit or a turret (called in its scope).
function fire_weapon(_target, _weapon, _dmg, _mx, _my, _shots)
{
    var _tx = aim_x(_target, _mx), _ty = aim_y(_target, _my);
    for (var _s = 0; _s < _shots; _s++)
    {
        var _ox = 0, _oy = 0;
        if (_shots > 1)
        {
            var _side = (_s == 0) ? -3 : 3;
            _ox = lengthdir_x(_side, point_direction(_mx, _my, _tx, _ty) + 90);
            _oy = lengthdir_y(_side, point_direction(_mx, _my, _tx, _ty) + 90);
        }
        var _ex = _tx, _ey = _ty;
        if (_weapon == "artillery") { _ex += random_range(-18, 18); _ey += random_range(-18, 18); }
        else if (_weapon == "bullet") { _ex += random_range(-3, 3); _ey += random_range(-3, 3); }
        instance_create_depth(_mx + _ox, _my + _oy, 1400, obj_proj, { team: team, weapon: _weapon, dmg: _dmg, tx: _ex + _ox, ty: _ey + _oy, target: _target, owner: id });
    }
    part_particles_create(global.ps, _mx, _my, global.pt_flash, 1);
    switch (_weapon)
    {
        case "bullet": play_at("gun", _mx, _my); break;
        case "shell": play_at("cannon", _mx, _my); break;
        default: play_at("rocket", _mx, _my); break;
    }
}

function unit_fire(_target)
{
    var _dir = (def.tur != -1) ? tface : face;
    var _len = (kind == "inf") ? 6 : ((def.tur != -1) ? 13 : 10);
    var _mx = x + lengthdir_x(_len, _dir), _my = y + lengthdir_y(_len, _dir);
    fire_weapon(_target, def.weapon, def.dmg, _mx, _my, variable_struct_exists(def, "shots") ? def.shots : 1);
    reload = def.reload + irandom(6);
}

function unit_stop()
{
    moving = false;
    target = noone;
    order = "idle";
    guard_x = x;
    guard_y = y;
}

/// Main behaviour of a combat unit (called from obj_unit's Step).
function unit_step()
{
    if (flash > 0) flash--;
    reload = max(0, reload - 1);
    if (utype == "harvester")
    {
        harvester_step();
        unit_follow();
        unit_separate();
        unit_after_move();
        return;
    }
    if (target != noone && !instance_exists(target)) target = noone;
    if (order == "move") target = noone;

    think--;
    if (think <= 0)
    {
        think = 12;
        if (order == "idle" || order == "amove")
        {
            var _sr = max(def.sight, def.range) * CELL;
            if (target == noone || target_dist(target, x, y) > _sr + CELL) target = find_target(x, y, team, _sr, 0);
        }
        if (order == "idle" && target != noone && point_distance(x, y, guard_x, guard_y) > 7 * CELL)
        {
            target = noone;
            unit_path_to(guard_x, guard_y);
        }
    }

    var _aiming = false;
    if (target != noone)
    {
        var _d = target_dist(target, x, y);
        var _ax = aim_x(target, x), _ay = aim_y(target, y);
        if (_d <= def.range * CELL && _d >= def.minr * CELL)
        {
            moving = false;
            _aiming = true;
            var _want = point_direction(x, y, _ax, _ay);
            var _aimed = false;
            if (def.tur != -1)
            {
                var _diff = angle_difference(_want, tface);
                tface = (tface + clamp(_diff, -6, 6) + 360) mod 360;
                _aimed = abs(_diff) < 10;
            }
            else if (kind == "inf")
            {
                face = _want;
                _aimed = true;
            }
            else
            {
                var _diff2 = angle_difference(_want, face);
                face = (face + clamp(_diff2, -def.turn * 1.5, def.turn * 1.5) + 360) mod 360;
                _aimed = abs(_diff2) < 12;
            }
            if (_aimed && reload == 0) unit_fire(target);
        }
        else if (_d < def.minr * CELL)
        {
            // Too close for artillery: back away.
            if (!moving)
            {
                var _away = point_direction(_ax, _ay, x, y);
                unit_path_to(x + lengthdir_x(3 * CELL, _away), y + lengthdir_y(3 * CELL, _away));
            }
        }
        else
        {
            chase_t--;
            if (chase_t <= 0 || !moving)
            {
                chase_t = 30;
                unit_path_to(_ax, _ay);
                if (order == "amove") amove_resume = true;
            }
        }
    }
    else
    {
        if (order == "attack") { order = "idle"; guard_x = x; guard_y = y; }
        if (order == "amove")
        {
            if (amove_resume) { amove_resume = false; unit_path_to(amove_x, amove_y); }
            else if (!moving) { order = "idle"; guard_x = x; guard_y = y; }
        }
    }
    if (order == "move" && !moving) { order = "idle"; guard_x = x; guard_y = y; }
    if (!_aiming && def.tur != -1)
    {
        var _back = angle_difference(face, tface);
        tface = (tface + clamp(_back, -4, 4) + 360) mod 360;
    }
    unit_follow();
    unit_separate();
    unit_after_move();
}

// ---------- Harvesters ----------

function lumen_claim_key(_cx, _cy)
{
    return _cy * global.mw + _cx;
}

function lumen_claimed(_cx, _cy, _by)
{
    var _k = lumen_claim_key(_cx, _cy);
    if (!ds_map_exists(global.lumen_claim, _k)) return false;
    var _o = global.lumen_claim[? _k];
    return _o != _by && instance_exists(_o);
}

function lumen_unclaim()
{
    if (dig_cx < 0) return;
    var _k = lumen_claim_key(dig_cx, dig_cy);
    if (ds_map_exists(global.lumen_claim, _k) && global.lumen_claim[? _k] == id) ds_map_delete(global.lumen_claim, _k);
}

/// The nearest unclaimed lumen cell to (_cx, _cy), or -1.
function lumen_find(_cx, _cy, _maxr, _by)
{
    for (var _r = 0; _r <= _maxr; _r++)
    {
        var _best = -1, _bd = 99999;
        for (var _i = _cx - _r; _i <= _cx + _r; _i++)
        {
            for (var _j = _cy - _r; _j <= _cy + _r; _j++)
            {
                if (max(abs(_i - _cx), abs(_j - _cy)) != _r || !in_map(_i, _j)) continue;
                if (global.lumen[# _i, _j] <= 0 || global.bgrid[# _i, _j] != noone || lumen_claimed(_i, _j, _by)) continue;
                var _d = point_distance(_i, _j, _cx, _cy);
                if (_d < _bd) { _bd = _d; _best = [_i, _j]; }
            }
        }
        if (_best != -1) return _best;
    }
    return -1;
}

function nearest_refinery(_team, _px, _py)
{
    var _best = noone, _bd = 999999;
    with (obj_building)
    {
        if (team != _team || btype != "refinery" || anim < 1) continue;
        var _d = point_distance(_px, _py, dock_x, dock_y);
        if (docked != noone && instance_exists(docked)) _d += 6 * CELL;
        if (_d < _bd) { _bd = _d; _best = id; }
    }
    return _best;
}

function harvester_dig_at(_cx, _cy)
{
    lumen_unclaim();
    dig_cx = _cx;
    dig_cy = _cy;
    global.lumen_claim[? lumen_claim_key(_cx, _cy)] = id;
    unit_path_to(_cx * CELL + HALF, _cy * CELL + HALF);
    htask = "go";
}

function harvester_undock()
{
    if (dock_ref != noone && instance_exists(dock_ref) && dock_ref.docked == id) dock_ref.docked = noone;
}

function harvester_step()
{
    switch (htask)
    {
        case "idle":
            // After a manual order, go back to work once it has been parked for a while.
            if (moving) wait_t = 0;
            else { wait_t++; if (wait_t > 600) { wait_t = 0; htask = (cargo >= HARV_CAP * 0.85) ? "return" : "seek"; } }
            break;

        case "wait":
            wait_t--;
            if (wait_t <= 0) htask = "seek";
            break;

        case "seek":
            if (cargo >= HARV_CAP) { htask = "return"; break; }
            var _fx = (last_cx >= 0) ? last_cx : cell_of(x), _fy = (last_cx >= 0) ? last_cy : cell_of(y);
            var _c = lumen_find(_fx, _fy, 40, id);
            if (_c == -1)
            {
                if (cargo > 0) htask = "return";
                else { htask = "wait"; wait_t = 180; }
                break;
            }
            harvester_dig_at(_c[0], _c[1]);
            break;

        case "go":
            if (global.lumen[# dig_cx, dig_cy] <= 0) { lumen_unclaim(); htask = "seek"; break; }
            if (!moving)
            {
                if (point_distance(x, y, dig_cx * CELL + HALF, dig_cy * CELL + HALF) < 12) { htask = "dig"; dig_t = 0; }
                else
                {
                    lumen_unclaim();
                    last_cx = cell_of(x);
                    last_cy = cell_of(y);
                    htask = "wait";
                    wait_t = 40;
                }
            }
            break;

        case "dig":
            dig_t++;
            face = (face + sin(dig_t / 14) * 1.2 + 360) mod 360;
            if (dig_t mod 5 == 0)
            {
                var _got = lumen_take(dig_cx, dig_cy, 7);
                cargo += _got;
                if (dig_t mod 15 == 0)
                {
                    var _fx2 = x + lengthdir_x(16, face), _fy2 = y + lengthdir_y(16, face);
                    part_particles_create(global.ps, _fx2, _fy2, global.pt_dust, 1);
                    part_particles_create(global.ps, _fx2, _fy2, global.pt_lumen, 2);
                }
                if (cargo >= HARV_CAP || _got == 0)
                {
                    lumen_unclaim();
                    last_cx = dig_cx;
                    last_cy = dig_cy;
                    htask = (cargo >= HARV_CAP * 0.85) ? "return" : "seek";
                }
            }
            break;

        case "return":
            var _ref = nearest_refinery(team, x, y);
            if (_ref == noone) { htask = "wait"; wait_t = 240; break; }
            dock_ref = _ref;
            unit_path_to(_ref.dock_x, _ref.dock_y);
            htask = "to_dock";
            break;

        case "to_dock":
            if (!instance_exists(dock_ref)) { htask = "return"; break; }
            var _busy = dock_ref.docked != noone && dock_ref.docked != id && instance_exists(dock_ref.docked);
            var _dd = point_distance(x, y, dock_ref.dock_x, dock_ref.dock_y);
            if (_busy)
            {
                if (_dd < 80) moving = false;
                break;
            }
            if (!moving)
            {
                if (_dd < 8)
                {
                    dock_ref.docked = id;
                    x = dock_ref.dock_x;
                    y = dock_ref.dock_y;
                    htask = "unload";
                    dig_t = 0;
                }
                else
                {
                    var _okp = unit_path_to(dock_ref.dock_x, dock_ref.dock_y);
                    if (!_okp) { htask = "wait"; wait_t = 60; }
                }
            }
            break;

        case "unload":
            if (!instance_exists(dock_ref)) { htask = "return"; break; }
            moving = false;
            var _fd = angle_difference(180, face);
            face = (face + clamp(_fd, -3, 3) + 360) mod 360;
            dig_t++;
            if (dig_t > 20 && dig_t mod 2 == 0)
            {
                var _a = min(cargo, 8);
                cargo -= _a;
                var _tm = global.teams[team];
                _tm.credits += _a;
                _tm.harvested += _a;
                if (dig_t mod 8 == 0) part_particles_create(global.ps, dock_ref.x + 70 + random(20), dock_ref.y + 30, global.pt_lumen, 1);
                if (team == PLAYER && dig_t mod 10 == 0) play("cash", 0.4);
            }
            if (cargo <= 0)
            {
                dock_ref.docked = noone;
                htask = "seek";
            }
            break;
    }
}

// ---------- Damage ----------

function deal_damage(_t, _amount, _weapon, _src_team, _src)
{
    if (!instance_exists(_t) || _t.team == _src_team) return;
    _t.hp -= _amount * dmg_mod(_weapon, _t.armor);
    _t.flash = 4;
    if (_t.hp <= 0)
    {
        if (_t.object_index == obj_building) building_destroy(_t, _src_team);
        else unit_kill(_t, _src_team);
        return;
    }
    if (_t.object_index == obj_unit && instance_exists(_src))
    {
        with (_t)
        {
            if (order == "idle" && target == noone && def.dmg > 0) target = _src;
        }
    }
    if (_t.team == PLAYER)
    {
        if (global.frame - global.alert_frame > 60 * 25)
        {
            var _what = (_t.object_index == obj_building) ? "Our base is under attack!" : ((_t.utype == "harvester") ? "Our Harvester is under attack!" : "Our units are under attack.");
            if (_t.object_index == obj_building || _t.utype == "harvester")
            {
                msg(_what + "   [Space] to look");
                play("alarm", 0.8);
            }
            global.alert_frame = global.frame;
        }
        global.alert_x = _t.x;
        global.alert_y = _t.y;
    }
    if (global.teams[_t.team].is_ai) ai_alert(_t.team, _src, _t.x, _t.y);
}

function unit_kill(_u, _killer_team)
{
    with (_u)
    {
        if (kind == "inf")
        {
            part_particles_create(global.ps, x, y, global.pt_dust, 4);
            play_at("crunch", x, y);
        }
        else fx_explode(x, y, (utype == "harvester" || utype == "heavy") ? 2 : 1);
        global.teams[team].stats.lost++;
        if (_killer_team >= 0) global.teams[_killer_team].stats.killed++;
        instance_destroy();
    }
}
