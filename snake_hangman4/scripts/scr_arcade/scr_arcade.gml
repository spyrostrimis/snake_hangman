/// The 80s bubble-arcade look for v4: palette, brick themes, round layouts, bubbles and
/// little pixel-art treats. Everything is drawn with primitives at 320 x 240, shown at 3x.

#macro GRID_W 17
#macro GRID_H 12
#macro CELL 16
#macro START_GX 4
#macro START_GY 6
#macro GAP_FROM 7    // columns 7..9 have a gap in the top and bottom walls: the snake wraps through
#macro GAP_TO 9

function arcade_init()
{
    if (variable_global_exists("arc")) return;
    draw_set_circle_precision(16);

    global.arc = {
        black:  c_black,
        white:  make_colour_rgb(255, 255, 255),
        p1:     make_colour_rgb(40, 230, 40),    // "1UP" green
        hi:     make_colour_rgb(255, 40, 40),    // "HIGH SCORE" red
        round:  make_colour_rgb(70, 180, 255),   // round label blue
        yellow: make_colour_rgb(255, 230, 40),
        orange: make_colour_rgb(255, 150, 30),
        pink:   make_colour_rgb(255, 100, 170),
        snake:  make_colour_rgb(60, 210, 70),
        snake_dark:  make_colour_rgb(16, 110, 36),
        snake_light: make_colour_rgb(170, 250, 150),
        // Bubble colours: every letter bubble gets one at random, so colour gives nothing away.
        bubbles: [
            make_colour_rgb(60, 220, 60), make_colour_rgb(60, 140, 255), make_colour_rgb(250, 215, 40),
            make_colour_rgb(255, 100, 160), make_colour_rgb(170, 80, 240), make_colour_rgb(255, 140, 40)
        ]
    };

    // One brick theme per round, cycling: base, light edge, dark edge, accent, pattern, shadow.
    global.themes = [
        { base: make_colour_rgb(255, 110, 170), light: make_colour_rgb(255, 200, 225), dark: make_colour_rgb(160, 30, 90),  accent: make_colour_rgb(255, 225, 70),  pattern: "check",   shadow: make_colour_rgb(90, 10, 50) },
        { base: make_colour_rgb(160, 165, 70),  light: make_colour_rgb(220, 225, 130), dark: make_colour_rgb(80, 85, 25),   accent: make_colour_rgb(40, 200, 60),   pattern: "square",  shadow: make_colour_rgb(50, 50, 10) },
        { base: make_colour_rgb(205, 70, 40),   light: make_colour_rgb(245, 130, 90),  dark: make_colour_rgb(110, 25, 10),  accent: make_colour_rgb(150, 40, 25),   pattern: "brick",   shadow: make_colour_rgb(70, 10, 0) },
        { base: make_colour_rgb(60, 120, 235),  light: make_colour_rgb(150, 200, 255), dark: make_colour_rgb(20, 45, 130),  accent: make_colour_rgb(130, 240, 255), pattern: "diamond", shadow: make_colour_rgb(10, 20, 70) },
        { base: make_colour_rgb(150, 70, 205),  light: make_colour_rgb(215, 155, 250), dark: make_colour_rgb(75, 25, 120),  accent: make_colour_rgb(255, 150, 225), pattern: "stripe",  shadow: make_colour_rgb(45, 10, 70) }
    ];
}

/// Round layouts: 17 x 12 cells, "#" is a brick block. The snake starts at (4, 6) facing right.
function round_layouts()
{
    return [
        { name: "BUBBLE BATH", rows: [
            ".................", ".................", "...#####.#####...", ".................",
            ".................", "..#...........#..", ".................", "..#...........#..",
            ".................", ".................", "...#####.#####...", "................." ], fizz: 0 },
        { name: "LADDERS", rows: [
            ".................", ".###.........###.", ".................", ".....#######.....",
            ".................", "##.............##", ".................", "##.............##",
            ".................", ".....#######.....", ".................", ".###.........###." ], fizz: 0 },
        { name: "TWIN TOWERS", rows: [
            ".................", "....#.....#......", "....#.....#......", "....#.....#......",
            ".................", ".................", ".................", ".................",
            "......#.....#....", "......#.....#....", "......#.....#....", "................." ], fizz: 1 },
        { name: "SPIRAL", rows: [
            ".................", ".#############...", ".#...............", ".#..#########....",
            ".#..#............", ".#..#..######....", ".................", "....#............",
            "....#########....", ".................", "...#############.", "................." ], fizz: 1 },
        { name: "CANDY GRID", rows: [
            ".................", "..##..##..##..##.", ".................", ".................",
            "..##..##..##..##.", ".................", ".................", ".................",
            "..##..##..##..##.", ".................", ".................", "..##..##..##..##." ], fizz: 2 }
    ];
}

