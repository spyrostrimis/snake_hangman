/// Starting and ending missions, the game tick, and the player's mouse and keyboard orders.

function mission_clear()
{
    with (obj_proj) instance_destroy();
    with (obj_unit) instance_destroy();
    with (obj_building) instance_destroy();
    map_destroy();
    if (surface_exists(global.shroud_surf)) surface_free(global.shroud_surf);
    if (surface_exists(global.mm_base)) surface_free(global.mm_base);
    if (surface_exists(global.mm_surf)) surface_free(global.mm_surf);
    global.shroud_surf = -1;
    global.mm_base = -1;
    global.mm_surf = -1;
    part_particles_clear(global.ps);
    global.decals = [];
    global.sel = [];
    global.sel_one = noone;
    global.placing = "";
    global.cmd = "";
    global.teams = [];
}

function spawn_group(_team, _types, _cx, _cy)
{
    var _avoid = ds_map_create();
    for (var _k = 0; _k < array_length(_types); _k++)
    {
        var _d = global.udef[$ _types[_k]];
        for (var _s = 0; _s < _d.squad; _s++)
        {
            var _c = nearest_free_cell(_cx, _cy, "veh", _avoid);
            _avoid[? _c[1] * global.mw + _c[0]] = 1;
            var _u = spawn_unit(_team, _types[_k], _c[0] * CELL + HALF, _c[1] * CELL + HALF, irandom(7) * 45);
            if (_team != PLAYER) _u.ai_role = "home";
        }
    }
    ds_map_destroy(_avoid);
}

function mission_start(_index)
{
    mission_clear();
    var _m = global.missions[_index];
    global.mission_index = _index;
    global.mission = _m;
    global.tech = _m.tech;
    global.frame = 0;
    global.alert_frame = -99999;
    global.alert_x = -1;
    global.alert_y = -1;
    global.paused = false;
    global.result = "";
    global.groups = array_create(10, []);
    global.ai_speed = [0.75, 1, 1.25][global.difficulty];
    global.order_fx = [];
    var _ps = global.player_side;
    global.teams = [team_create(_ps, global.sides[_ps].col, global.sides[_ps].name, false, _m.credits)];
    for (var _k = 0; _k < array_length(_m.enemies); _k++)
    {
        var _e = _m.enemies[_k];
        var _side = (_e.side == -1) ? (1 - _ps) : _e.side;
        var _tm = team_create(_side, global.sides[_side].col, global.sides[_side].name, true, _e.credits);
        _tm.ai = ai_create(_e, global.difficulty);
        array_push(global.teams, _tm);
    }
    map_create(_m);
    global.minimap_dirty = true;

    // The player's base
    var _p = _m.player;
    place_building(PLAYER, "yard", _p.cx, _p.cy, true);
    shroud_reveal(_p.cx + 1, _p.cy + 1, 8);
    spawn_group(PLAYER, _m.start_units, _p.cx + 1, _p.cy - 2);

    // The enemy bases
    for (var _k = 0; _k < array_length(_m.enemies); _k++)
    {
        var _t = _k + 1;
        var _e2 = _m.enemies[_k];
        place_building(_t, "yard", _e2.cx, _e2.cy, true);
        ai_set_rally(_t);
        teams_tally();
        for (var _b = 0; _b < array_length(_e2.base); _b++)
        {
            ai_place(_t, _e2.base[_b], true);
            teams_tally();
        }
        var _ai = global.teams[_t].ai;
        spawn_group(_t, _e2.units, cell_of(_ai.rally_x), cell_of(_ai.rally_y));
    }
    teams_tally();
    cam_center(_p.cx * CELL + CELL, _p.cy * CELL + CELL);
    global.state = "play";
    msg("Mission " + string(_index + 1) + ": " + _m.title + ".  " + _m.objective);
}

function mission_end(_won)
{
    global.state = "end";
    global.result = _won ? "win" : "lose";
    global.end_t = 0;
    global.placing = "";
    play(_won ? "win" : "lose");
    if (_won)
    {
        ini_open("embersand.ini");
        ini_write_real("progress", "m" + string(global.mission_index), 1);
        ini_close();
        global.done[global.mission_index] = true;
    }
}

