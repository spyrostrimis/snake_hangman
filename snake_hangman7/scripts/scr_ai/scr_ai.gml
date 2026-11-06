/// The computer sides: rebuild the base from a build order, keep harvesters working, gather an army and attack in waves.

function ai_create(_e, _diff)
{
    return {
        order: _e.order, mix: _e.mix,
        wave: _e.wave + ((_diff == 2) ? 1 : 0), wave_grow: _e.wave_grow, wave_max: _e.wave_max + ((_diff == 2) ? 2 : 0),
        next_wave: global.frame + _e.first_wave * 60 * ((_diff == 0) ? 1.5 : ((_diff == 2) ? 0.8 : 1)),
        wave_every: _e.wave_every * 60 * ((_diff == 0) ? 1.4 : ((_diff == 2) ? 0.8 : 1)),
        income: [0, 2, 5][_diff],
        harv_per: (_diff == 2) ? 2 : 1,
        home_x: _e.cx * CELL + CELL, home_y: _e.cy * CELL + CELL,
        rally_x: 0, rally_y: 0,
        threat_x: 0, threat_y: 0, threat_t: -99999,
        fails: 0
    };
}

/// The cell of the player's main base (where waves and turrets point).
function player_home()
{
    return [global.mission.player.cx, global.mission.player.cy];
}

function ai_set_rally(_t)
{
    var _ai = global.teams[_t].ai;
    var _ph = player_home();
    var _dir = point_direction(_ai.home_x, _ai.home_y, _ph[0] * CELL, _ph[1] * CELL);
    var _c = nearest_free_cell(cell_of(_ai.home_x + lengthdir_x(6 * CELL, _dir)), cell_of(_ai.home_y + lengthdir_y(6 * CELL, _dir)), "veh", -1);
    _ai.rally_x = _c[0] * CELL + HALF;
    _ai.rally_y = _c[1] * CELL + HALF;
}

function ai_next_structure(_t)
{
    var _ai = global.teams[_t].ai;
    var _need = {};
    for (var _k = 0; _k < array_length(_ai.order); _k++)
    {
        var _type = _ai.order[_k];
        _need[$ _type] = (_need[$ _type] ?? 0) + 1;
        if (bcount(_t, _type) < _need[$ _type] && can_build(_t, _type)) return _type;
    }
    return "";
}

