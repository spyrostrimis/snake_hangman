/// Draws the homepage look around the game, and the field itself through a surface and a shader.

var _s = global.site;
var _f = global.fonts;
var _pulse = 0.5 + 0.5 * sin(frame * 0.08);
var _misses = word_miss_count(word, guessed);
var _fx2 = grid_x + field_w;
var _fy2 = grid_y + field_h;
var _grey = make_colour_rgb(153, 153, 153);

var _ox = (shake > 0) ? round(random_range(-shake, shake)) : 0;
var _oy = (shake > 0) ? round(random_range(-shake, shake)) : 0;
matrix_set(matrix_world, matrix_build(_ox, _oy, 0, 0, 0, 0, 1, 1, 1));

// ---------- Background: the homepage's warp-speed stars, multiplied over #999 ----------
draw_set_colour(make_colour_rgb(24, 32, 40));
draw_rectangle(-16, -16, room_width + 16, room_height + 16, false);
draw_sprite_ext(spr_bg, 0, 0, 0, 1, 1, 0, _grey, 1);

// ---------- Title, as on the homepage ----------
site_text_glow(640, 4, "Snake Hangman", _f.title, _s.neon, 8, 0.08, fa_center);
site_text_spaced(640, 66, "RESCUE MISSION", _f.small, make_colour_rgb(184, 183, 187), 3, fa_center);

// ---------- The hidden word ----------
var _n = string_length(word);
if (_n > 0)
{
    var _pitch = 46;
    var _wx = 640 - (_n * _pitch - 10) / 2;
    for (var _i = 0; _i < _n; _i++)
    {
        var _ch = string_char_at(word, _i + 1);
        var _sx = _wx + _i * _pitch;
        var _shown = letter_is_guessed(guessed, _ch);
        draw_set_colour(_shown ? _s.cyan : _s.text);
        draw_set_alpha(_shown ? 0.9 : 0.35);
        draw_rectangle(_sx, 156, _sx + 35, 158, false);
        draw_set_alpha(1);
        if (_shown)
        {
            var _t = reveal_timers[_i] / 40;
            var _col = merge_colour(_s.yellow, _s.green, _t);
            site_text_glow(_sx + 18, 104 - round(10 * _t), _ch, _f.word, _col, 5, 0.08, fa_center);
        }
        else if (state == "lost")
        {
            site_text(_sx + 18, 104, _ch, _f.word, _s.pink, fa_center);
        }
    }
}

// ---------- Left: the mission log, on the briefing's frosted glass ----------
site_glass_panel(20, 200, 260, 680);
site_text(140, 212, "Mission log", _f.heading, _s.text, fa_center);

site_text_spaced(40, 258, "STAGE", _f.label, _s.muted, 2);
site_text_glow(40, 272, string(level), _f.big, _s.yellow, 4, 0.06);
site_text(78, 282, layout.name, _f.mono_sm, _s.brief);

site_text_spaced(40, 320, "SCORE", _f.label, _s.muted, 2);
site_text_glow(40, 334, string(total_points), _f.big, _s.yellow, 4, 0.06);

site_text_spaced(40, 382, "BEST", _f.label, _s.muted, 2);
site_text(40, 396, string(max(best_points, total_points)), _f.row, _s.cyan);

site_text_spaced(40, 438, "POWER CELLS", _f.label, _s.muted, 2);
site_power_cells(40, 456, MAX_MISSES - _misses, MAX_MISSES);

site_text_spaced(40, 504, "USED LETTERS", _f.label, _s.muted, 2);
for (var _i = 1; _i <= string_length(guessed); _i++)
{
    var _ch = string_char_at(guessed, _i);
    var _ux = 40 + ((_i - 1) mod 7) * 28;
    var _uy = 522 + ((_i - 1) div 7) * 26;
    site_text(_ux, _uy, _ch, _f.orb, word_has_letter(word, _ch) ? _s.green : _s.pink);
}
site_text(40, 600, "Arrows / WASD: move", _f.mono_sm, _s.muted);
site_text(40, 620, "P: pause", _f.mono_sm, _s.muted);
site_text(40, 640, "M: sound " + (sound_on ? "on" : "off"), _f.mono_sm, sound_on ? _s.muted : _s.pink);