function check_end()
{
    var _m = global.mission;
    var _all_down = true;
    for (var _t = 1; _t < array_length(global.teams); _t++)
    {
        var _tm = global.teams[_t];
        if (_tm.alive && _tm.buildings == 0)
        {
            _tm.alive = false;
            msg("The " + _tm.name + " base has fallen!");
        }
        if (_tm.alive) _all_down = false;
    }
    var _me = global.teams[PLAYER];
    if (_me.buildings == 0 && _me.units == 0) { mission_end(false); return; }
    if (_m.goal == "credits" && _me.credits >= _m.goal_amount) { mission_end(true); return; }
    if (_m.goal == "destroy" && _all_down) mission_end(true);
}

/// One frame of the world, apart from the units' and structures' own Step events.
function game_tick()
{
    global.frame++;
    teams_tally();
    for (var _t = 0; _t < array_length(global.teams); _t++)
    {
        production_step(_t);
        if (global.teams[_t].is_ai && (global.frame + _t * 13) mod 30 == 0) ai_step(_t);
    }
    if (global.frame mod 60 == 0) lumen_regrow();
    if (global.frame mod 30 == 0) check_end();
    var _me = global.teams[PLAYER];
    _me.shown += clamp(_me.credits - _me.shown, -25, 25);
    if (abs(_me.credits - _me.shown) < 1) _me.shown = _me.credits;
    if (global.message_t > 0) global.message_t--;
    global.shake = max(0, global.shake - 0.15);
    for (var _k = array_length(global.order_fx) - 1; _k >= 0; _k--)
    {
        global.order_fx[_k].t--;
        if (global.order_fx[_k].t <= 0) array_delete(global.order_fx, _k, 1);
    }
    if (global.placing != "" && !global.teams[PLAYER].q_bld.ready) global.placing = "";
}

// ---------- Selection ----------

function sel_clean()
{
    for (var _k = array_length(global.sel) - 1; _k >= 0; _k--)
    {
        if (!instance_exists(global.sel[_k])) array_delete(global.sel, _k, 1);
    }
    if (global.sel_one != noone && !instance_exists(global.sel_one)) global.sel_one = noone;
}

function sel_set(_arr)
{
    with (obj_unit) selected = false;
    global.sel = _arr;
    for (var _k = 0; _k < array_length(_arr); _k++) _arr[_k].selected = true;
    if (array_length(_arr) > 0) global.sel_one = noone;
}

/// What is under the mouse: a unit (nearest within reach) or a structure, if the player can see it.
function entity_at(_wx, _wy)
{
    var _best = noone, _bd = 11;
    with (obj_unit)
    {
        var _d = point_distance(x, y, _wx, _wy) - radius * 0.5;
        if (_d < _bd && (team == PLAYER || seen(x, y))) { _bd = _d; _best = id; }
    }
    if (_best != noone) return _best;
    with (obj_building)
    {
        if (_wx >= x && _wy >= y && _wx < x + w * CELL && _wy < y + h * CELL && seen(_wx, _wy)) { _best = id; break; }
    }
    return _best;
}

function sel_has(_pred_type)
{
    for (var _k = 0; _k < array_length(global.sel); _k++)
    {
        var _u = global.sel[_k];
        if (_pred_type == "harvester" && _u.utype == "harvester") return true;
        if (_pred_type == "combat" && _u.utype != "harvester") return true;
    }
    return false;
}

// ---------- Orders ----------

function order_fx_add(_x, _y, _col)
{
    array_push(global.order_fx, { x: _x, y: _y, t: 24, col: _col });
}