function layout_walls(_layout)
{
    var _walls = array_create(GRID_W);
    for (var _x = 0; _x < GRID_W; _x++)
    {
        _walls[_x] = array_create(GRID_H, false);
        for (var _y = 0; _y < GRID_H; _y++) _walls[_x][_y] = string_char_at(_layout.rows[_y], _x + 1) == "#";
    }
    return _walls;
}

/// Flood fill from the start: letters and treats only appear where the snake can reach.
function layout_reachable(_walls)
{
    var _seen = array_create(GRID_W);
    for (var _x = 0; _x < GRID_W; _x++) _seen[_x] = array_create(GRID_H, false);
    var _queue = [[START_GX, START_GY]];
    _seen[START_GX][START_GY] = true;
    var _steps = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    while (array_length(_queue) > 0)
    {
        var _c = _queue[0];
        array_delete(_queue, 0, 1);
        for (var _i = 0; _i < 4; _i++)
        {
            var _nx = _c[0] + _steps[_i][0];
            var _ny = _c[1] + _steps[_i][1];
            if (_nx < 0 || _ny < 0 || _nx >= GRID_W || _ny >= GRID_H) continue;
            if (_seen[_nx][_ny] || _walls[_nx][_ny]) continue;
            _seen[_nx][_ny] = true;
            array_push(_queue, [_nx, _ny]);
        }
    }
    return _seen;
}

/// One 8 x 8 bevelled brick in a theme.
function draw_brick(_x, _y, _t)
{
    draw_set_colour(_t.base);
    draw_rectangle(_x, _y, _x + 8, _y + 8, false);
    switch (_t.pattern)
    {
        case "check":
            draw_set_colour(_t.accent);
            draw_rectangle(_x + 1, _y + 1, _x + 4, _y + 4, false);
            draw_rectangle(_x + 4, _y + 4, _x + 7, _y + 7, false);
            break;
        case "square":
            draw_set_colour(_t.dark);
            draw_rectangle(_x + 2, _y + 2, _x + 6, _y + 6, false);
            draw_set_colour(_t.accent);
            draw_rectangle(_x + 3, _y + 3, _x + 5, _y + 5, false);
            break;
        case "brick":
            draw_set_colour(_t.accent);
            draw_rectangle(_x, _y + 4, _x + 8, _y + 5, false);
            draw_rectangle(_x + 3, _y, _x + 4, _y + 4, false);
            draw_rectangle(_x + 6, _y + 5, _x + 7, _y + 8, false);
            break;
        case "diamond":
            draw_set_colour(_t.accent);
            draw_rectangle(_x + 3, _y + 2, _x + 5, _y + 6, false);
            draw_rectangle(_x + 2, _y + 3, _x + 6, _y + 5, false);
            break;
        case "stripe":
            draw_set_colour(_t.accent);
            for (var _i = 0; _i < 3; _i++) draw_rectangle(_x + 1 + _i * 2, _y + 5 - _i * 2, _x + 3 + _i * 2, _y + 7 - _i * 2, false);
            break;
    }
    draw_set_colour(_t.light);
    draw_rectangle(_x, _y, _x + 8, _y + 1, false);
    draw_rectangle(_x, _y, _x + 1, _y + 8, false);
    draw_set_colour(_t.dark);
    draw_rectangle(_x, _y + 7, _x + 8, _y + 8, false);
    draw_rectangle(_x + 7, _y, _x + 8, _y + 8, false);
}