// ---------- Right: the crew, each in a pod, reacting to the game ----------
var _cards = [
    { y: 200, accent: _s.han,     name: "Han Fastolfe", role: "Linguist · Aurora" },
    { y: 360, accent: _s.artsy,   name: "Artsy",        role: "Painter · Solaria" },
    { y: 520, accent: _s.illucia, name: "Illucia",      role: "Han's daughter" }
];
var _rev = revival();
for (var _c = 0; _c < 3; _c++)
{
    var _cd = _cards[_c];
    var _x1 = 1004;
    var _x2 = 1260;
    var _y1 = _cd.y;
    var _y2 = _cd.y + 150;
    var _pod_x2 = _x1 + 116;
    var _lit = (_c == 0 && (hint_timer > 0 || !is_undefined(hint_orb))) || (_c == 1 && state == "won");
    site_crew_card(_x1, _y1, _x2, _y2, _cd.accent, _pod_x2, 146, _lit ? 1 : _pulse * 0.3);

    var _pcx = (_x1 + _pod_x2) / 2;
    var _bottom = _y1 + 146 - 12;
    switch (_c)
    {
        case 0: draw_sprite(spr_han, 0, _pcx - sprite_get_width(spr_han) / 2, _bottom - sprite_get_height(spr_han)); break;
        case 1:
            // Artsy wakes up letter by letter: the grey robot fades into the coloured one.
            var _ax = _pcx - sprite_get_width(spr_artsy) * 0.45;
            var _ay = _bottom - sprite_get_height(spr_artsy) * 0.9;
            draw_sprite_ext(spr_artsygray, 0, _ax, _ay, 0.9, 0.9, 0, c_white, 1);
            draw_sprite_ext(spr_artsy, 0, _ax, _ay, 0.9, 0.9, 0, c_white, (state == "won") ? 1 : _rev);
            break;
        case 2: draw_sprite(spr_illucia, 0, _pcx - sprite_get_width(spr_illucia) / 2, _bottom - sprite_get_height(spr_illucia) + 6); break;
    }

    var _tx = _pod_x2 + 10;
    site_text(_tx, _y1 + 14, _cd.name, _f.name, _s.text);
    site_text(_tx, _y1 + 42, _cd.role, _f.label, _cd.accent);
    var _status = "";
    var _scol = _s.brief;
    switch (_c)
    {
        case 0:
            if (hint_timer > 0) { _status = "Hint on: the right letters glow green."; _scol = _s.han; }
            else if (!is_undefined(hint_orb)) { _status = "Eat my green orb for a hint."; _scol = _s.han; }
            else if (state == "play" && launched) _status = "Next orb in " + string(ceil(hint_cooldown / 60)) + " s.";
            else _status = "I'll send hint orbs during the mission.";
            break;
        case 1:
            var _pct = (state == "won") ? 100 : round(_rev * 100);
            _status = (state == "won") ? "Back online." : "Revival " + string(_pct) + "%";
            draw_set_colour(_s.steel);
            draw_roundrect_ext(_tx, _y1 + 112, _x2 - 14, _y1 + 120, 3, 3, false);
            draw_set_colour(_s.artsy);
            draw_roundrect_ext(_tx, _y1 + 112, _tx + (_x2 - 14 - _tx) * _pct / 100, _y1 + 120, 3, 3, false);
            break;
        case 2:
            var _total = array_length(word_hidden_letters(word, ""));
            var _found = _total - array_length(word_hidden_letters(word, guessed));
            var _acc = (letters_eaten > 0) ? string(round(100 * letters_right / letters_eaten)) + "%" : "-";
            _status = (word == "") ? "I'll keep the statistics." : "Found " + string(_found) + " of " + string(_total) + " letters. Accuracy " + _acc + ".";
            break;
    }
    site_text_wrap(_tx, _y1 + 62, _status, _f.mono_sm, _scol, _x2 - _tx - 10, 18);
}