function order_move(_units, _px, _py, _mode)
{
    var _tcx = clamp(cell_of(_px), 0, global.mw - 1), _tcy = clamp(cell_of(_py), 0, global.mh - 1);
    var _avoid = ds_map_create();
    for (var _k = 0; _k < array_length(_units); _k++)
    {
        var _u = _units[_k];
        var _c = nearest_free_cell(_tcx, _tcy, _u.kind, _avoid);
        _avoid[? _c[1] * global.mw + _c[0]] = 1;
        var _gx = _c[0] * CELL + HALF + ((_u.kind == "inf") ? random_range(-5, 5) : 0);
        var _gy = _c[1] * CELL + HALF + ((_u.kind == "inf") ? random_range(-5, 5) : 0);
        with (_u)
        {
            target = noone;
            if (utype == "harvester")
            {
                lumen_unclaim();
                harvester_undock();
                htask = "idle";
            }
            order = (_mode == "amove" && utype != "harvester") ? "amove" : "move";
            amove_x = _gx;
            amove_y = _gy;
            amove_resume = false;
            unit_path_to(_gx, _gy);
        }
    }
    ds_map_destroy(_avoid);
    order_fx_add(_px, _py, (_mode == "amove") ? c_red : c_lime);
}

function order_attack(_units, _target)
{
    var _movers = [];
    for (var _k = 0; _k < array_length(_units); _k++)
    {
        var _u = _units[_k];
        if (_u.def.dmg <= 0) { array_push(_movers, _u); continue; }
        with (_u)
        {
            order = "attack";
            target = _target;
            chase_t = 0;
        }
    }
    if (array_length(_movers) > 0) order_move(_movers, _target.x, _target.y, "move");
    order_fx_add(_target.x + ((_target.object_index == obj_building) ? _target.w * HALF : 0), _target.y + ((_target.object_index == obj_building) ? _target.h * HALF : 0), c_red);
}

function order_harvest(_units, _cx, _cy)
{
    var _others = [];
    for (var _k = 0; _k < array_length(_units); _k++)
    {
        var _u = _units[_k];
        if (_u.utype != "harvester") { array_push(_others, _u); continue; }
        with (_u)
        {
            harvester_undock();
            var _c = lumen_find(_cx, _cy, 5, id);
            if (_c != -1) harvester_dig_at(_c[0], _c[1]);
        }
    }
    if (array_length(_others) > 0) order_move(_others, _cx * CELL + HALF, _cy * CELL + HALF, "move");
    order_fx_add(_cx * CELL + HALF, _cy * CELL + HALF, c_aqua);
}

function order_return(_units, _ref)
{
    for (var _k = 0; _k < array_length(_units); _k++)
    {
        with (_units[_k])
        {
            if (utype != "harvester") continue;
            lumen_unclaim();
            if (cargo <= 0) cargo = 0;
            dock_ref = _ref;
            htask = "to_dock";
            unit_path_to(_ref.dock_x, _ref.dock_y);
        }
    }
}

function order_stop(_units)
{
    for (var _k = 0; _k < array_length(_units); _k++)
    {
        with (_units[_k])
        {
            unit_stop();
            if (utype == "harvester") { lumen_unclaim(); htask = "idle"; }
        }
    }
}

function order_retreat(_units)
{
    var _y = noone;
    with (obj_building) if (team == PLAYER && btype == "yard") _y = id;
    if (_y == noone) return;
    order_move(_units, _y.x + CELL, _y.y + 3 * CELL, "move");
}

