global.ui_t++;
// The GUI is laid out for 1280 x 720 and stretched to whatever size the window has (e.g. full screen).
var _ww = window_get_width(), _wh = window_get_height();
if (_ww > 0 && _wh > 0 && (_ww != gui_w || _wh != gui_h))
{
    gui_w = _ww;
    gui_h = _wh;
    display_set_gui_maximise(_ww / GUI_W, _wh / GUI_H, 0, 0);
}
global.gx = device_mouse_x_to_gui(0);
global.gy = device_mouse_y_to_gui(0);
if (!centred && global.ui_t > 1) { window_center(); centred = true; }
if (keyboard_check_pressed(vk_f11) || (keyboard_check(vk_alt) && keyboard_check_pressed(vk_enter))) window_set_fullscreen(!window_get_fullscreen());

if (global.autotest) autotest_step();

switch (global.state)
{
    case "title":
        if (keyboard_check_pressed(vk_escape)) game_end();
        break;

    case "brief":
        if (keyboard_check_pressed(vk_escape)) global.state = "title";
        break;

    case "play":
        if (keyboard_check_pressed(vk_escape) && global.placing == "" && global.cmd == "") global.paused = !global.paused;
        part_system_automatic_update(global.ps, !global.paused);
        if (global.autotest) { global.hover = noone; sel_clean(); } else play_input();
        if (!global.paused) game_tick();
        break;

    case "end":
        part_system_automatic_update(global.ps, true);
        break;
}

// Camera (with a little shake from big explosions)
var _sx = (global.shake > 0) ? random_range(-global.shake, global.shake) : 0;
var _sy = (global.shake > 0) ? random_range(-global.shake, global.shake) : 0;
if (view_camera[0] != global.cam) { view_camera[0] = global.cam; view_wport[0] = VIEW_W; view_hport[0] = VIEW_H; }
camera_set_view_pos(global.cam, round(global.cam_x + _sx), round(global.cam_y + _sy));
