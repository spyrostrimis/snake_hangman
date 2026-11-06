/// Sides in play, power, and the three build queues (structures, infantry, vehicles).

function team_create(_side_index, _col, _name, _is_ai, _credits)
{
    return {
        side: _side_index, col: _col, name: _name, is_ai: _is_ai,
        credits: _credits, shown: _credits, harvested: 0,
        power_made: 0, power_used: 0, power_low: false,
        bcount: {}, units: 0, buildings: 0, alive: true,
        q_bld: { item: "", prog: 0, paid: 0, ready: false, stalled: false },
        q_inf: { list: [], prog: 0, paid: 0, stalled: false },
        q_veh: { list: [], prog: 0, paid: 0, stalled: false },
        rally: { barracks: undefined, factory: undefined },
        stats: { killed: 0, lost: 0, bkilled: 0, blost: 0 },
        ai: undefined
    };
}

/// Counts finished structures and power for every side (once per step).
function teams_tally()
{
    var _n = array_length(global.teams);
    for (var _t = 0; _t < _n; _t++)
    {
        var _tm = global.teams[_t];
        _tm.bcount = {};
        _tm.power_made = 0;
        _tm.power_used = 0;
        _tm.units = 0;
        _tm.buildings = 0;
    }
    with (obj_building)
    {
        var _tm2 = global.teams[team];
        if (btype != "wall") _tm2.buildings++;
        if (anim < 1) continue;
        _tm2.bcount[$ btype] = (_tm2.bcount[$ btype] ?? 0) + 1;
        if (def.power > 0) _tm2.power_made += def.power; else _tm2.power_used -= def.power;
    }
    with (obj_unit) global.teams[team].units++;
    for (var _t = 0; _t < _n; _t++)
    {
        var _tm3 = global.teams[_t];
        _tm3.power_low = _tm3.power_used > _tm3.power_made;
    }
}

function has(_team, _type)
{
    return (global.teams[_team].bcount[$ _type] ?? 0) > 0;
}

function bcount(_team, _type)
{
    return global.teams[_team].bcount[$ _type] ?? 0;
}

function def_of(_type)
{
    return variable_struct_exists(global.bdef, _type) ? global.bdef[$ _type] : global.udef[$ _type];
}

/// Is an item buildable right now (tech level, prerequisites, and the place that makes it)?
function can_build(_team, _type)
{
    var _d = def_of(_type);
    if (_d.tech > global.tech) return false;
    var _at = variable_struct_exists(global.bdef, _type) ? "yard" : _d.at;
    if (!has(_team, _at)) return false;
    for (var _k = 0; _k < array_length(_d.needs); _k++) if (!has(_team, _d.needs[_k])) return false;
    return true;
}

function queue_of(_team, _type)
{
    var _tm = global.teams[_team];
    if (variable_struct_exists(global.bdef, _type)) return _tm.q_bld;
    return (global.udef[$ _type].kind == "inf") ? _tm.q_inf : _tm.q_veh;
}

function build_frames(_type)
{
    var _d = def_of(_type);
    if (variable_struct_exists(global.bdef, _type)) return (2.5 + _d.cost / 80) * 60;
    return (2 + _d.cost / 90) * 60;
}

/// Starts or queues an item. Returns true if accepted.
function queue_add(_team, _type)
{
    if (!can_build(_team, _type)) return false;
    var _tm = global.teams[_team];
    if (variable_struct_exists(global.bdef, _type))
    {
        if (_tm.q_bld.item != "") return false;
        _tm.q_bld.item = _type;
        _tm.q_bld.prog = 0;
        _tm.q_bld.paid = 0;
        _tm.q_bld.ready = false;
        return true;
    }
    var _q = queue_of(_team, _type);
    if (array_length(_q.list) >= 6) return false;
    array_push(_q.list, _type);
    if (array_length(_q.list) == 1) { _q.prog = 0; _q.paid = 0; }
    return true;
}

/// Cancels the last queued _type (refunding what was spent if it had started).
function queue_cancel(_team, _type)
{
    var _tm = global.teams[_team];
    if (variable_struct_exists(global.bdef, _type))
    {
        if (_tm.q_bld.item != _type) return false;
        _tm.credits += _tm.q_bld.paid;
        _tm.q_bld.item = "";
        _tm.q_bld.ready = false;
        return true;
    }
    var _q = queue_of(_team, _type);
    for (var _k = array_length(_q.list) - 1; _k >= 0; _k--)
    {
        if (_q.list[_k] != _type) continue;
        if (_k == 0) { _tm.credits += _q.paid; _q.prog = 0; _q.paid = 0; }
        array_delete(_q.list, _k, 1);
        return true;
    }
    return false;
}