/// Right-click in the world with units selected.
function order_context(_wx, _wy)
{
    var _h = entity_at(_wx, _wy);
    var _units = global.sel;
    if (_h != noone && _h.team != PLAYER)
    {
        order_attack(_units, _h);
        play("attack");
        return;
    }
    if (_h != noone && _h.object_index == obj_building && _h.btype == "refinery" && sel_has("harvester"))
    {
        order_return(_units, _h);
        play("ack");
        return;
    }
    var _cx = cell_of(_wx), _cy = cell_of(_wy);
    if (in_map(_cx, _cy) && global.lumen[# _cx, _cy] > 0 && sel_has("harvester"))
    {
        order_harvest(_units, _cx, _cy);
        play("ack");
        return;
    }
    order_move(_units, _wx, _wy, "move");
    play("ack");
}

// ---------- Mouse and keys while playing ----------

function cursor_world_x(_gx) { return global.cam_x + _gx / ZOOM; }
function cursor_world_y(_gy) { return global.cam_y + (_gy - TOP_H) / ZOOM; }

function play_input()
{
    var _gx = device_mouse_x_to_gui(0), _gy = device_mouse_y_to_gui(0);
    var _in_world = _gx < SIDE_X && _gy >= TOP_H && !global.paused;
    var _wx = cursor_world_x(_gx), _wy = cursor_world_y(_gy);
    global.mouse_wx = _wx;
    global.mouse_wy = _wy;
    global.hover = _in_world ? entity_at(_wx, _wy) : noone;
    var _shift = keyboard_check(vk_shift), _ctrl = keyboard_check(vk_control);
    sel_clean();

    // Camera: arrow keys, screen edges, middle-drag
    var _sp = 9;
    if (keyboard_check(vk_left)) global.cam_x -= _sp;
    if (keyboard_check(vk_right)) global.cam_x += _sp;
    if (keyboard_check(vk_up)) global.cam_y -= _sp;
    if (keyboard_check(vk_down)) global.cam_y += _sp;
    if (window_has_focus() && global.edge_scroll && !mouse_check_button(mb_left))
    {
        if (_gx < 4) global.cam_x -= _sp;
        if (_gx > GUI_W - 4) global.cam_x += _sp;
        if (_gy < 4) global.cam_y -= _sp;
        if (_gy > GUI_H - 4) global.cam_y += _sp;
    }
    if (mouse_check_button_pressed(mb_middle)) { global.pan = true; global.pan_x = _gx; global.pan_y = _gy; }
    if (global.pan)
    {
        global.cam_x -= (_gx - global.pan_x) / ZOOM;
        global.cam_y -= (_gy - global.pan_y) / ZOOM;
        global.pan_x = _gx;
        global.pan_y = _gy;
        if (!mouse_check_button(mb_middle)) global.pan = false;
    }
    cam_clamp();
    if (global.paused) return;

    // Keys
    if (keyboard_check_pressed(ord("S")) && array_length(global.sel) > 0) { order_stop(global.sel); play("ack"); }
    if (keyboard_check_pressed(ord("A")) && sel_has("combat")) global.cmd = "attack";
    if (keyboard_check_pressed(ord("R")) && array_length(global.sel) > 0) { order_retreat(global.sel); play("ack"); }
    if (keyboard_check_pressed(ord("H")))
    {
        with (obj_building) if (team == PLAYER && btype == "yard") cam_center(x + CELL, y + CELL);
    }
    if (keyboard_check_pressed(vk_space) && global.alert_x >= 0) cam_center(global.alert_x, global.alert_y);
    for (var _n = 1; _n <= 9; _n++)
    {
        if (!keyboard_check_pressed(ord(string(_n)))) continue;
        if (_ctrl) { global.groups[_n] = array_concat([], global.sel); msg("Group " + string(_n) + " set."); }
        else
        {
            var _g = [];
            for (var _k = 0; _k < array_length(global.groups[_n]); _k++) if (instance_exists(global.groups[_n][_k])) array_push(_g, global.groups[_n][_k]);
            global.groups[_n] = _g;
            if (array_length(_g) > 0)
            {
                if (global.last_group == _n && global.frame - global.last_group_t < 25) cam_center(_g[0].x, _g[0].y);
                sel_set(_g);
                play("select");
                global.last_group = _n;
                global.last_group_t = global.frame;
            }
        }
    }

    // Placing a structure
    if (global.placing != "")
    {
        var _d = global.bdef[$ global.placing];
        global.place_cx = cell_of(_wx - _d.w * HALF + HALF);
        global.place_cy = cell_of(_wy - _d.h * HALF + HALF);
        if (_in_world && mouse_check_button_pressed(mb_left))
        {
            if (can_place(PLAYER, global.placing, global.place_cx, global.place_cy))
            {
                place_building(PLAYER, global.placing, global.place_cx, global.place_cy, false);
                var _qb = global.teams[PLAYER].q_bld;
                _qb.item = "";
                _qb.ready = false;
                global.placing = "";
                play("place");
            }
            else
            {
                play("error");
                msg("Structures go on rock, close to your base, and clear of units.");
            }
        }
        if (mouse_check_button_pressed(mb_right) || keyboard_check_pressed(vk_escape)) global.placing = "";
        return;
    }

    // Attack-move mode (A)
    if (global.cmd == "attack")
    {
        if (_in_world && mouse_check_button_pressed(mb_left))
        {
            var _h = global.hover;
            if (_h != noone && _h.team != PLAYER) order_attack(global.sel, _h);
            else order_move(global.sel, _wx, _wy, "amove");
            play("attack");
            global.cmd = "";
            return;
        }
        if (mouse_check_button_pressed(mb_right) || keyboard_check_pressed(vk_escape) || array_length(global.sel) == 0) { global.cmd = ""; return; }
    }

    // Selecting
    if (_in_world && mouse_check_button_pressed(mb_left))
    {
        global.drag = true;
        global.drag_x = _gx;
        global.drag_y = _gy;
    }
    if (global.drag && mouse_check_button_released(mb_left))
    {
        global.drag = false;
        if (point_distance(_gx, _gy, global.drag_x, global.drag_y) < 6) select_click(global.hover, _shift);
        else select_box(cursor_world_x(global.drag_x), cursor_world_y(global.drag_y), _wx, _wy, _shift);
    }
    if (global.drag && !mouse_check_button(mb_left)) global.drag = false;

    // Orders
    if (_in_world && mouse_check_button_pressed(mb_right))
    {
        if (array_length(global.sel) > 0) order_context(_wx, _wy);
        else if (global.sel_one != noone && global.sel_one.team == PLAYER && (global.sel_one.btype == "barracks" || global.sel_one.btype == "factory"))
        {
            global.teams[PLAYER].rally[$ global.sel_one.btype] = [_wx, _wy];
            order_fx_add(_wx, _wy, c_lime);
            msg("Rally point set.");
            play("ack");
        }
    }
}

function select_click(_h, _shift)
{
    if (_h == noone)
    {
        if (!_shift) { sel_set([]); global.sel_one = noone; }
        return;
    }
    if (_h.object_index == obj_unit && _h.team == PLAYER)
    {
        if (global.frame - global.click_t < 20 && global.click_type == _h.utype)
        {
            var _all = [];
            with (obj_unit)
            {
                if (team == PLAYER && utype == _h.utype && on_screen(x, y, 0)) array_push(_all, id);
            }
            sel_set(_all);
        }
        else if (_shift)
        {
            var _arr = array_concat([], global.sel);
            var _i = array_get_index(_arr, _h);
            if (_i >= 0) array_delete(_arr, _i, 1); else array_push(_arr, _h);
            if (_i >= 0) _h.selected = false;
            sel_set(_arr);
        }
        else sel_set([_h]);
        global.click_t = global.frame;
        global.click_type = _h.utype;
    }
    else
    {
        sel_set([]);
        global.sel_one = _h;
    }
    play("select");
}

function select_box(_x1, _y1, _x2, _y2, _shift)
{
    var _l = min(_x1, _x2), _r = max(_x1, _x2), _t = min(_y1, _y2), _b = max(_y1, _y2);
    var _arr = _shift ? array_concat([], global.sel) : [];
    var _box = [], _combat = false;
    with (obj_unit)
    {
        if (team == PLAYER && x >= _l && x <= _r && y >= _t && y <= _b && array_get_index(_arr, id) < 0)
        {
            array_push(_box, id);
            if (utype != "harvester") _combat = true;
        }
    }
    // Harvesters only come along when nothing else is in the box
    for (var _k = 0; _k < array_length(_box); _k++) if (!_combat || _box[_k].utype != "harvester") array_push(_arr, _box[_k]);
    sel_set(_arr);
    if (array_length(_arr) > 0) play("select");
    else global.sel_one = noone;
}

// ---------- Self-test (only when the environment variable EMBERSAND_TEST is set) ----------
// Plays mission EMBERSAND_TEST (1-3) on its own at high speed, saving screenshots and a log next to the game, then quits.

function autotest_place(_type)
{
    var _y = noone;
    with (obj_building) if (team == PLAYER && btype == "yard") _y = id;
    if (_y == noone) return false;
    var _best = -1, _bd = 9999;
    for (var _i = _y.cx - 8; _i <= _y.cx + 8; _i++)
    {
        for (var _j = _y.cy - 8; _j <= _y.cy + 8; _j++)
        {
            if (!can_place(PLAYER, _type, _i, _j)) continue;
            var _d = point_distance(_i, _j, _y.cx, _y.cy) + random(1);
            if (_d < _bd) { _bd = _d; _best = [_i, _j]; }
        }
    }
    if (_best == -1) return false;
    place_building(PLAYER, _type, _best[0], _best[1], false);
    return true;
}

function autotest_log(_s)
{
    var _f = file_text_open_append(global.test_dir + "autotest_log.txt");
    file_text_write_string(_f, string(global.frame) + ": " + _s);
    file_text_writeln(_f);
    file_text_close(_f);
}

function autotest_step()
{
    global.test_t++;
    var _t = global.test_t;
    if (_t == 10) autotest_log("tm w=" + string(tilemap_get_width(global.tm_terrain)) + " t55=" + string(tilemap_get(global.tm_terrain, 5, 5)) + " ts=" + string(tilemap_get_tileset(global.tm_terrain)) + " vis=" + string(layer_get_visible(global.lay_terrain)) + " depth=" + string(layer_get_depth(global.lay_terrain)) + " tsinfo=" + json_stringify(tileset_get_info(ts_terrain)));
    if (_t == 1) { global.state = "brief"; global.brief_index = global.test_mission; global.brief_chars = 9999; }
    if (_t == 3) { game_set_speed(240, gamespeed_fps); mission_start(global.test_mission); global.test_order = ["power", "refinery", "barracks", "power", "factory", "gun", "gun", "radar", "power", "rocket"]; }
    if (global.state != "play" && global.state != "end") return;
    if (global.state == "end")
    {
        if (global.test_shot > -2) { autotest_log("END " + global.result); global.test_shot = -2; global.test_end = global.test_t; }
        if (global.test_t > global.test_end + 5) game_end();
        return;
    }
    var _tm = global.teams[PLAYER];
    _tm.credits += 0.4; // a little help so the test reaches the late game
    var _qb = _tm.q_bld;
    if (_qb.ready)
    {
        if (autotest_place(_qb.item)) { _qb.item = ""; _qb.ready = false; }
    }
    else if (_qb.item == "" && array_length(global.test_order) > 0)
    {
        if (queue_add(PLAYER, global.test_order[0]) || def_of(global.test_order[0]).tech > global.tech) array_delete(global.test_order, 0, 1);
    }
    if (array_length(_tm.q_veh.list) == 0) queue_add(PLAYER, choose("tank", "buggy", "launcher", "heavy"));
    if (array_length(_tm.q_inf.list) == 0) queue_add(PLAYER, choose("trooper", "rocketeer"));
    if (global.frame mod 600 == 0)
    {
        var _s = "";
        for (var _k = 0; _k < array_length(global.teams); _k++)
        {
            var _x = global.teams[_k];
            _s += _x.name + " cr=" + string(floor(_x.credits)) + " harv=" + string(_x.harvested) + " units=" + string(_x.units) + " bld=" + string(_x.buildings) + " pow=" + string(_x.power_made) + "/" + string(_x.power_used) + " | ";
        }
        autotest_log(_s + " objs u=" + string(instance_number(obj_unit)) + " p=" + string(instance_number(obj_proj)) + " fps=" + string(fps_real));
    }
    // Exercise the player's controls and screens
    var _f = global.frame;
    if (_f == 2000) { var _hv = noone; with (obj_unit) if (team == PLAYER && utype == "harvester") _hv = id; if (_hv != noone) { select_click(_hv, false); autotest_log("selected harvester"); } }
    if (_f == 2010 && array_length(global.sel) > 0)
    {
        var _lc = lumen_find(cell_of(global.sel[0].x), cell_of(global.sel[0].y), 30, noone);
        if (_lc != -1) { order_context(_lc[0] * CELL + HALF, _lc[1] * CELL + HALF); autotest_log("harvest order"); }
    }
    if (_f == 2100) { var _yd = noone; with (obj_building) if (team == PLAYER && btype == "yard") _yd = id; select_box(_yd.x - 300, _yd.y - 300, _yd.x + 300, _yd.y + 300, false); autotest_log("box " + string(array_length(global.sel))); }
    if (_f == 2110 && array_length(global.sel) > 0) { order_context(global.sel[0].x + 64, global.sel[0].y - 64); global.cmd = "attack"; }
    if (_f == 2120) { global.cmd = ""; var _en = noone; with (obj_building) if (team != PLAYER) _en = id; if (_en != noone) { global.sel_one = _en; sel_set([]); } }
    if (_f == 2130) { var _ob = noone; with (obj_building) if (team == PLAYER && btype == "barracks") _ob = id; if (_ob != noone) { global.sel_one = _ob; _ob.repairing = true; global.teams[PLAYER].rally.barracks = [_ob.x, _ob.y + 160]; } }
    if (_f == 2140) { global.placing = "wall"; global.place_cx = cell_of(global.cam_x) + 5; global.place_cy = cell_of(global.cam_y) + 5; }
    if (_f == 2150) global.placing = "";
    if (_f == 2160) global.groups[1] = array_concat([], global.sel);
    if (_f == 2200 && global.test_pause_t == 0) { global.paused = true; global.test_pause_t = global.test_t; autotest_log("paused"); }
    if (global.paused && global.test_t > global.test_pause_t + 20) { global.paused = false; autotest_log("resumed"); }

    // Send the army every two minutes
    if (global.frame mod 7200 == 3600)
    {
        var _army = [];
        with (obj_unit) if (team == PLAYER && utype != "harvester") { array_push(_army, id); ai_role = "test"; }
        var _e = global.mission.enemies[0];
        if (array_length(_army) > 0) order_move(_army, _e.cx * CELL, _e.cy * CELL, "amove");
        autotest_log("attack with " + string(array_length(_army)));
    }
    if (global.frame mod 600 == 300)
    {
        var _st = {};
        with (obj_unit) if (team == PLAYER && ai_role == "test") { var _k = order + (moving ? "+mv" : "") + ((target != noone) ? "+tg" : ""); _st[$ _k] = (_st[$ _k] ?? 0) + 1; }
        autotest_log("army " + json_stringify(_st));
    }
    // Screenshots: the base, and wherever the action is
    var _shots = [60, 1500, 3000, 4500, 8000, 11500, 16000, 19000];
    var _i = array_get_index(_shots, global.frame);
    if (_i >= 0)
    {
        var _ax = 0, _ay = 0, _an = 0;
        with (obj_unit) if (team == PLAYER && utype != "harvester" && ai_role == "test") { _ax += x; _ay += y; _an++; }
        if (_i mod 2 == 1 && _an > 0) cam_center(_ax / _an, _ay / _an);
        else cam_center(global.mission.player.cx * CELL + CELL, global.mission.player.cy * CELL);
        global.test_shot = global.frame + 2;
        global.tab = _i mod 3;
        if (_i >= 2) with (obj_unit) if (team == PLAYER) { global.sel = [id]; selected = true; break; }
    }
    if (global.frame >= global.test_frames) { autotest_log("TIMEOUT"); game_end(); }
}

/// Draws the whole frame (world and GUI) into a surface and saves it; called from Draw GUI on test frames.
function autotest_capture(_name)
{
    var _s = surface_create(GUI_W, GUI_H);
    surface_set_target(_s);
    draw_clear(c_black);
    draw_surface_ext(application_surface, 0, TOP_H, ZOOM, ZOOM, 0, c_white, 1);
    ui_topbar();
    ui_sidebar();
    if (global.state == "end") { global.end_t = 200; ui_end(); }
    surface_reset_target();
    surface_save(_s, global.test_dir + _name);
    surface_free(_s);
}