// ---------- The field, drawn into a surface ----------
site_glass_panel(grid_x - 10, grid_y - 10, _fx2 + 10, _fy2 + 14);

if (!surface_exists(field_surface)) field_surface = surface_create(field_w, field_h);
surface_set_target(field_surface);
matrix_set(matrix_world, matrix_build_identity());

// The part of the background behind the field, darkened like glass.
draw_sprite_part_ext(spr_bg, 0, grid_x, grid_y, field_w, field_h, 0, 0, 1, 1, _grey, 1);
draw_set_colour(_s.space);
draw_set_alpha(0.62);
draw_rectangle(0, 0, field_w, field_h, false);
draw_set_alpha(1);

// Warp stars (particle system).
part_system_drawit(ps_back);

// Faint navigation dots at cell corners.
draw_set_colour(_s.cyan);
draw_set_alpha(0.12);
for (var _gx = 1; _gx < GRID_W; _gx++)
{
    for (var _gy = 1; _gy < GRID_H; _gy++) draw_point(_gx * cell, _gy * cell);
}
draw_set_alpha(1);

// Walls: dark hull plates with a cyan edge only where they meet open space.
for (var _gx = 0; _gx < GRID_W; _gx++)
{
    for (var _gy = 0; _gy < GRID_H; _gy++)
    {
        if (!walls[_gx][_gy]) continue;
        var _x1 = _gx * cell;
        var _y1 = _gy * cell;
        var _x2 = _x1 + cell;
        var _y2 = _y1 + cell;
        draw_set_colour(make_colour_rgb(35, 37, 46));
        draw_rectangle(_x1, _y1, _x2, _y2, false);
        draw_set_colour(make_colour_rgb(58, 61, 74));
        draw_rectangle(_x1 + 3, _y1 + 3, _x2 - 4, _y2 - 4, true);
        draw_set_colour(make_colour_rgb(120, 124, 140));
        draw_point(_x1 + 6, _y1 + 6);
        draw_point(_x2 - 7, _y1 + 6);
        draw_point(_x1 + 6, _y2 - 7);
        draw_point(_x2 - 7, _y2 - 7);

        var _open_up    = (_gy == 0) || !walls[_gx][_gy - 1];
        var _open_down  = (_gy == GRID_H - 1) || !walls[_gx][_gy + 1];
        var _open_left  = (_gx == 0) || !walls[_gx - 1][_gy];
        var _open_right = (_gx == GRID_W - 1) || !walls[_gx + 1][_gy];
        var _edge_a = 0.55 + 0.35 * _pulse;
        gpu_set_blendmode(bm_add);
        draw_set_colour(_s.cyan);
        for (var _g = 0; _g < 3; _g++)
        {
            draw_set_alpha(_edge_a * (0.6 - _g * 0.2));
            if (_open_up)    draw_line(_x1, _y1 + _g, _x2, _y1 + _g);
            if (_open_down)  draw_line(_x1, _y2 - 1 - _g, _x2, _y2 - 1 - _g);
            if (_open_left)  draw_line(_x1 + _g, _y1, _x1 + _g, _y2);
            if (_open_right) draw_line(_x2 - 1 - _g, _y1, _x2 - 1 - _g, _y2);
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
}

// Letters: floating data orbs that pop in. During a hint, the right ones glow green.
for (var _i = 0; _i < array_length(letters); _i++)
{
    var _l = letters[_i];
    var _sc = ease_out_back(min(1, _l.age / 22));
    var _cx = cell_cx(_l.gx);
    var _cy = cell_cy(_l.gy) + sin(frame * 0.07 + _l.seed) * 2;
    var _hinted = hint_timer > 0 && word_has_letter(word, _l.ch);
    var _ring = _hinted ? _s.han : _s.cyan;

    gpu_set_blendmode(bm_add);
    draw_set_colour(_ring);
    draw_set_alpha(_hinted ? 0.25 + 0.2 * _pulse : 0.14);
    draw_circle(_cx, _cy, 16 * _sc, false);
    gpu_set_blendmode(bm_normal);
    draw_set_colour(make_colour_rgb(8, 10, 24));
    draw_set_alpha(0.9);
    draw_circle(_cx, _cy, 12.5 * _sc, false);
    draw_set_colour(_ring);
    draw_set_alpha(_hinted ? 1 : 0.6);
    draw_circle(_cx, _cy, 12.5 * _sc, true);
    draw_set_alpha(1);
    draw_set_font(_f.orb);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(_hinted ? _s.han : c_white);
    draw_text_transformed(_cx, _cy + 1, _l.ch, _sc, _sc, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// Han's hint orb: green, with "AI" like the orb on his staff; blinks before it fades.
if (!is_undefined(hint_orb))
{
    var _show = hint_orb.life > 120 || (frame div 6) mod 2 == 0;
    if (_show)
    {
        var _cx = cell_cx(hint_orb.gx);
        var _cy = cell_cy(hint_orb.gy);
        gpu_set_blendmode(bm_add);
        draw_set_colour(_s.han);
        draw_set_alpha(0.25 + 0.25 * _pulse);
        draw_circle(_cx, _cy, 17, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
        draw_set_colour(make_colour_rgb(20, 70, 40));
        draw_circle(_cx, _cy, 12, false);
        draw_set_colour(_s.han);
        draw_circle(_cx, _cy, 12, true);
        draw_set_font(_f.label);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(c_white);
        draw_text(_cx, _cy + 1, "AI");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
}

// The snake: a robot chain with glowing joints and a visored head, like Artsy's.
var _len = array_length(snake);
for (var _i = _len - 1; _i >= 0; _i--)
{
    var _seg = snake[_i];
    var _cx = cell_cx(_seg.gx);
    var _cy = cell_cy(_seg.gy);
    if (_i > 0)
    {
        // Joint towards the segment in front.
        var _prev = snake[_i - 1];
        var _jx = (_cx + cell_cx(_prev.gx)) / 2;
        var _jy = (_cy + cell_cy(_prev.gy)) / 2;
        gpu_set_blendmode(bm_add);
        draw_set_colour(_s.cyan);
        draw_set_alpha(0.5);
        draw_circle(_jx, _jy, 6, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
        draw_set_colour(_s.cyan);
        draw_circle(_jx, _jy, 3, false);
    }
    var _inset = (_i == 0) ? 2 : 4 + 3 * (_i / max(1, _len - 1));
    var _metal = (_i == 0) ? make_colour_rgb(228, 230, 238) : ((_i mod 2 == 0) ? make_colour_rgb(201, 204, 214) : make_colour_rgb(178, 182, 194));
    draw_set_colour(_metal);
    draw_roundrect_ext(_cx - cell / 2 + _inset, _cy - cell / 2 + _inset, _cx + cell / 2 - _inset, _cy + cell / 2 - _inset, 9, 9, false);
    draw_set_colour(c_white);
    draw_set_alpha(0.45);
    draw_line(_cx - cell / 2 + _inset + 4, _cy - cell / 2 + _inset + 2, _cx + cell / 2 - _inset - 4, _cy - cell / 2 + _inset + 2);
    draw_set_alpha(1);

    if (_i == 0)
    {
        // Dark visor across the front, with two cyan eyes.
        var _vx = _cx + dir_x * 4;
        var _vy = _cy + dir_y * 4;
        var _hw = (dir_x != 0) ? 6 : 11;
        var _hh = (dir_x != 0) ? 11 : 6;
        draw_set_colour(make_colour_rgb(11, 13, 26));
        draw_roundrect_ext(_vx - _hw, _vy - _hh, _vx + _hw, _vy + _hh, 5, 5, false);
        for (var _e = -1; _e <= 1; _e += 2)
        {
            var _ex = _vx + (-dir_y) * 5 * _e + dir_x;
            var _ey = _vy + dir_x * 5 * _e + dir_y;
            gpu_set_blendmode(bm_add);
            draw_set_colour(_s.cyan);
            draw_set_alpha(0.6);
            draw_circle(_ex, _ey, 4, false);
            gpu_set_blendmode(bm_normal);
            draw_set_alpha(1);
            draw_set_colour(make_colour_rgb(170, 245, 255));
            draw_circle(_ex, _ey, 2, false);
        }
    }
}

// Space debris (instances following paths), drawn here so the shader and surface include them.
with (obj_debris)
{
    var _dx = x - other.grid_x;
    var _dy = y - other.grid_y;
    // A hot orange halo so the rock reads clearly against the dark field.
    gpu_set_blendmode(bm_add);
    draw_set_colour(global.site.artsy);
    draw_set_alpha(0.35);
    draw_circle(_dx, _dy, debris_radius + 7, false);
    draw_set_alpha(0.25);
    draw_circle(_dx, _dy, debris_radius + 3, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(_dx, _dy, make_colour_rgb(214, 178, 140), 1);
    for (var _k = 0; _k <= 8; _k++)
    {
        var _ang = image_angle + (_k mod 8) * 45;
        var _r = debris_radius * corners[_k mod 8];
        draw_vertex_colour(_dx + lengthdir_x(_r, _ang), _dy + lengthdir_y(_r, _ang), make_colour_rgb(128, 96, 74), 1);
    }
    draw_primitive_end();
    draw_set_colour(make_colour_rgb(255, 200, 120));
    for (var _k = 0; _k < 8; _k++)
    {
        var _a1 = image_angle + _k * 45;
        var _a2 = image_angle + (_k + 1) * 45;
        draw_line(_dx + lengthdir_x(debris_radius * corners[_k], _a1), _dy + lengthdir_y(debris_radius * corners[_k], _a1),
                  _dx + lengthdir_x(debris_radius * corners[(_k + 1) mod 8], _a2), _dy + lengthdir_y(debris_radius * corners[(_k + 1) mod 8], _a2));
    }
}

// Sparks, rings and trails (particle system).
part_system_drawit(ps_front);

// A clear "press to launch" hint before the first move.
if (state == "play" && !launched && (frame div 25) mod 2 == 0)
{
    site_text(field_w / 2, field_h - 44, "Press an arrow key to launch", _f.mono, _s.yellow, fa_center);
}

surface_reset_target();

// Draw the field through the shader, with a small zoom "punch" when a word is cleared.
var _zoom = 1 + 0.04 * sin(punch * pi);
var _dxs = grid_x + _ox - field_w * (_zoom - 1) / 2;
var _dys = grid_y + _oy - field_h * (_zoom - 1) / 2;
shader_set(shd_field);
shader_set_uniform_f(u_time, frame / 60);
shader_set_uniform_f(u_hit, hit);
shader_set_uniform_f(u_glow, glow);
shader_set_uniform_f(u_height, field_h);
draw_surface_ext(field_surface, _dxs, _dys, _zoom, _zoom, 0, c_white, 1);
shader_reset();
matrix_set(matrix_world, matrix_build(_ox, _oy, 0, 0, 0, 0, 1, 1, 1));

// ---------- Stage banner, sliding in ----------
if (banner_timer > 0 && state == "play")
{
    var _t = 1 - banner_timer / 150;
    var _in = ease_out_cubic(min(1, _t * 4));
    var _out = (_t > 0.75) ? (_t - 0.75) / 0.25 : 0;
    var _bx = lerp(grid_x - 200, grid_x + field_w / 2, _in) + _out * 300;
    var _ba = 1 - _out;
    draw_set_colour(_s.space);
    draw_set_alpha(0.55 * _ba);
    draw_rectangle(grid_x, grid_y + 170, _fx2, grid_y + 270, false);
    draw_set_alpha(1);
    site_text_glow(_bx, grid_y + 184, "Stage " + string(level), _f.stage, _s.neon, 6, 0.08 * _ba, fa_center, _ba);
    site_text(_bx, grid_y + 232, layout.name, _f.mono, _s.brief, fa_center, _ba);
}

// ---------- Overlays ----------
if (state != "play")
{
    draw_set_colour(_s.space);
    draw_set_alpha((state == "paused") ? 0.45 : 0.8);
    draw_rectangle(grid_x, grid_y, _fx2, _fy2, false);
    draw_set_alpha(1);
    var _mx = grid_x + field_w / 2;

    switch (state)
    {
        case "title":
            site_text(_mx, grid_y + 18, "Mission briefing", _f.heading, _s.text, fa_center);
            var _ty = grid_y + 66;
            var _tx = grid_x + 56;
            var _w = field_w - 112;
            _ty += site_text_wrap(_tx, _ty, "Professor Han Fastolfe urgently seeks your assistance again. Artsy's memory has scattered across the station as letters, and only the secret word can wake him.", _f.mono, _s.brief, _w, 24) + 12;
            _ty += site_text_wrap(_tx, _ty, "Steer the rescue snake into the letters of the word. Every right letter brings Artsy closer to waking up.", _f.mono, _s.brief, _w, 24) + 14;
            site_text_glow(_tx, _ty, "But beware!", _f.row, _s.pink, 4, 0.06);
            _ty += 34;
            _ty += site_text_wrap(_tx, _ty, "A wrong letter drains a power cell. Six wrong letters, a wall, your own tail or a piece of space debris end the mission. Han's green orb makes the right letters glow for a few seconds.", _f.mono, _s.brief, _w, 24) + 22;
            site_button(_mx - 140, _ty, "Enter: play", true, _pulse);
            site_button(_mx + 140, _ty, "M: sound " + (sound_on ? "on" : "off"), false, _pulse);
            break;

        case "paused":
            site_text_glow(_mx, grid_y + 180, "Paused", _f.banner, _s.neon, 6, 0.08, fa_center);
            site_text(_mx, grid_y + 244, "Press P to resume.", _f.mono, _s.brief, fa_center);
            break;

        case "won":
            site_text_glow(_mx, grid_y + 110, "Word clear", _f.banner, _s.neon, 6, 0.08, fa_center);
            site_text_glow(_mx, grid_y + 180, word, _f.word, _s.cyan, 5, 0.07, fa_center);
            site_text(_mx, grid_y + 246, "+" + string(round_bonus) + " bonus. Your score is " + string(total_points) + ".", _f.mono, _s.brief, fa_center);
            site_text(_mx, grid_y + 272, "Artsy is back online.", _f.mono, _s.artsy, fa_center);
            site_button(_mx, grid_y + 320, "Enter: next stage", true, _pulse);
            break;

        case "lost":
            site_text_glow(_mx, grid_y + 96, end_reason, _f.big, _s.pink, 5, 0.08, fa_center);
            site_text(_mx, grid_y + 150, "The word was", _f.mono, _s.muted, fa_center);
            site_text_glow(_mx, grid_y + 174, word, _f.word, _s.yellow, 5, 0.07, fa_center);
            var _line = "Score " + string(total_points) + ".  Best " + string(best_points) + ".";
            site_text(_mx, grid_y + 244, _line, _f.mono, _s.cyan, fa_center);
            if (new_best) site_text_glow(_mx, grid_y + 272, "A new best score", _f.row, _s.yellow, 4, 0.06, fa_center);
            site_button(_mx, grid_y + 320, "Enter: try again", true, _pulse);
            break;
    }
}

matrix_set(matrix_world, matrix_build_identity());
