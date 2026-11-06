/// The Hangman site's homepage look, ported to GameMaker: colours from client/src/theme.css,
/// TechnoBoard and Bruno Ace SC from client/src/Fonts, and helpers for the frosted-glass
/// briefing panel, the crew cards with their pods, glows, labels and buttons.

function site_style_init()
{
    if (variable_global_exists("site")) return;

    global.site = {
        yellow:  make_colour_rgb(243, 244, 0),   // --hm-yellow
        neon:    make_colour_rgb(237, 238, 2),   // --hm-neon
        cyan:    make_colour_rgb(16, 207, 230),  // --hm-cyan
        pink:    make_colour_rgb(219, 62, 177),  // --hm-pink ("But beware!")
        magenta: make_colour_rgb(189, 27, 109),  // --hm-magenta
        green:   make_colour_rgb(62, 224, 122),  // --hm-green
        text:    make_colour_rgb(217, 216, 219), // --hm-text
        brief:   make_colour_rgb(216, 243, 247), // .home-brief-inner text
        muted:   make_colour_rgb(169, 168, 173), // --hm-muted
        steel:   make_colour_rgb(26, 27, 32),
        space:   make_colour_rgb(5, 7, 18),      // #050712, card background
        line:    make_colour_rgb(147, 147, 147),
        han:     make_colour_rgb(67, 228, 64),   // #43e440, Han's accent
        artsy:   make_colour_rgb(225, 128, 27),  // #e1801b, Artsy's accent
        illucia: make_colour_rgb(165, 78, 215)   // #a54ed7, Illucia's accent
    };

    // File fonts are sized in pixels. TechnoBoard for headings, Bruno for labels and numbers.
    // The free TechnoBoard replaces its digits with the designer's logo, so never give it numbers.
    var _tb = "TechnoBoard-519Ej.ttf";
    var _bruno = "BrunoAceSC-Regular.ttf";
    global.fonts = {
        title:   font_add(_tb, 46, false, false, 32, 128),
        banner:  font_add(_tb, 40, false, false, 32, 128),
        stage:   font_add(_bruno, 34, false, false, 32, 128),
        heading: font_add(_tb, 24, false, false, 32, 128),
        name:    font_add(_tb, 17, false, false, 32, 128),
        word:    font_add(_bruno, 36, false, false, 32, 128),
        big:     font_add(_bruno, 26, false, false, 32, 128),
        row:     font_add(_bruno, 19, false, false, 32, 128),
        orb:     font_add(_bruno, 16, false, false, 32, 128),
        small:   font_add(_bruno, 13, false, false, 32, 128),
        label:   font_add(_bruno, 10, false, false, 32, 128),
        mono:    font_add("Consolas", 16, false, false, 32, 128),
        mono_sm: font_add("Consolas", 14, false, false, 32, 128)
    };
}

/// Text with the site's soft dark shadow underneath.
function site_text(_x, _y, _text, _font, _col, _halign = fa_left, _alpha = 1)
{
    draw_set_font(_font);
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    draw_set_colour(c_black);
    draw_set_alpha(0.35 * _alpha);
    draw_text(_x, _y + 2, _text);
    draw_set_colour(_col);
    draw_set_alpha(_alpha);
    draw_text(_x, _y, _text);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
}

/// Neon text: additive halos for the site's text-shadow glows.
function site_text_glow(_x, _y, _text, _font, _col, _radius = 6, _strength = 0.1, _halign = fa_left, _alpha = 1)
{
    draw_set_font(_font);
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_add);
    draw_set_colour(_col);
    for (var _r = _radius; _r > 0; _r -= _radius / 2)
    {
        draw_set_alpha(_strength * _alpha);
        for (var _a = 0; _a < 360; _a += 45)
        {
            draw_text(_x + lengthdir_x(_r, _a), _y + lengthdir_y(_r, _a), _text);
        }
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    site_text(_x, _y, _text, _font, _col, _halign, _alpha);
}

