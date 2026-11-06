/// Particles, ground decals, sounds, messages and the camera.

function fx_init()
{
    global.ps = part_system_create();
    part_system_depth(global.ps, 1500);
    part_system_automatic_draw(global.ps, true);

    var _p = part_type_create();
    part_type_sprite(_p, spr_explosion, true, true, false);
    part_type_life(_p, 34, 34);
    part_type_size(_p, 1, 1.15, 0, 0);
    part_type_orientation(_p, 0, 359, 0, 0, false);
    global.pt_explo = _p;

    _p = part_type_create();
    part_type_sprite(_p, spr_explosion, true, true, false);
    part_type_life(_p, 22, 22);
    part_type_size(_p, 0.45, 0.6, 0, 0);
    part_type_orientation(_p, 0, 359, 0, 0, false);
    global.pt_explo_s = _p;

    _p = part_type_create();
    part_type_sprite(_p, spr_smoke, false, false, false);
    part_type_size(_p, 0.5, 0.8, 0.012, 0);
    part_type_colour2(_p, make_colour_rgb(70, 64, 60), make_colour_rgb(40, 36, 34));
    part_type_alpha3(_p, 0.0, 0.55, 0);
    part_type_speed(_p, 0.15, 0.35, 0, 0);
    part_type_direction(_p, 70, 110, 0, 2);
    part_type_life(_p, 60, 100);
    global.pt_smoke = _p;

    _p = part_type_create();
    part_type_sprite(_p, spr_smoke, false, false, false);
    part_type_size(_p, 0.3, 0.6, 0.02, 0);
    part_type_colour1(_p, make_colour_rgb(222, 176, 120));
    part_type_alpha2(_p, 0.6, 0);
    part_type_speed(_p, 0.1, 0.5, -0.01, 0);
    part_type_direction(_p, 0, 359, 0, 0);
    part_type_life(_p, 25, 45);
    global.pt_dust = _p;

    _p = part_type_create();
    part_type_sprite(_p, spr_smoke, false, false, false);
    part_type_size(_p, 0.2, 0.35, 0.01, 0);
    part_type_colour2(_p, make_colour_rgb(230, 225, 215), make_colour_rgb(120, 115, 110));
    part_type_alpha2(_p, 0.5, 0);
    part_type_life(_p, 18, 28);
    global.pt_trail = _p;

    _p = part_type_create();
    part_type_sprite(_p, spr_flare, false, false, false);
    part_type_size(_p, 0.4, 0.9, -0.02, 0);
    part_type_speed(_p, 1, 2.6, -0.05, 0);
    part_type_direction(_p, 0, 359, 0, 0);
    part_type_gravity(_p, 0.06, 270);
    part_type_life(_p, 12, 26);
    part_type_blend(_p, true);
    global.pt_spark = _p;

    _p = part_type_create();
    part_type_sprite(_p, spr_flare, false, false, false);
    part_type_size(_p, 1.2, 1.6, -0.15, 0);
    part_type_life(_p, 4, 5);
    part_type_blend(_p, true);
    global.pt_flash = _p;

    _p = part_type_create();
    part_type_sprite(_p, spr_flare, false, false, false);
    part_type_size(_p, 0.3, 0.6, -0.01, 0);
    part_type_colour1(_p, make_colour_rgb(110, 240, 255));
    part_type_speed(_p, 0.3, 0.9, -0.02, 0);
    part_type_direction(_p, 50, 130, 0, 0);
    part_type_life(_p, 16, 30);
    part_type_blend(_p, true);
    global.pt_lumen = _p;

    _p = part_type_create();
    part_type_sprite(_p, spr_flare, false, false, false);
    part_type_size(_p, 0.5, 1.0, -0.01, 0);
    part_type_colour3(_p, make_colour_rgb(255, 240, 160), make_colour_rgb(255, 140, 40), make_colour_rgb(120, 40, 20));
    part_type_speed(_p, 0.2, 0.5, 0, 0);
    part_type_direction(_p, 80, 100, 0, 3);
    part_type_life(_p, 14, 26);
    part_type_blend(_p, true);
    global.pt_fire = _p;
}