/// Places a structure for an AI side near its yard. Returns the instance or noone.
function ai_place(_t, _type, _instant)
{
    var _ai = global.teams[_t].ai;
    var _d = global.bdef[$ _type];
    var _hx = cell_of(_ai.home_x), _hy = cell_of(_ai.home_y);
    var _ph = player_home();
    var _defence = (_type == "gun" || _type == "rocket");
    var _best = -1, _bs = 999999, _best_tight = -1, _bst = 999999;
    for (var _i = _hx - 11; _i <= _hx + 11; _i++)
    {
        for (var _j = _hy - 11; _j <= _hy + 11; _j++)
        {
            if (!can_place(_t, _type, _i, _j)) continue;
            var _mx = _i + _d.w / 2, _my = _j + _d.h / 2;
            var _dh = point_distance(_mx, _my, _hx + 1, _hy + 1);
            var _score = _defence ? point_distance(_mx, _my, _ph[0], _ph[1]) + ((_dh > 8) ? 200 : 0) + random(2) : _dh + random(1.5);
            // Keep a lane around ordinary structures so units can get out.
            var _gap = true;
            if (!_defence)
            {
                for (var _a = _i - 1; _a <= _i + _d.w && _gap; _a++)
                {
                    for (var _b = _j - 1; _b <= _j + _d.h; _b++)
                    {
                        if (in_map(_a, _b) && global.bgrid[# _a, _b] != noone) { _gap = false; break; }
                    }
                }
            }
            if (_gap && _score < _bs) { _bs = _score; _best = [_i, _j]; }
            if (_score < _bst) { _bst = _score; _best_tight = [_i, _j]; }
        }
    }
    if (_best == -1) _best = _best_tight;
    if (_best == -1) return noone;
    return place_building(_t, _type, _best[0], _best[1], _instant);
}

function ai_new_unit(_t, _u)
{
    var _ai = global.teams[_t].ai;
    _u.ai_role = "home";
    with (_u)
    {
        order = "move";
        unit_path_to(_ai.rally_x + random_range(-40, 40), _ai.rally_y + random_range(-40, 40));
    }
}

function ai_alert(_t, _src, _x, _y)
{
    var _ai = global.teams[_t].ai;
    if (_ai == undefined) return;
    _ai.threat_x = (_src != noone && instance_exists(_src)) ? _src.x : _x;
    _ai.threat_y = (_src != noone && instance_exists(_src)) ? _src.y : _y;
    _ai.threat_t = global.frame;
}

/// Where to send an attack: the enemy structure (or else unit) nearest to (_px, _py).
function ai_attack_point(_t, _px, _py)
{
    var _best = noone, _bd = 9999999;
    with (obj_building)
    {
        if (team != PLAYER || btype == "wall") continue;
        var _d = point_distance(_px, _py, x, y);
        if (_d < _bd) { _bd = _d; _best = id; }
    }
    if (_best == noone)
    {
        with (obj_unit)
        {
            if (team != PLAYER) continue;
            var _d2 = point_distance(_px, _py, x, y);
            if (_d2 < _bd) { _bd = _d2; _best = id; }
        }
    }
    if (_best == noone) return undefined;
    if (_best.object_index == obj_building) return [_best.x + _best.w * HALF, _best.y + _best.h * HALF];
    return [_best.x, _best.y];
}

function ai_pick(_t, _list, _mix)
{
    var _total = 0;
    var _ok = [];
    for (var _k = 0; _k < array_length(_list); _k++)
    {
        var _type = _list[_k];
        var _w = _mix[$ _type] ?? 0;
        if (_w <= 0 || !can_build(_t, _type)) continue;
        array_push(_ok, [_type, _w]);
        _total += _w;
    }
    if (_total <= 0) return "";
    var _r = random(_total);
    for (var _k = 0; _k < array_length(_ok); _k++)
    {
        _r -= _ok[_k][1];
        if (_r <= 0) return _ok[_k][0];
    }
    return _ok[0][0];
}

function ai_step(_t)
{
    var _tm = global.teams[_t];
    var _ai = _tm.ai;
    if (!_tm.alive) return;
    _tm.credits += _ai.income * 0.5;

    // Structures
    var _qb = _tm.q_bld;
    var _want = "";
    if (_qb.item == "" && has(_t, "yard"))
    {
        _want = ai_next_structure(_t);
        if (_want != "" && _tm.credits > global.bdef[$ _want].cost * 0.3) queue_add(_t, _want);
    }
    if (_qb.ready)
    {
        if (ai_place(_t, _qb.item, false) != noone) { _qb.item = ""; _qb.ready = false; _ai.fails = 0; }
        else
        {
            _ai.fails += 1;
            if (_ai.fails > 6) { _qb.item = ""; _qb.ready = false; _ai.fails = 0; }
        }
    }

    // Harvesters first, then the army
    var _harv = 0;
    with (obj_unit) if (team == _t && utype == "harvester") _harv++;
    var _vq = _tm.q_veh.list;
    if (_harv < bcount(_t, "refinery") * _ai.harv_per && array_length(_vq) == 0) queue_add(_t, "harvester");
    var _army = 0;
    with (obj_unit) if (team == _t && utype != "harvester" && ai_role == "home") _army++;
    var _spare = _tm.credits - ((_want != "") ? 200 : 0);
    if (_army >= _ai.wave_max + 4) _spare = 0; // enough at home: save up instead
    if (array_length(_tm.q_inf.list) == 0 && _spare > 150)
    {
        var _ti = ai_pick(_t, global.inf_list, _ai.mix);
        if (_ti != "") queue_add(_t, _ti);
    }
    if (array_length(_tm.q_veh.list) == 0 && _spare > 350)
    {
        var _tv = ai_pick(_t, global.veh_list, _ai.mix);
        if (_tv != "") queue_add(_t, _tv);
    }

    // The army
    var _home = [];
    var _threat = (global.frame - _ai.threat_t < 360) && point_distance(_ai.threat_x, _ai.threat_y, _ai.home_x, _ai.home_y) < 16 * CELL;
    with (obj_unit)
    {
        if (team != _t || utype == "harvester") continue;
        if (ai_role == "home")
        {
            array_push(_home, id);
            if (_threat && order != "amove" && order != "attack")
            {
                order = "amove";
                amove_x = _ai.threat_x;
                amove_y = _ai.threat_y;
                amove_resume = false;
                unit_path_to(amove_x, amove_y);
            }
            else if (!_threat && order == "idle" && target == noone && point_distance(x, y, _ai.rally_x, _ai.rally_y) > 5 * CELL)
            {
                order = "move";
                unit_path_to(_ai.rally_x + random_range(-48, 48), _ai.rally_y + random_range(-48, 48));
            }
        }
        else if (order == "idle" && target == noone)
        {
            var _p = ai_attack_point(_t, x, y);
            if (_p != undefined)
            {
                order = "amove";
                amove_x = _p[0];
                amove_y = _p[1];
                amove_resume = false;
                unit_path_to(amove_x, amove_y);
            }
        }
    }
    if (global.frame >= _ai.next_wave && array_length(_home) >= _ai.wave)
    {
        var _p2 = ai_attack_point(_t, _ai.rally_x, _ai.rally_y);
        if (_p2 != undefined)
        {
            var _send = min(array_length(_home), _ai.wave);
            for (var _k = 0; _k < _send; _k++)
            {
                with (_home[_k])
                {
                    ai_role = "attack";
                    order = "amove";
                    amove_x = _p2[0] + random_range(-40, 40);
                    amove_y = _p2[1] + random_range(-40, 40);
                    amove_resume = false;
                    unit_path_to(amove_x, amove_y);
                }
            }
            _ai.wave = min(_ai.wave_max, _ai.wave + _ai.wave_grow);
            _ai.next_wave = global.frame + _ai.wave_every;
        }
    }
}