function queue_count(_team, _type)
{
    var _q = queue_of(_team, _type);
    if (variable_struct_exists(global.bdef, _type)) return (_q.item == _type) ? 1 : 0;
    var _n = 0;
    for (var _k = 0; _k < array_length(_q.list); _k++) if (_q.list[_k] == _type) _n++;
    return _n;
}

/// Advances one queue item: credits are spent as it progresses, so an empty purse pauses it.
function queue_advance(_tm, _q, _type)
{
    var _frames = build_frames(_type);
    var _cost = def_of(_type).cost;
    var _rate = _tm.power_low ? 0.5 : 1;
    if (_tm.is_ai) _rate *= global.ai_speed;
    var _step = _rate / _frames;
    var _price = _cost * _step;
    if (_tm.credits < _price) { _q.stalled = true; return false; }
    _q.stalled = false;
    _tm.credits -= _price;
    _q.paid += _price;
    _q.prog = min(1, _q.prog + _step);
    return _q.prog >= 1;
}

function production_step(_team)
{
    var _tm = global.teams[_team];
    // Structures
    var _qb = _tm.q_bld;
    if (_qb.item != "" && !_qb.ready)
    {
        if (!has(_team, "yard")) { _tm.credits += _qb.paid; _qb.item = ""; }
        else if (queue_advance(_tm, _qb, _qb.item))
        {
            _qb.ready = true;
            if (_team == PLAYER) { msg("Construction complete. Click it to place the " + global.bdef[$ _qb.item].name + "."); play("complete"); }
        }
    }
    // Units
    var _qs = [_tm.q_inf, _tm.q_veh];
    for (var _k = 0; _k < 2; _k++)
    {
        var _q = _qs[_k];
        if (array_length(_q.list) == 0) continue;
        var _type = _q.list[0];
        if (!can_build(_team, _type))
        {
            _tm.credits += _q.paid;
            _q.list = [];
            _q.prog = 0;
            _q.paid = 0;
            continue;
        }
        if (queue_advance(_tm, _q, _type))
        {
            if (deliver_unit(_team, _type))
            {
                array_delete(_q.list, 0, 1);
                _q.prog = 0;
                _q.paid = 0;
            }
            else _q.prog = 0.999;
        }
    }
}

/// Puts a finished unit outside the newest building that makes it.
function deliver_unit(_team, _type)
{
    var _d = global.udef[$ _type];
    var _src = noone;
    with (obj_building)
    {
        if (team == _team && btype == _d.at && anim >= 1) _src = id;
    }
    if (_src == noone) return false;
    var _ex = _src.cx + _src.w div 2, _ey = _src.cy + _src.h;
    var _avoid = ds_map_create();
    var _made = [];
    for (var _s = 0; _s < _d.squad; _s++)
    {
        var _c = nearest_free_cell(_ex, _ey, _d.kind, (_d.kind == "inf") ? -1 : _avoid);
        _avoid[? _c[1] * global.mw + _c[0]] = 1;
        var _ox = (_d.squad > 1) ? (_s - 1) * 7 : 0;
        var _u = spawn_unit(_team, _type, _c[0] * CELL + HALF + _ox, _c[1] * CELL + HALF + ((_s == 1) ? -4 : 3), 270);
        array_push(_made, _u);
    }
    ds_map_destroy(_avoid);
    var _tm = global.teams[_team];
    var _r = _tm.rally[$ _d.at];
    for (var _k = 0; _k < array_length(_made); _k++)
    {
        var _u2 = _made[_k];
        if (_type == "harvester") { _u2.htask = "seek"; continue; }
        if (_r != undefined) with (_u2) { order = "move"; unit_path_to(_r[0] + random_range(-10, 10), _r[1] + random_range(-10, 10)); }
        if (_tm.is_ai) ai_new_unit(_team, _u2);
    }
    if (_team == PLAYER) { msg(_d.name + " ready."); play("ready"); }
    return true;
}