function fx_free()
{
    part_type_destroy(global.pt_explo); part_type_destroy(global.pt_explo_s); part_type_destroy(global.pt_smoke);
    part_type_destroy(global.pt_dust); part_type_destroy(global.pt_trail); part_type_destroy(global.pt_spark);
    part_type_destroy(global.pt_flash); part_type_destroy(global.pt_lumen); part_type_destroy(global.pt_fire);
    part_system_destroy(global.ps);
}

/// Size: 0 small, 1 vehicle, 2 big.
function fx_explode(_x, _y, _size)
{
    if (_size == 0)
    {
        part_particles_create(global.ps, _x, _y, global.pt_explo_s, 1);
        part_particles_create(global.ps, _x, _y, global.pt_spark, 3);
        play_at("boom_s", _x, _y);
    }
    else
    {
        part_particles_create(global.ps, _x, _y, global.pt_explo, 1);
        repeat (_size) part_particles_create(global.ps, _x + random_range(-10, 10), _y + random_range(-8, 8), global.pt_explo_s, 1);
        part_particles_create(global.ps, _x, _y, global.pt_spark, 8 * _size);
        part_particles_create(global.ps, _x, _y, global.pt_smoke, 3 * _size);
        play_at("boom", _x, _y);
        if (seen(_x, _y)) global.shake = max(global.shake, 1.5 * _size);
    }
    if (_size > 0 || random(1) < 0.4) crater(_x, _y, _size);
}

function crater(_x, _y, _size)
{
    var _cx = cell_of(_x), _cy = cell_of(_y);
    if (!in_map(_cx, _cy)) return;
    if (_size >= 1) decal_add(spr_scorch, 0, _x, _y, 0.5 + _size * 0.15, random(360), 0.6 + _size * 0.3);
    if (global.terr[# _cx, _cy] == T_SAND) decal_add(spr_crater, irandom(2), _x, _y, 0.9, 0, 0.7 + _size * 0.25);
}

function decal_add(_spr, _img, _x, _y, _alpha, _angle, _scale)
{
    array_push(global.decals, { spr: _spr, img: _img, x: _x, y: _y, a: _alpha, ang: _angle, s: _scale });
    if (array_length(global.decals) > 260) array_delete(global.decals, 0, 1);
}

/// Plays a named effect, quieter the further it is from the middle of the screen. Only one of each name per frame.
function play_at(_name, _x, _y)
{
    var _cx = global.cam_x + VIEW_W / 2, _cy = global.cam_y + VIEW_H / 2;
    var _d = point_distance(_x, _y, _cx, _cy);
    var _vol = clamp(1.2 - _d / 520, 0, 1);
    if (_vol <= 0.02) return;
    play(_name, _vol);
}

function play(_name, _vol = 1)
{
    if (global.sound_off) return;
    var _last = global.snd_last[$ _name];
    if (_last != undefined && _last == global.frame) return;
    global.snd_last[$ _name] = global.frame;
    audio_play_sound(global.sfx[$ _name].sound, 1, false, _vol);
}

function msg(_text)
{
    global.message = _text;
    global.message_t = 240;
}

function cam_clamp()
{
    global.cam_x = clamp(global.cam_x, 0, max(0, global.mw * CELL - VIEW_W));
    global.cam_y = clamp(global.cam_y, 0, max(0, global.mh * CELL - VIEW_H));
}

function cam_center(_x, _y)
{
    global.cam_x = _x - VIEW_W / 2;
    global.cam_y = _y - VIEW_H / 2;
    cam_clamp();
}

function on_screen(_x, _y, _margin)
{
    return _x > global.cam_x - _margin && _y > global.cam_y - _margin && _x < global.cam_x + VIEW_W + _margin && _y < global.cam_y + VIEW_H + _margin;
}

function team_shader(_team)
{
    var _c = global.teams[_team].col;
    shader_set(sh_team);
    shader_set_uniform_f(global.u_team, colour_get_red(_c) / 255, colour_get_green(_c) / 255, colour_get_blue(_c) / 255);
}