/// Wraps _text at _width pixels and draws it with the site's shadow; returns the height used.
function site_text_wrap(_x, _y, _text, _font, _col, _width, _line_h, _halign = fa_left)
{
    draw_set_font(_font);
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    draw_set_colour(c_black);
    draw_set_alpha(0.35);
    draw_text_ext(_x, _y + 2, _text, _line_h, _width);
    draw_set_colour(_col);
    draw_set_alpha(1);
    draw_text_ext(_x, _y, _text, _line_h, _width);
    var _h = string_height_ext(_text, _line_h, _width);
    draw_set_halign(fa_left);
    return _h;
}

function spaced_width(_text, _font, _spacing)
{
    draw_set_font(_font);
    var _n = string_length(_text);
    return (_n == 0) ? 0 : string_width(_text) + _spacing * (_n - 1);
}

/// Letter-spaced text (CSS letter-spacing), for labels and buttons.
function site_text_spaced(_x, _y, _text, _font, _col, _spacing, _halign = fa_left)
{
    var _w = spaced_width(_text, _font, _spacing);
    if (_halign == fa_center) _x -= _w / 2;
    else if (_halign == fa_right) _x -= _w;
    draw_set_font(_font);
    for (var _i = 1; _i <= string_length(_text); _i++)
    {
        var _ch = string_char_at(_text, _i);
        site_text(_x, _y, _ch, _font, _col);
        _x += string_width(_ch) + _spacing;
    }
}

function glow_roundrect(_x1, _y1, _x2, _y2, _radius, _col, _strength, _spread = 8)
{
    gpu_set_blendmode(bm_add);
    draw_set_colour(_col);
    for (var _g = _spread; _g >= 1; _g -= 1)
    {
        draw_set_alpha(_strength * (1 - _g / (_spread + 1)) * 0.35);
        draw_roundrect_ext(_x1 - _g, _y1 - _g, _x2 + _g, _y2 + _g, _radius + _g, _radius + _g, true);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

/// The frosted-glass briefing panel: translucent white, a light rim and a cyan bottom edge.
function site_glass_panel(_x1, _y1, _x2, _y2)
{
    var _s = global.site;
    glow_roundrect(_x1, _y1 + 10, _x2, _y2 + 4, 16, make_colour_rgb(230, 230, 230), 0.35, 12);
    draw_set_colour(c_white);
    draw_set_alpha(0.08);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 16, 16, false);
    draw_set_alpha(0.05);
    draw_roundrect_ext(_x1, _y1, _x2, _y1 + (_y2 - _y1) * 0.55, 16, 16, false);
    draw_set_alpha(0.16);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 16, 16, true);
    draw_set_alpha(0.22);
    draw_line(_x1 + 14, _y1 + 1, _x2 - 14, _y1 + 1);
    draw_set_alpha(1);
    draw_set_colour(_s.cyan);
    draw_roundrect_ext(_x1 + 4, _y2 - 4, _x2 - 4, _y2, 3, 3, false);
    glow_roundrect(_x1 + 4, _y2 - 4, _x2 - 4, _y2, 3, _s.cyan, 0.5, 5);
}

