/// A 5x7 pixel font drawn with rectangles, so the game needs no font resource.
/// Each glyph is 5 columns by 7 rows; "#" is a lit pixel. Text is drawn in uppercase.

/// Builds global.pixel_glyphs once: character -> array of [column, row] lit pixels.
function pixel_font_init()
{
    if (variable_global_exists("pixel_glyphs")) return;
    global.pixel_glyphs = {};

    var _add = function(_ch, _rows)
    {
        var _pixels = [];
        for (var _r = 0; _r < 7; _r++)
        {
            for (var _c = 0; _c < 5; _c++)
            {
                if (string_char_at(_rows[_r], _c + 1) == "#") array_push(_pixels, [_c, _r]);
            }
        }
        global.pixel_glyphs[$ _ch] = _pixels;
    };

    _add("A", [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"]);
    _add("B", ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."]);
    _add("C", [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."]);
    _add("D", ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."]);
    _add("E", ["#####", "#....", "#....", "####.", "#....", "#....", "#####"]);
    _add("F", ["#####", "#....", "#....", "####.", "#....", "#....", "#...."]);
    _add("G", [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"]);
    _add("H", ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"]);
    _add("I", [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."]);
    _add("J", ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."]);
    _add("K", ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"]);
    _add("L", ["#....", "#....", "#....", "#....", "#....", "#....", "#####"]);
    _add("M", ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"]);
    _add("N", ["#...#", "#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#"]);
    _add("O", [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."]);
    _add("P", ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."]);
    _add("Q", [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"]);
    _add("R", ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"]);
    _add("S", [".####", "#....", "#....", ".###.", "....#", "....#", "####."]);
    _add("T", ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."]);
    _add("U", ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."]);
    _add("V", ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."]);
    _add("W", ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "#.#.#", ".#.#."]);
    _add("X", ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"]);
    _add("Y", ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."]);
    _add("Z", ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"]);

    _add("0", [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."]);
    _add("1", ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."]);
    _add("2", [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"]);
    _add("3", ["####.", "....#", "....#", ".###.", "....#", "....#", "####."]);
    _add("4", ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."]);
    _add("5", ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."]);
    _add("6", ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."]);
    _add("7", ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."]);
    _add("8", [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."]);
    _add("9", [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."]);

    _add(":", [".....", "..#..", "..#..", ".....", "..#..", "..#..", "....."]);
    _add("!", ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."]);
    _add("?", [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."]);
    _add(".", [".....", ".....", ".....", ".....", ".....", ".....", "..#.."]);
    _add(",", [".....", ".....", ".....", ".....", ".....", "..#..", ".#..."]);
    _add("'", ["..#..", "..#..", ".....", ".....", ".....", ".....", "....."]);
    _add("-", [".....", ".....", ".....", ".###.", ".....", ".....", "....."]);
    _add("+", [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."]);
    _add("/", ["....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."]);
    _add("_", [".....", ".....", ".....", ".....", ".....", ".....", "#####"]);
    _add(" ", [".....", ".....", ".....", ".....", ".....", ".....", "....."]);
}

/// Width in pixels of _text at _scale (each glyph is 5 wide plus 1 of spacing).
function pixel_text_width(_text, _scale)
{
    var _n = string_length(_text);
    return (_n <= 0) ? 0 : _n * 6 * _scale - _scale;
}

/// Height in pixels of one line at _scale.
function pixel_text_height(_scale)
{
    return 7 * _scale;
}

/// Draws _text with its top edge at _y. _halign is fa_left, fa_center or fa_right.
function draw_pixel_text(_x, _y, _text, _scale, _colour, _alpha = 1, _halign = fa_left)
{
    _text = string_upper(_text);
    var _w = pixel_text_width(_text, _scale);
    if (_halign == fa_center) _x -= _w div 2;
    else if (_halign == fa_right) _x -= _w;

    draw_set_colour(_colour);
    draw_set_alpha(_alpha);
    var _n = string_length(_text);
    for (var _i = 0; _i < _n; _i++)
    {
        var _glyph = global.pixel_glyphs[$ string_char_at(_text, _i + 1)];
        if (is_undefined(_glyph)) continue;
        var _gx = _x + _i * 6 * _scale;
        var _count = array_length(_glyph);
        for (var _p = 0; _p < _count; _p++)
        {
            var _px = _gx + _glyph[_p][0] * _scale;
            var _py = _y + _glyph[_p][1] * _scale;
            // Filled rectangles stop one pixel short of x2/y2 here, so x2 = x1 + scale fills exactly scale pixels.
            draw_rectangle(_px, _py, _px + _scale, _py + _scale, false);
        }
    }
    draw_set_alpha(1);
}

/// Draws _text with a soft additive glow around it, for the neon look.
function draw_neon_text(_x, _y, _text, _scale, _colour, _glow = 0.35, _halign = fa_left)
{
    if (_glow > 0)
    {
        var _g = max(1, _scale div 2);
        gpu_set_blendmode(bm_add);
        draw_pixel_text(_x - _g, _y, _text, _scale, _colour, _glow * 0.5, _halign);
        draw_pixel_text(_x + _g, _y, _text, _scale, _colour, _glow * 0.5, _halign);
        draw_pixel_text(_x, _y - _g, _text, _scale, _colour, _glow * 0.5, _halign);
        draw_pixel_text(_x, _y + _g, _text, _scale, _colour, _glow * 0.5, _halign);
        gpu_set_blendmode(bm_normal);
    }
    draw_pixel_text(_x, _y, _text, _scale, _colour, 1, _halign);
}
