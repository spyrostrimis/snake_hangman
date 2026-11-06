/// Everything drawn on the GUI layer (1280 x 720): title, briefing, sidebar, minimap, menus. Buttons are immediate-mode.

#macro UI_BG make_colour_rgb(30, 27, 25)
#macro UI_EDGE make_colour_rgb(92, 82, 70)
#macro UI_HI make_colour_rgb(150, 136, 112)
#macro UI_AMBER make_colour_rgb(240, 170, 60)
#macro UI_TEXT make_colour_rgb(236, 228, 210)
#macro UI_DIM make_colour_rgb(150, 140, 124)
#macro MM_X 1032
#macro MM_Y 36
#macro MM_S 240
#macro TAB_Y 284
#macro ICON_Y 318
#macro INFO_Y 602

function ui_text(_x, _y, _s, _col, _font, _ha = fa_left, _va = fa_top, _alpha = 1)
{
    draw_set_font(_font);
    draw_set_halign(_ha);
    draw_set_valign(_va);
    draw_set_alpha(_alpha);
    draw_set_colour(c_black);
    draw_text(_x + 1, _y + 1, _s);
    draw_set_colour(_col);
    draw_text(_x, _y, _s);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_panel(_x1, _y1, _x2, _y2, _alpha = 1)
{
    draw_set_alpha(_alpha);
    draw_rectangle_colour(_x1, _y1, _x2, _y2, UI_BG, UI_BG, make_colour_rgb(20, 18, 17), make_colour_rgb(20, 18, 17), false);
    draw_set_alpha(1);
    draw_set_colour(UI_EDGE);
    draw_rectangle(_x1, _y1, _x2, _y2, true);
    draw_set_colour(make_colour_rgb(60, 54, 48));
    draw_rectangle(_x1 + 2, _y1 + 2, _x2 - 2, _y2 - 2, true);
    draw_set_colour(UI_HI);
    var _r = [[_x1 + 5, _y1 + 5], [_x2 - 5, _y1 + 5], [_x1 + 5, _y2 - 5], [_x2 - 5, _y2 - 5]];
    if (_x2 - _x1 > 40 && _y2 - _y1 > 30) for (var _k = 0; _k < 4; _k++) draw_circle(_r[_k][0], _r[_k][1], 1.5, false);
    draw_set_colour(c_white);
}

function ui_hover(_x, _y, _w, _h)
{
    return point_in_rectangle(global.gx, global.gy, _x, _y, _x + _w - 1, _y + _h - 1);
}

/// Draws a button and returns true on the frame it is clicked.
function ui_button(_x, _y, _w, _h, _label, _enabled = true, _on = false)
{
    var _hov = _enabled && ui_hover(_x, _y, _w, _h);
    var _top = _on ? make_colour_rgb(120, 82, 30) : (_hov ? make_colour_rgb(74, 66, 56) : make_colour_rgb(52, 47, 42));
    var _bot = _on ? make_colour_rgb(80, 52, 18) : make_colour_rgb(34, 31, 28);
    draw_rectangle_colour(_x, _y, _x + _w, _y + _h, _top, _top, _bot, _bot, false);
    draw_set_colour(_on ? UI_AMBER : (_hov ? UI_HI : UI_EDGE));
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_colour(c_white);
    ui_text(_x + _w / 2, _y + _h / 2, _label, _enabled ? (_on ? c_white : UI_TEXT) : make_colour_rgb(90, 84, 76), (_h >= 36) ? global.f_ui : global.f_small, fa_center, fa_middle);
    if (_hov && mouse_check_button_pressed(mb_left))
    {
        play("click");
        global.ui_clicked = true;
        return true;
    }
    return false;
}

function ui_bar(_x, _y, _w, _h, _frac, _col)
{
    draw_set_colour(c_black);
    draw_rectangle(_x - 1, _y - 1, _x + _w, _y + _h, false);
    draw_set_colour(_col);
    if (_frac > 0) draw_rectangle(_x, _y, _x + max(1, (_w - 1) * clamp(_frac, 0, 1)), _y + _h - 1, false);
    draw_set_colour(c_white);
}

function hp_colour(_f)
{
    return (_f > 0.6) ? make_colour_rgb(90, 220, 80) : ((_f > 0.3) ? make_colour_rgb(240, 200, 60) : make_colour_rgb(230, 60, 40));
}

function fmt_num(_n)
{
    _n = floor(_n);
    var _s = string(_n);
    if (_n >= 1000) _s = string(_n div 1000) + "," + string_replace_all(string_format(_n mod 1000, 3, 0), " ", "0");
    return _s;
}

// ---------- Window ----------

#macro WIN_SIZES [[1280, 720], [1600, 900], [1920, 1080], [2560, 1440]]

/// Steps the window through a few 16:9 sizes that fit on this display.
function window_next_size()
{
    if (window_get_fullscreen()) { window_set_fullscreen(false); return; }
    var _sizes = WIN_SIZES;
    for (var _k = 0; _k < array_length(_sizes); _k++)
    {
        global.win_i = (global.win_i + 1) mod array_length(_sizes);
        var _w = _sizes[global.win_i][0], _h = _sizes[global.win_i][1];
        if (_w <= display_get_width() && _h <= display_get_height() - 60) break;
    }
    window_set_size(_sizes[global.win_i][0], _sizes[global.win_i][1]);
    global.recentre = 3;
}

function window_size_label()
{
    if (window_get_fullscreen()) return "Window: full screen";
    return "Window: " + string(window_get_width()) + " x " + string(window_get_height());
}

// ---------- Title ----------

function ui_title()
{
    draw_sprite(spr_title_bg, 0, 0, 0);
    draw_set_font(global.f_logo);
    draw_set_halign(fa_center);
    draw_set_colour(c_black);
    draw_set_alpha(0.6);
    draw_text(646, 66, "EMBERSAND");
    draw_set_alpha(1);
    draw_text_colour(640, 60, "EMBERSAND", make_colour_rgb(255, 236, 170), make_colour_rgb(255, 236, 170), make_colour_rgb(240, 120, 40), make_colour_rgb(240, 120, 40), 1);
    draw_set_halign(fa_left);
    ui_text(640, 158, "A DESERT STRATEGY GAME", UI_TEXT, global.f_ui, fa_center);

    ui_panel(420, 210, 860, 650, 0.9);
    ui_text(440, 224, "YOUR SIDE", UI_AMBER, global.f_small);
    for (var _s = 0; _s < 2; _s++)
    {
        var _bx = 440 + _s * 205;
        if (ui_button(_bx, 244, 195, 40, global.sides[_s].name, true, global.player_side == _s)) global.player_side = _s;
        draw_set_colour(global.sides[_s].col);
        draw_rectangle(_bx + 6, 250, _bx + 14, 278, false);
        draw_set_colour(c_white);
    }
    ui_text(440, 298, "DIFFICULTY", UI_AMBER, global.f_small);
    for (var _d = 0; _d < 3; _d++)
    {
        if (ui_button(440 + _d * 137, 318, 127, 34, global.difficulties[_d], true, global.difficulty == _d)) global.difficulty = _d;
    }
    ui_text(440, 368, "MISSIONS", UI_AMBER, global.f_small);
    for (var _m = 0; _m < array_length(global.missions); _m++)
    {
        var _lab = string(_m + 1) + ".  " + string_upper(global.missions[_m].title) + (global.done[_m] ? "   (done)" : "");
        if (ui_button(440, 388 + _m * 54, 400, 44, _lab))
        {
            global.brief_index = _m;
            global.brief_chars = 0;
            global.state = "brief";
            global.ui_t = 0;
        }
    }
    if (ui_button(440, 560, 127, 34, global.sound_off ? "Sound: off" : "Sound: on")) global.sound_off = !global.sound_off;
    if (ui_button(577, 560, 263, 34, global.edge_scroll ? "Edge scrolling: on" : "Edge scrolling: off")) global.edge_scroll = !global.edge_scroll;
    if (ui_button(440, 604, 127, 34, window_get_fullscreen() ? "Windowed" : "Full screen")) window_set_fullscreen(!window_get_fullscreen());
    if (ui_button(577, 604, 168, 34, window_size_label())) window_next_size();
    if (ui_button(755, 604, 85, 34, "Quit")) game_end();
    ui_text(640, 690, "An original tribute to the desert strategy games of the early 90s, made with GameMaker.", UI_TEXT, global.f_small, fa_center, fa_top, 0.8);
}

// ---------- Briefing ----------

function brief_text(_m)
{
    var _other = global.sides[1 - global.player_side].name;
    return string_replace_all(_m.brief, "{other}", _other);
}

function ui_brief()
{
    var _m = global.missions[global.brief_index];
    draw_rectangle_colour(0, 0, GUI_W, GUI_H, make_colour_rgb(24, 20, 28), make_colour_rgb(24, 20, 28), make_colour_rgb(10, 8, 12), make_colour_rgb(10, 8, 12), false);
    ui_panel(30, 40, 290, 340);
    draw_sprite(spr_advisor, ((global.ui_t mod 190) < 7) ? 1 : 0, 40, 50);
    ui_text(160, 300, "K-7  FIELD ADVISOR", UI_AMBER, global.f_small, fa_center);
    ui_text(160, 318, "talking...", UI_DIM, global.f_small, fa_center, fa_top, (global.brief_chars < string_length(brief_text(_m))) ? 0.5 + 0.5 * sin(global.ui_t / 6) : 0);
    ui_panel(300, 40, 790, 320);
    draw_sprite(spr_mission_pic, global.brief_index, 305, 45);
    ui_panel(800, 40, 1250, 340);
    ui_text(820, 54, "MISSION " + string(global.brief_index + 1), UI_AMBER, global.f_small);
    ui_text(820, 72, string_upper(_m.title), UI_TEXT, global.f_big);
    ui_text(820, 118, "OBJECTIVE", UI_AMBER, global.f_small);
    draw_set_font(global.f_ui);
    draw_set_colour(UI_TEXT);
    draw_text_ext(820, 136, _m.objective, 22, 410);
    ui_text(820, 196, "NEW EQUIPMENT", UI_AMBER, global.f_small);
    draw_set_font(global.f_small);
    draw_set_colour(UI_TEXT);
    draw_text_ext(820, 214, _m.unlocks, 18, 410);
    ui_text(820, 286, "YOU COMMAND", UI_AMBER, global.f_small);
    draw_set_colour(global.sides[global.player_side].col);
    draw_rectangle(820, 306, 830, 322, false);
    ui_text(838, 304, global.sides[global.player_side].name + "   (" + global.difficulties[global.difficulty] + ")", UI_TEXT, global.f_small);

    ui_panel(30, 352, 1250, 620);
    var _full = brief_text(_m);
    global.brief_chars = min(string_length(_full), global.brief_chars + 1.4);
    draw_set_font(global.f_ui);
    draw_set_colour(UI_TEXT);
    draw_text_ext(56, 372, string_copy(_full, 1, floor(global.brief_chars)), 26, 1170);
    if (ui_hover(30, 352, 1220, 268) && mouse_check_button_pressed(mb_left)) global.brief_chars = string_length(_full);
    if (ui_button(30, 640, 180, 50, "Back")) global.state = "title";
    if (ui_button(1030, 640, 220, 50, "Start mission") || keyboard_check_pressed(vk_enter)) mission_start(global.brief_index);
}

// ---------- Minimap ----------

function minimap_update()
{
    var _w = global.mw, _h = global.mh;
    if (!surface_exists(global.mm_base)) { global.mm_base = surface_create(_w, _h); global.minimap_dirty = true; }
    if (!surface_exists(global.mm_surf)) global.mm_surf = surface_create(_w, _h);
    if (global.minimap_dirty && global.frame mod 20 == 0)
    {
        global.minimap_dirty = false;
        surface_set_target(global.mm_base);
        draw_clear(c_black);
        var _sand = make_colour_rgb(206, 148, 90), _rock = make_colour_rgb(92, 82, 76), _crag = make_colour_rgb(58, 50, 46), _lum = make_colour_rgb(70, 210, 230);
        for (var _i = 0; _i < _w; _i++)
        {
            for (var _j = 0; _j < _h; _j++)
            {
                if (!global.shroud[# _i, _j]) continue;
                var _t = global.terr[# _i, _j];
                var _c = (_t == T_SAND) ? ((global.lumen[# _i, _j] > 0 || global.isvent[# _i, _j]) ? _lum : _sand) : ((_t == T_CRAG) ? _crag : _rock);
                draw_point_colour(_i, _j, _c);
            }
        }
        surface_reset_target();
    }
    if (global.frame mod 6 != 0) return;
    surface_set_target(global.mm_surf);
    draw_surface(global.mm_base, 0, 0);
    with (obj_building)
    {
        if (team != PLAYER && !seen(x + HALF, y + HALF)) continue;
        draw_set_colour(merge_colour(global.teams[team].col, c_white, 0.25));
        draw_rectangle(cx, cy, cx + w - 1, cy + h - 1, false);
    }
    with (obj_unit)
    {
        if (team != PLAYER && !seen(x, y)) continue;
        draw_point_colour(cell_of(x), cell_of(y), global.teams[team].col);
    }
    draw_set_colour(c_white);
    surface_reset_target();
}

function ui_minimap()
{
    var _on = has(PLAYER, "radar") && !global.teams[PLAYER].power_low;
    draw_set_colour(c_black);
    draw_rectangle(MM_X, MM_Y, MM_X + MM_S, MM_Y + MM_S, false);
    var _s = MM_S / max(global.mw, global.mh);
    var _ox = MM_X + (MM_S - global.mw * _s) / 2, _oy = MM_Y + (MM_S - global.mh * _s) / 2;
    if (_on)
    {
        minimap_update();
        if (surface_exists(global.mm_surf)) draw_surface_ext(global.mm_surf, _ox, _oy, _s, _s, 0, c_white, 1);
        draw_set_colour(c_white);
        draw_rectangle(_ox + global.cam_x / CELL * _s, _oy + global.cam_y / CELL * _s, _ox + (global.cam_x + VIEW_W) / CELL * _s, _oy + (global.cam_y + VIEW_H) / CELL * _s, true);
        if (ui_hover(MM_X, MM_Y, MM_S, MM_S))
        {
            var _mx = (global.gx - _ox) / _s * CELL, _my = (global.gy - _oy) / _s * CELL;
            if (mouse_check_button(mb_left) && !global.drag) cam_center(_mx, _my);
            if (mouse_check_button_pressed(mb_right) && array_length(global.sel) > 0) { order_move(global.sel, _mx, _my, "move"); play("ack"); }
        }
    }
    else
    {
        // Static
        random_set_seed(global.ui_t div 3);
        for (var _k = 0; _k < 260; _k++)
        {
            var _g = irandom(60);
            draw_set_colour(make_colour_rgb(_g, _g, _g + 6));
            var _px = MM_X + irandom(MM_S - 4), _py = MM_Y + irandom(MM_S - 4);
            draw_rectangle(_px, _py, _px + 3, _py + 2, false);
        }
        randomize();
        ui_text(MM_X + MM_S / 2, MM_Y + MM_S / 2 - 10, has(PLAYER, "radar") ? "RADAR OFFLINE" : "NO RADAR", UI_DIM, global.f_ui, fa_center, fa_middle);
        ui_text(MM_X + MM_S / 2, MM_Y + MM_S / 2 + 12, has(PLAYER, "radar") ? "Not enough power" : ((global.tech >= 2) ? "Build a Radar Post" : ""), UI_DIM, global.f_small, fa_center, fa_middle);
    }
    draw_set_colour(UI_EDGE);
    draw_rectangle(MM_X - 1, MM_Y - 1, MM_X + MM_S + 1, MM_Y + MM_S + 1, true);
    draw_set_colour(c_white);
}

// ---------- Sidebar ----------

function tab_list(_tab)
{
    var _src = (_tab == 0) ? global.build_list : ((_tab == 1) ? global.inf_list : global.veh_list);
    var _out = [];
    for (var _k = 0; _k < array_length(_src); _k++)
    {
        if (can_build(PLAYER, _src[_k]) || queue_count(PLAYER, _src[_k]) > 0) array_push(_out, _src[_k]);
    }
    return _out;
}

function ui_sidebar()
{
    var _tm = global.teams[PLAYER];
    sel_clean();
    ui_panel(SIDE_X, TOP_H, GUI_W - 1, GUI_H - 1);
    ui_minimap();

    // Tabs
    var _names = ["STRUCTURES", "INFANTRY", "VEHICLES"];
    var _qs = [_tm.q_bld, _tm.q_inf, _tm.q_veh];
    for (var _t = 0; _t < 3; _t++)
    {
        var _tx = MM_X + _t * 81;
        var _busy = (_t == 0) ? (_tm.q_bld.item != "") : (array_length(_qs[_t].list) > 0);
        var _lab = _names[_t];
        if (_t == 0 && _tm.q_bld.ready && (global.ui_t div 15) mod 2 == 0) _lab = "READY!";
        if (ui_button(_tx, TAB_Y, 77, 26, _lab, true, global.tab == _t)) global.tab = _t;
        if (_busy) ui_bar(_tx + 4, TAB_Y + 22, 69, 2, _qs[_t].prog, UI_AMBER);
    }

    // Build icons
    var _list = tab_list(global.tab);
    global.tip = "";
    for (var _k = 0; _k < 8; _k++)
    {
        var _ix = MM_X + (_k mod 2) * 124, _iy = ICON_Y + (_k div 2) * 70;
        if (_k >= array_length(_list))
        {
            draw_set_colour(make_colour_rgb(22, 20, 18));
            draw_rectangle(_ix, _iy, _ix + 115, _iy + 63, false);
            draw_set_colour(make_colour_rgb(50, 45, 40));
            draw_rectangle(_ix, _iy, _ix + 115, _iy + 63, true);
            continue;
        }
        var _type = _list[_k];
        var _d = def_of(_type);
        var _q = queue_of(PLAYER, _type);
        var _is_bld = variable_struct_exists(global.bdef, _type);
        var _active = _is_bld ? (_q.item == _type) : (array_length(_q.list) > 0 && _q.list[0] == _type);
        var _blocked = _is_bld && _q.item != "" && _q.item != _type;
        var _ok = can_build(PLAYER, _type);
        team_shader(PLAYER);
        draw_sprite_ext(spr_cameo, _d.cameo, _ix, _iy, 1, 1, 0, (_ok && !_blocked) ? c_white : c_gray, 1);
        shader_reset();
        draw_set_alpha(0.65);
        draw_set_colour(c_black);
        draw_rectangle(_ix, _iy + 48, _ix + 115, _iy + 63, false);
        draw_set_alpha(1);
        ui_text(_ix + 4, _iy + 49, _d.name, UI_TEXT, global.f_small);
        ui_text(_ix + 112, _iy + 2, string(_d.cost), UI_AMBER, global.f_small, fa_right);
        if (_active)
        {
            if (_is_bld && _q.ready)
            {
                if ((global.ui_t div 12) mod 2 == 0) ui_text(_ix + 58, _iy + 24, "READY", c_white, global.f_ui, fa_center, fa_middle);
                draw_set_colour(UI_AMBER);
                draw_rectangle(_ix, _iy, _ix + 115, _iy + 63, true);
            }
            else
            {
                draw_set_alpha(0.6);
                draw_set_colour(c_black);
                draw_rectangle(_ix + 116 * _q.prog, _iy, _ix + 115, _iy + 47, false);
                draw_set_alpha(1);
                ui_text(_ix + 58, _iy + 24, _q.stalled ? "NEED CREDITS" : (string(floor(_q.prog * 100)) + "%"), _q.stalled ? make_colour_rgb(255, 120, 90) : c_white, global.f_ui, fa_center, fa_middle);
            }
        }
        var _n = queue_count(PLAYER, _type);
        if (!_is_bld && _n > 1) ui_text(_ix + 6, _iy + 4, "x" + string(_n), c_white, global.f_ui);
        draw_set_colour(UI_EDGE);
        if (!_active) draw_rectangle(_ix, _iy, _ix + 115, _iy + 63, true);
        draw_set_colour(c_white);
        if (ui_hover(_ix, _iy, 116, 64))
        {
            global.tip = _type;
            draw_set_colour(c_white);
            draw_rectangle(_ix, _iy, _ix + 115, _iy + 63, true);
            if (mouse_check_button_pressed(mb_left))
            {
                global.ui_clicked = true;
                if (_is_bld)
                {
                    if (_q.item == _type && _q.ready) { global.placing = _type; global.cmd = ""; play("click"); }
                    else if (_q.item == "")
                    {
                        if (queue_add(PLAYER, _type)) { play("click"); msg("Building " + _d.name + "."); } else play("error");
                    }
                    else play("error");
                }
                else if (queue_add(PLAYER, _type)) play("click"); else play("error");
            }
            if (mouse_check_button_pressed(mb_right))
            {
                global.ui_clicked = true;
                if (queue_cancel(PLAYER, _type)) { play("click"); if (global.placing == _type) global.placing = ""; }
            }
        }
    }
    ui_info();
}

function ui_info()
{
    var _x = MM_X, _y = INFO_Y, _w = 240;
    draw_set_colour(make_colour_rgb(22, 20, 18));
    draw_rectangle(_x, _y, _x + _w, _y + 108, false);
    draw_set_colour(UI_EDGE);
    draw_rectangle(_x, _y, _x + _w, _y + 108, true);
    draw_set_colour(c_white);
    if (global.tip != "")
    {
        var _d = def_of(global.tip);
        ui_text(_x + 8, _y + 6, _d.name, UI_AMBER, global.f_ui);
        var _line = "Cost " + string(_d.cost);
        if (variable_struct_exists(_d, "power") && _d.power != 0) _line += "    Power " + ((_d.power > 0) ? "+" : "") + string(_d.power);
        ui_text(_x + 8, _y + 28, _line, UI_TEXT, global.f_small);
        draw_set_font(global.f_small);
        draw_set_colour(UI_DIM);
        draw_text_ext(_x + 8, _y + 46, _d.desc, 16, _w - 16);
        ui_text(_x + 8, _y + 90, "Left: build   Right: cancel", make_colour_rgb(110, 102, 90), global.f_small);
        return;
    }
    var _n = array_length(global.sel);
    if (_n == 1 || (_n == 0 && global.sel_one != noone))
    {
        var _e = (_n == 1) ? global.sel[0] : global.sel_one;
        var _own = _e.team == PLAYER;
        ui_text(_x + 8, _y + 6, _e.def.name, _own ? UI_AMBER : global.teams[_e.team].col, global.f_ui);
        if (!_own) ui_text(_x + _w - 8, _y + 8, global.teams[_e.team].name, UI_DIM, global.f_small, fa_right);
        ui_bar(_x + 8, _y + 30, 160, 8, _e.hp / _e.maxhp, hp_colour(_e.hp / _e.maxhp));
        ui_text(_x + 176, _y + 26, string(ceil(_e.hp)) + "/" + string(_e.maxhp), UI_DIM, global.f_small);
        if (_own && _e.object_index == obj_unit && _e.utype == "harvester")
        {
            ui_bar(_x + 8, _y + 44, 160, 5, _e.cargo / HARV_CAP, make_colour_rgb(90, 230, 250));
            ui_text(_x + 176, _y + 39, string(floor(_e.cargo / HARV_CAP * 100)) + "% full", UI_DIM, global.f_small);
        }
        if (_own && _e.object_index == obj_building)
        {
            if (_e.btype == "barracks" || _e.btype == "factory") ui_text(_x + 8, _y + 50, "Right-click the map: rally point", UI_DIM, global.f_small);
            if (ui_button(_x + 8, _y + 70, 108, 30, _e.repairing ? "Repairing..." : "Repair", _e.hp < _e.maxhp, _e.repairing)) _e.repairing = !_e.repairing;
            if (ui_button(_x + 124, _y + 70, 108, 30, "Sell (" + string(floor(_e.def.cost * 0.5 * _e.hp / _e.maxhp)) + ")"))
            {
                // Selling destroys the structure, so nothing below may touch _e any more.
                global.sel_one = noone;
                building_sell(_e);
            }
            return;
        }
        if (_own && _e.object_index == obj_unit) ui_unit_buttons(_x, _y);
        return;
    }
    if (_n > 1)
    {
        ui_text(_x + 8, _y + 6, string(_n) + " units selected", UI_AMBER, global.f_ui);
        var _hp = 0, _max = 0;
        for (var _k = 0; _k < _n; _k++) { _hp += global.sel[_k].hp; _max += global.sel[_k].maxhp; }
        ui_bar(_x + 8, _y + 30, 160, 8, _hp / _max, hp_colour(_hp / _max));
        ui_unit_buttons(_x, _y);
        return;
    }
    var _tm = global.teams[PLAYER];
    ui_text(_x + 8, _y + 6, "COMMANDER", UI_AMBER, global.f_small);
    draw_set_font(global.f_small);
    draw_set_colour(UI_DIM);
    draw_text_ext(_x + 8, _y + 24, "Drag to select. Right-click to move, attack or harvest. A: attack-move, S: stop, R: retreat, Ctrl+1-9: groups, H: home, Space: last alert.", 16, _w - 16);
}

function ui_unit_buttons(_x, _y)
{
    if (ui_button(_x + 8, _y + 70, 70, 30, "Stop")) order_stop(global.sel);
    if (ui_button(_x + 85, _y + 70, 70, 30, "Attack", sel_has("combat"), global.cmd == "attack")) global.cmd = (global.cmd == "attack") ? "" : "attack";
    if (sel_has("harvester") && !sel_has("combat"))
    {
        if (ui_button(_x + 162, _y + 70, 70, 30, "Return"))
        {
            var _r = nearest_refinery(PLAYER, global.sel[0].x, global.sel[0].y);
            if (_r != noone) order_return(global.sel, _r);
        }
    }
    else if (ui_button(_x + 162, _y + 70, 70, 30, "Retreat")) order_retreat(global.sel);
}

function ui_topbar()
{
    var _tm = global.teams[PLAYER];
    ui_panel(0, 0, GUI_W - 1, TOP_H - 1);
    ui_text(10, 5, "CREDITS", UI_DIM, global.f_small);
    var _s = fmt_num(_tm.shown);
    if (global.mission.goal == "credits") _s += " / " + fmt_num(global.mission.goal_amount);
    ui_text(70, 3, _s, UI_AMBER, global.f_ui);
    if (global.message_t > 0) ui_text(SIDE_X / 2 + 60, 4, global.message, UI_TEXT, global.f_ui, fa_center, fa_top, min(1, global.message_t / 30));
    var _pc = _tm.power_low ? make_colour_rgb(255, 90, 60) : make_colour_rgb(120, 220, 110);
    ui_text(SIDE_X + 8, 5, "POWER", UI_DIM, global.f_small);
    ui_text(SIDE_X + 58, 3, string(_tm.power_made) + " / " + string(_tm.power_used), _pc, global.f_ui);
    if (ui_button(GUI_W - 70, 3, 64, 21, "Menu")) global.paused = true;
}

// ---------- Overlays ----------

function ui_pause()
{
    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, GUI_W, GUI_H, false);
    draw_set_alpha(1);
    ui_panel(460, 160, 820, 610);
    ui_text(640, 176, "PAUSED", UI_AMBER, global.f_big, fa_center);
    if (ui_button(490, 250, 300, 40, "Resume") || keyboard_check_pressed(vk_escape)) { global.paused = false; return; }
    var _sp = ["Slow", "Normal", "Fast"];
    if (ui_button(490, 300, 300, 40, "Game speed: " + _sp[global.speed_i]))
    {
        global.speed_i = (global.speed_i + 1) mod 3;
        game_set_speed([42, 60, 84][global.speed_i], gamespeed_fps);
    }
    if (ui_button(490, 350, 145, 40, global.sound_off ? "Sound: off" : "Sound: on")) global.sound_off = !global.sound_off;
    if (ui_button(645, 350, 145, 40, window_get_fullscreen() ? "Windowed" : "Full screen")) window_set_fullscreen(!window_get_fullscreen());
    if (ui_button(490, 400, 300, 40, window_size_label())) window_next_size();
    if (ui_button(490, 450, 300, 40, "Restart mission")) { mission_start(global.mission_index); return; }
    if (ui_button(490, 500, 300, 40, "Quit to title")) { mission_clear(); global.paused = false; global.state = "title"; return; }
    ui_text(640, 560, "Mission " + string(global.mission_index + 1) + ": " + global.mission.objective, UI_DIM, global.f_small, fa_center);
}

function ui_end()
{
    global.end_t++;
    draw_set_alpha(min(0.6, global.end_t / 60));
    draw_set_colour(c_black);
    draw_rectangle(0, 0, GUI_W, GUI_H, false);
    draw_set_alpha(1);
    if (global.end_t < 40) return;
    var _won = global.result == "win";
    ui_panel(400, 150, 880, 590);
    ui_text(640, 176, _won ? "MISSION ACCOMPLISHED" : "MISSION FAILED", _won ? UI_AMBER : make_colour_rgb(255, 90, 60), global.f_big, fa_center);
    var _me = global.teams[PLAYER];
    var _rows = [
        ["Enemy units destroyed", _me.stats.killed],
        ["Units lost", _me.stats.lost],
        ["Enemy structures destroyed", _me.stats.bkilled],
        ["Structures lost", _me.stats.blost],
        ["Lumen harvested", fmt_num(_me.harvested)],
        ["Time", string(global.frame div 3600) + ":" + string_replace_all(string_format((global.frame div 60) mod 60, 2, 0), " ", "0")]
    ];
    for (var _k = 0; _k < array_length(_rows); _k++)
    {
        ui_text(440, 240 + _k * 34, _rows[_k][0], UI_TEXT, global.f_ui);
        ui_text(840, 240 + _k * 34, string(_rows[_k][1]), UI_AMBER, global.f_ui, fa_right);
    }
    var _next = global.mission_index + 1;
    if (_won && _next < array_length(global.missions))
    {
        if (ui_button(430, 520, 200, 44, "Next mission")) { mission_clear(); global.brief_index = _next; global.brief_chars = 0; global.state = "brief"; return; }
    }
    else if (ui_button(430, 520, 200, 44, "Try again")) { mission_start(global.mission_index); return; }
    if (ui_button(650, 520, 200, 44, "Title")) { mission_clear(); global.state = "title"; return; }
    if (_won && _next >= array_length(global.missions)) ui_text(640, 470, "Embersand is yours, Commander.", UI_AMBER, global.f_ui, fa_center);
}

function ui_cursor()
{
    var _f = 0;
    if (global.state == "play" && !global.paused && global.gx < SIDE_X && global.gy >= TOP_H)
    {
        var _h = global.hover;
        if (_h != noone && !instance_exists(_h)) _h = noone; // it may have been destroyed since the Step event
        if (global.placing != "") _f = 0;
        else if (global.cmd == "attack") _f = 2;
        else if (array_length(global.sel) > 0)
        {
            _f = 1;
            var _cx = cell_of(global.mouse_wx), _cy = cell_of(global.mouse_wy);
            if (_h != noone && _h.team != PLAYER) _f = sel_has("combat") ? 2 : 4;
            else if (_h != noone && _h.object_index == obj_unit && _h.team == PLAYER) _f = 0;
            else if (sel_has("harvester") && _h != noone && _h.object_index == obj_building && _h.btype == "refinery") _f = 3;
            else if (sel_has("harvester") && in_map(_cx, _cy) && global.lumen[# _cx, _cy] > 0) _f = 3;
        }
    }
    draw_sprite(spr_cursor, _f, global.gx, global.gy);
}

function ui_drag_box()
{
    if (!global.drag) return;
    if (point_distance(global.gx, global.gy, global.drag_x, global.drag_y) < 6) return;
    draw_set_colour(make_colour_rgb(120, 255, 110));
    draw_rectangle(global.drag_x, global.drag_y, clamp(global.gx, 0, SIDE_X - 1), clamp(global.gy, TOP_H, GUI_H), true);
    draw_set_colour(c_white);
}

// ---------- World overlay (drawn in the room, under the shroud) ----------

function brackets(_x1, _y1, _x2, _y2, _col)
{
    var _l = min(5, (_x2 - _x1) / 3);
    draw_set_colour(_col);
    draw_line(_x1, _y1, _x1 + _l, _y1); draw_line(_x1, _y1, _x1, _y1 + _l);
    draw_line(_x2, _y1, _x2 - _l, _y1); draw_line(_x2, _y1, _x2, _y1 + _l);
    draw_line(_x1, _y2, _x1 + _l, _y2); draw_line(_x1, _y2, _x1, _y2 - _l);
    draw_line(_x2, _y2, _x2 - _l, _y2); draw_line(_x2, _y2, _x2, _y2 - _l);
    draw_set_colour(c_white);
}

function world_overlay_draw()
{
    for (var _k = 0; _k < array_length(global.order_fx); _k++)
    {
        var _o = global.order_fx[_k];
        draw_set_alpha(_o.t / 24);
        draw_set_colour(_o.col);
        draw_circle(_o.x, _o.y, 2 + (24 - _o.t) * 0.5, true);
        draw_set_alpha(1);
    }
    with (obj_unit)
    {
        var _show = selected || global.hover == id;
        if (!_show && hp >= maxhp) continue;
        if (!_show && !on_screen(x, y, 16)) continue;
        if (team != PLAYER && !seen(x, y)) continue;
        var _r = radius + 2;
        if (selected) brackets(x - _r, y - _r, x + _r, y + _r, c_white);
        if (_show || hp < maxhp)
        {
            var _f = hp / maxhp;
            ui_bar(x - _r, y - _r - 4, _r * 2, 2, _f, hp_colour(_f));
            if (utype == "harvester" && team == PLAYER && _show) ui_bar(x - _r, y + _r + 2, _r * 2, 2, cargo / HARV_CAP, make_colour_rgb(90, 230, 250));
        }
    }
    var _b = global.sel_one;
    if (_b != noone && instance_exists(_b))
    {
        if (_b.object_index == obj_building)
        {
            brackets(_b.x, _b.y, _b.x + _b.w * CELL - 1, _b.y + _b.h * CELL - 1, c_white);
            ui_bar(_b.x + 2, _b.y - 5, _b.w * CELL - 4, 3, _b.hp / _b.maxhp, hp_colour(_b.hp / _b.maxhp));
            if (_b.team == PLAYER)
            {
                var _r2 = global.teams[PLAYER].rally[$ _b.btype];
                if (_r2 != undefined)
                {
                    draw_set_colour(c_lime);
                    draw_set_alpha(0.6);
                    draw_line(_b.x + _b.w * HALF, _b.y + _b.h * CELL, _r2[0], _r2[1]);
                    draw_set_alpha(1);
                    draw_circle(_r2[0], _r2[1], 3, true);
                    draw_set_colour(c_white);
                }
            }
        }
        else if (_b.object_index == obj_unit)
        {
            var _r3 = _b.radius + 2;
            brackets(_b.x - _r3, _b.y - _r3, _b.x + _r3, _b.y + _r3, c_red);
        }
    }
    if (global.placing != "" && !global.paused)
    {
        var _d = global.bdef[$ global.placing];
        var _ok = can_place(PLAYER, global.placing, global.place_cx, global.place_cy);
        var _px = global.place_cx * CELL, _py = global.place_cy * CELL;
        team_shader(PLAYER);
        draw_sprite_ext(_d.spr, 0, _px, _py, 1, 1, 0, c_white, 0.55);
        shader_reset();
        for (var _i = 0; _i < _d.w; _i++)
        {
            for (var _j = 0; _j < _d.h; _j++)
            {
                var _c = global.place_cx + _i, _r = global.place_cy + _j;
                var _cell_ok = _ok || (in_map(_c, _r) && global.terr[# _c, _r] == T_ROCK && global.bgrid[# _c, _r] == noone);
                draw_set_alpha(0.35);
                draw_set_colour(_ok ? c_lime : (_cell_ok ? c_yellow : c_red));
                draw_rectangle(_px + _i * CELL, _py + _j * CELL, _px + (_i + 1) * CELL - 1, _py + (_j + 1) * CELL - 1, false);
                draw_set_alpha(1);
            }
        }
        draw_set_colour(_ok ? c_lime : c_red);
        draw_rectangle(_px, _py, _px + _d.w * CELL - 1, _py + _d.h * CELL - 1, true);
        draw_set_colour(c_white);
    }
}
