/// The Hangman site's look, ported to GameMaker: colours from client/src/theme.css,
/// Bruno Ace SC from client/src/Fonts, and helpers for its glows, labels, rows and buttons.

/// Sets up global.site (colours) and global.fonts. Safe to call more than once.
function site_style_init()
{
    if (variable_global_exists("site")) return;

    global.site = {
        yellow:   make_colour_rgb(243, 244, 0),   // --hm-yellow
        neon:     make_colour_rgb(237, 238, 2),   // --hm-neon (title glow)
        cyan:     make_colour_rgb(16, 207, 230),  // --hm-cyan
        pink:     make_colour_rgb(219, 62, 177),  // --hm-pink (table headings)
        magenta:  make_colour_rgb(189, 27, 109),  // --hm-magenta (wrong, lost chances)
        green:    make_colour_rgb(62, 224, 122),  // --hm-green (right, chances left)
        text:     make_colour_rgb(217, 216, 219), // --hm-text
        muted:    make_colour_rgb(169, 168, 173), // --hm-muted
        subtitle: make_colour_rgb(184, 183, 187), // .hm-subtitle
        silver:   make_colour_rgb(230, 230, 234), // 2nd place
        bronze:   make_colour_rgb(240, 160, 80),  // 3rd place
        space:    make_colour_rgb(11, 13, 26),    // Deep Space
        steel:    make_colour_rgb(26, 27, 32),    // unlit power cell
        line:     make_colour_rgb(147, 147, 147)  // #939393 row dividers
    };

    // font_add takes file fonts in pixels. The site sets Bruno for titles, nav, labels and numbers.
    var _bruno = "BrunoAceSC-Regular.ttf";
    global.fonts = {
        title:   font_add(_bruno, 40, false, false, 32, 128),
        word:    font_add(_bruno, 36, false, false, 32, 128),
        big:     font_add(_bruno, 26, false, false, 32, 128),
        row:     font_add(_bruno, 21, false, false, 32, 128),
        nav:     font_add(_bruno, 17, false, false, 32, 128),
        tile:    font_add(_bruno, 18, false, false, 32, 128),
        small:   font_add(_bruno, 13, false, false, 32, 128),
        label:   font_add(_bruno, 11, false, false, 32, 128),
        // The site's body text is the system monospace; on Windows that is Consolas.
        mono:    font_add("Consolas", 16, false, false, 32, 128),
        mono_sm: font_add("Consolas", 14, false, false, 32, 128)
    };
}

/// Draws text with the site's legibility shadow (0 2px 10px #000000c0) underneath.
function site_text(_x, _y, _text, _font, _col, _halign = fa_left, _alpha = 1)
{
    draw_set_font(_font);
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    draw_set_colour(c_black);
    draw_set_alpha(0.35 * _alpha);
    draw_text(_x, _y + 2, _text);
    draw_text(_x + 1, _y + 3, _text);
    draw_set_colour(_col);
    draw_set_alpha(_alpha);
    draw_text(_x, _y, _text);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
}

/// Neon text: the site's text-shadow glow (e.g. 0 0 15px yellow) as additive halos.
function site_text_glow(_x, _y, _text, _font, _col, _radius = 6, _strength = 0.12, _halign = fa_left)
{
    draw_set_font(_font);
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_add);
    draw_set_colour(_col);
    for (var _r = _radius; _r > 0; _r -= _radius / 2)
    {
        draw_set_alpha(_strength);
        for (var _a = 0; _a < 360; _a += 45)
        {
            draw_text(_x + lengthdir_x(_r, _a), _y + lengthdir_y(_r, _a), _text);
        }
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    site_text(_x, _y, _text, _font, _col, _halign);
}

/// Width of _text drawn with letter spacing _spacing (CSS letter-spacing).
function spaced_width(_text, _font, _spacing)
{
    draw_set_font(_font);
    var _n = string_length(_text);
    return (_n == 0) ? 0 : string_width(_text) + _spacing * (_n - 1);
}

/// Letter-spaced uppercase text, like the site's labels (.hm-label, table headings, subtitle).
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

/// A dashed horizontal line, like the table's row dividers (1px dashed #93939326).
function dashed_line(_x1, _x2, _y, _col, _alpha, _dash = 6, _gap = 5)
{
    draw_set_colour(_col);
    draw_set_alpha(_alpha);
    for (var _x = _x1; _x < _x2; _x += _dash + _gap)
    {
        draw_line(_x, _y, min(_x + _dash, _x2), _y);
    }
    draw_set_alpha(1);
}

/// Soft additive glow around a rounded rectangle (the site's box-shadow glows).
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

/// The yellow neon navigation capsule.
function site_capsule(_x1, _y1, _x2, _y2)
{
    var _s = global.site;
    glow_roundrect(_x1, _y1, _x2, _y2, 22, _s.neon, 0.9, 10);
    draw_set_colour(make_colour_rgb(6, 10, 14));
    draw_set_alpha(0.86);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 22, 22, false);
    draw_set_alpha(1);
    draw_set_colour(_s.yellow);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 22, 22, true);
    draw_roundrect_ext(_x1, _y1 + 1, _x2, _y2 + 1, 22, 22, true);
}

/// The six power cells (.hm-cells): lit green while chances remain, dark with a magenta rim once lost.
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

/// The arcade button (.hm-button): curved top, glow; primary is yellow.
function site_button(_cx, _y, _label, _primary, _pulse)
{
    var _s = global.site;
    var _w = spaced_width(_label, global.fonts.small, 2) + 64;
    var _x1 = _cx - _w / 2;
    var _x2 = _cx + _w / 2;
    var _y2 = _y + 46;
    var _glow_col = _primary ? _s.neon : _s.cyan;
    glow_roundrect(_x1, _y, _x2, _y2, 14, _glow_col, 0.7 + 0.3 * _pulse, 10);
    draw_set_colour(make_colour_rgb(20, 22, 26));
    draw_set_alpha(0.7);
    draw_roundrect_ext(_x1, _y, _x2, _y2, 14, 14, false);
    draw_set_alpha(0.25);
    draw_set_colour(_s.line);
    draw_roundrect_ext(_x1, _y, _x2, _y2, 14, 14, true);
    draw_set_alpha(1);
    site_text_spaced(_cx, _y + 15, string_upper(_label), global.fonts.small, _primary ? _s.yellow : make_colour_rgb(208, 210, 213), 2, fa_center);
}