/// A crew card: dark rounded card with an accent glow, and the rounded pod the robot stands in,
/// spanning _x1.._pod_x2 and _pod_h tall. Returns the y where the pod ends.
function site_crew_card(_x1, _y1, _x2, _y2, _accent, _pod_x2, _pod_h, _pulse)
{
    var _s = global.site;
    glow_roundrect(_x1, _y1, _x2, _y2, 14, _accent, 0.55 + 0.25 * _pulse, 8);
    draw_set_colour(_s.space);
    draw_set_alpha(0.62);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, false);
    draw_set_colour(_s.line);
    draw_set_alpha(0.2);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, true);
    draw_set_alpha(1);

    // The pod: square top, deep elliptical bottom, radial blue inside, grey rim.
    var _cx = (_x1 + _pod_x2) / 2;
    var _py2 = _y1 + _pod_h;
    var _rx = (_pod_x2 - _x1) / 2;
    var _ry = min(34, _pod_h * 0.35);
    var _top = make_colour_rgb(29, 33, 80);
    var _edge = make_colour_rgb(5, 7, 18);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(_cx, _y1 + _pod_h * 0.35, _top, 0.85);
    draw_vertex_colour(_x1, _y1, _edge, 0.7);
    draw_vertex_colour(_pod_x2, _y1, _edge, 0.7);
    for (var _a = 0; _a <= 180; _a += 10)
    {
        draw_vertex_colour(_cx + _rx * dcos(_a), _py2 - _ry + _ry * dsin(_a), make_colour_rgb(70, 72, 90), 0.75);
    }
    draw_vertex_colour(_x1, _y1, _edge, 0.7);
    draw_primitive_end();

    // Grey rim along the pod's curved bottom.
    draw_set_colour(_s.text);
    draw_set_alpha(0.75);
    var _px = _cx + _rx;
    var _py = _py2 - _ry;
    for (var _a = 10; _a <= 180; _a += 10)
    {
        var _nx = _cx + _rx * dcos(_a);
        var _ny = _py2 - _ry + _ry * dsin(_a);
        draw_line_width(_px, _py, _nx, _ny, 3);
        _px = _nx;
        _py = _ny;
    }
    draw_set_alpha(1);
    return _py2;
}

/// The six power cells (.hm-cells).
function site_power_cells(_x, _y, _remaining, _total)
{
    var _s = global.site;
    for (var _i = 0; _i < _total; _i++)
    {
        var _cx = _x + _i * 22;
        if (_i < _remaining)
        {
            glow_roundrect(_cx, _y, _cx + 16, _y + 30, 2, _s.green, 0.9, 5);
            draw_set_colour(_s.green);
            draw_roundrect_ext(_cx, _y, _cx + 16, _y + 30, 3, 3, false);
        }
        else
        {
            draw_set_colour(_s.steel);
            draw_roundrect_ext(_cx, _y, _cx + 16, _y + 30, 3, 3, false);
            draw_set_colour(_s.magenta);
            draw_set_alpha(0.7);
            draw_roundrect_ext(_cx, _y, _cx + 16, _y + 30, 3, 3, true);
            draw_set_alpha(1);
        }
    }
}

/// Arcade button (.hm-button): yellow for the main action, cyan for the second.
function site_button(_cx, _y, _label, _primary, _pulse)
{
    var _s = global.site;
    var _w = spaced_width(_label, global.fonts.small, 2) + 60;
    var _x1 = _cx - _w / 2;
    var _x2 = _cx + _w / 2;
    var _y2 = _y + 46;
    glow_roundrect(_x1, _y, _x2, _y2, 12, _primary ? _s.neon : _s.cyan, 0.7 + 0.3 * _pulse, 10);
    draw_set_colour(make_colour_rgb(20, 22, 26));
    draw_set_alpha(0.7);
    draw_roundrect_ext(_x1, _y, _x2, _y2, 12, 12, false);
    draw_set_alpha(0.25);
    draw_set_colour(_s.line);
    draw_roundrect_ext(_x1, _y, _x2, _y2, 12, 12, true);
    draw_set_alpha(1);
    site_text_spaced(_cx, _y + 15, string_upper(_label), global.fonts.small, _primary ? _s.yellow : make_colour_rgb(208, 210, 213), 2, fa_center);
}

/// Easing for pop-ins: overshoots a little, then settles (t from 0 to 1).
function ease_out_back(_t)
{
    var _c1 = 1.70158;
    var _c3 = _c1 + 1;
    return 1 + _c3 * power(_t - 1, 3) + _c1 * power(_t - 1, 2);
}

function ease_out_cubic(_t)
{
    return 1 - power(1 - _t, 3);
}