/// A letter bubble: coloured ball, darker rim, shine spots and a white letter.
function draw_bubble(_cx, _cy, _r, _col, _letter = "", _alpha = 1)
{
    _cx = round(_cx);
    _cy = round(_cy);
    draw_set_alpha(_alpha);
    draw_set_colour(merge_colour(_col, c_black, 0.45));
    draw_circle(_cx, _cy, _r, false);
    draw_set_colour(_col);
    draw_circle(_cx, _cy, _r - 1, false);
    draw_set_colour(merge_colour(_col, c_white, 0.35));
    draw_circle(_cx - 1, _cy - 1, _r - 3, false);
    draw_set_colour(_col);
    draw_circle(_cx, _cy, _r - 3, false);
    draw_set_colour(c_white);
    draw_rectangle(_cx - _r + 2, _cy - _r + 3, _cx - _r + 4, _cy - _r + 5, false);
    draw_rectangle(_cx - _r + 4, _cy - _r + 2, _cx - _r + 5, _cy - _r + 3, false);
    draw_set_alpha(1);
    if (_letter != "")
    {
        pixel_text(_cx - 1, _cy - 2, _letter, 1, c_black, fa_center, 0.5 * _alpha);
        pixel_text(_cx - 2, _cy - 3, _letter, 1, c_white, fa_center, _alpha);
    }
}

/// Draws pixel art from strings: each character is looked up in _palette; "." is transparent.
function pixel_map(_x, _y, _rows, _palette, _scale = 1)
{
    _x = round(_x);
    _y = round(_y);
    for (var _r = 0; _r < array_length(_rows); _r++)
    {
        var _row = _rows[_r];
        for (var _c = 1; _c <= string_length(_row); _c++)
        {
            var _ch = string_char_at(_row, _c);
            if (_ch == ".") continue;
            var _col = _palette[$ _ch];
            if (is_undefined(_col)) continue;
            draw_set_colour(_col);
            var _px = _x + (_c - 1) * _scale;
            var _py = _y + _r * _scale;
            draw_rectangle(_px, _py, _px + _scale, _py + _scale, false);
        }
    }
}

/// Bonus treats: original pixel art, worth more in later rounds.
function treat_list()
{
    var _pal = {
        r: make_colour_rgb(230, 30, 50), R: make_colour_rgb(255, 190, 200), g: make_colour_rgb(40, 170, 50),
        w: make_colour_rgb(255, 250, 235), y: make_colour_rgb(250, 210, 90), p: make_colour_rgb(255, 120, 170),
        b: make_colour_rgb(150, 90, 40), o: make_colour_rgb(235, 160, 60), P: make_colour_rgb(255, 210, 230),
        k: make_colour_rgb(90, 50, 20), c: make_colour_rgb(110, 60, 30)
    };
    return [
        { name: "CHERRIES", points: 500, palette: _pal, rows: [
            "......gg.", ".....g.g.", "....g..g.", "...g...g.", ".rr...rr.",
            "rRrr.rRrr", "rrrr.rrrr", "rrrr.rrrr", ".rr...rr." ] },
        { name: "CAKE", points: 1000, palette: _pal, rows: [
            "....r....", "...www...", "..wwwww..", ".wwwwwww.", ".yyyyyyy.",
            ".ppppppp.", ".yyyyyyy.", ".bbbbbbb." ] },
        { name: "ICE CREAM", points: 2000, palette: _pal, rows: [
            "..ppp..", ".pPppp.", ".ppppp.", "..www..", ".wwwww.",
            ".ooooo.", "..ooo..", "..ooo..", "...o...", "...o..." ] },
        { name: "COOKIE", points: 3000, palette: _pal, rows: [
            "..ccccc..", ".coooooc.", "cookoooc.", "coooookoc", "coooooooc",
            "cokoooooc", ".cooookc.", "..ccccc.." ] }
    ];
}

/// The little snake head used for lives.
function draw_life_icon(_x, _y)
{
    var _a = global.arc;
    pixel_map(_x, _y, [
        ".gggg..",
        "gwkgggg",
        "gggggg.",
        ".gggg.r" ], { g: _a.snake, w: c_white, k: c_black, r: make_colour_rgb(255, 60, 80) });
}
