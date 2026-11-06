/// Levels are built in code from a few shapes: ground, blocks, logs, spikes and spawns.
/// Every level, word and creature here is original.

function lvl_create(_name, _w, _h, _music, _sky_top, _sky_bottom)
{
    var _grid = array_create(_w);
    for (var _x = 0; _x < _w; _x++) _grid[_x] = array_create(_h, T_EMPTY);
    return { name: _name, w: _w, h: _h, grid: _grid, spawns: [], music: _music, sky_top: _sky_top, sky_bottom: _sky_bottom, arena: [0, 0] };
}

function lvl_rect(_l, _x1, _y1, _x2, _y2, _t)
{
    for (var _x = max(0, _x1); _x <= min(_l.w - 1, _x2); _x++)
        for (var _y = max(0, _y1); _y <= min(_l.h - 1, _y2); _y++) _l.grid[_x][_y] = _t;
}

/// Solid ground from row _top down to the bottom.
function lvl_ground(_l, _x1, _x2, _top)
{
    lvl_rect(_l, _x1, _top, _x2, _l.h - 1, T_SOLID);
}

function lvl_put(_l, _kind, _tx, _ty)
{
    array_push(_l.spawns, { kind: _kind, tx: _tx, ty: _ty });
}

function lvl_gems(_l, _x1, _x2, _ty)
{
    for (var _x = _x1; _x <= _x2; _x++) lvl_put(_l, "gem", _x, _ty);
}

/// Level 1: a sunny meadow of hills, logs, a hidden alcove and a few pits.
function level_greenleaf()
{
    var L = lvl_create("GREENLEAF GROVE", 170, 15, "music_08.ogg", make_colour_rgb(22, 40, 140), make_colour_rgb(96, 168, 236));
    lvl_ground(L, 0, 24, 11);
    lvl_put(L, "start", 3, 10);
    lvl_gems(L, 7, 11, 9);
    lvl_put(L, "bug", 16, 10);
    lvl_put(L, "letter", 20, 8);

    lvl_ground(L, 28, 44, 11);
    lvl_rect(L, 33, 9, 37, 10, T_SOLID);
    lvl_rect(L, 30, 6, 35, 6, T_ONEWAY);
    lvl_put(L, "letter", 32, 5);
    lvl_put(L, "gem", 34, 5);
    lvl_put(L, "bug", 40, 10);
    lvl_put(L, "spring", 43, 10);

    lvl_rect(L, 46, 4, 52, 5, T_SOLID);
    lvl_put(L, "letter", 49, 3);
    lvl_put(L, "egg", 47, 3);
    lvl_ground(L, 45, 72, 11);
    lvl_put(L, "bee", 55, 7);
    lvl_put(L, "letter", 58, 10);

    // A sealed alcove: roll into the cracked wall to break in.
    lvl_rect(L, 63, 8, 63, 10, T_CRACK);
    lvl_rect(L, 63, 7, 69, 7, T_SOLID);
    lvl_rect(L, 69, 8, 69, 10, T_SOLID);
    lvl_put(L, "letter", 66, 10);
    lvl_put(L, "gem", 65, 10);
    lvl_put(L, "gem", 67, 10);

    lvl_ground(L, 73, 82, 11);
    lvl_put(L, "flag", 75, 10);
    lvl_put(L, "letter", 79, 7);
    lvl_rect(L, 85, 9, 88, 9, T_ONEWAY);
    lvl_rect(L, 91, 7, 94, 7, T_ONEWAY);
    lvl_put(L, "letter", 92, 6);
    lvl_put(L, "bee", 89, 5);
    lvl_gems(L, 85, 88, 8);

    lvl_ground(L, 97, 122, 11);
    lvl_rect(L, 103, 10, 105, 10, T_SPIKES);
    lvl_rect(L, 108, 8, 112, 10, T_SOLID);
    lvl_put(L, "bug", 100, 10);
    lvl_put(L, "bug", 116, 10);
    lvl_put(L, "letter", 110, 7);
    lvl_put(L, "letter", 119, 10);
    lvl_put(L, "egg", 114, 10);
    lvl_put(L, "spring", 121, 10);

    lvl_ground(L, 127, 169, 11);
    lvl_rect(L, 128, 8, 130, 8, T_ONEWAY);   // a step up to the high log (5 tiles is out of jump reach)
    lvl_rect(L, 132, 6, 137, 6, T_ONEWAY);
    lvl_put(L, "letter", 134, 5);
    lvl_put(L, "bee", 140, 7);
    lvl_put(L, "letter", 145, 10);

    // Boss arena: Big Cheese guards the exit and one letter of the word.
    L.arena = [146, 163];
    lvl_rect(L, 151, 8, 155, 8, T_ONEWAY);
    lvl_put(L, "letter", 153, 7);
    lvl_put(L, "boss_mouse", 158, 10);
    lvl_put(L, "door", 165, 10);
    return L;
}

/// Level 2: a purple-sky climb of pillars, springs, a secret floor and more bees.
function level_mushroom()
{
    var L = lvl_create("MUSHROOM HEIGHTS", 150, 15, "music_01.ogg", make_colour_rgb(58, 26, 106), make_colour_rgb(228, 122, 184));
    lvl_ground(L, 0, 18, 11);
    lvl_put(L, "start", 3, 10);
    lvl_put(L, "bug", 12, 10);
    lvl_put(L, "letter", 15, 10);

    lvl_ground(L, 22, 30, 11);
    lvl_put(L, "spring", 29, 10);
    lvl_rect(L, 32, 7, 36, 14, T_SOLID);
    lvl_put(L, "letter", 34, 6);

    // A secret room under cracked floor: drop onto it as a ball.
    lvl_ground(L, 37, 50, 11);
    lvl_rect(L, 46, 12, 50, 13, T_EMPTY);
    lvl_rect(L, 47, 11, 49, 11, T_CRACK);
    lvl_put(L, "letter", 48, 13);
    lvl_put(L, "gem", 47, 13);
    lvl_put(L, "gem", 49, 13);
    lvl_rect(L, 39, 8, 43, 8, T_ONEWAY);
    lvl_put(L, "letter", 41, 7);
    lvl_put(L, "bee", 45, 6);

    lvl_ground(L, 51, 70, 11);
    lvl_put(L, "spring", 53, 10);
    lvl_rect(L, 55, 5, 56, 10, T_SOLID);
    lvl_rect(L, 58, 5, 62, 5, T_ONEWAY);
    lvl_put(L, "letter", 60, 4);
    // A spring on the far side of the tall wall, so it can be climbed again from the right.
    lvl_put(L, "spring", 63, 10);
    lvl_put(L, "bug", 64, 10);
    lvl_put(L, "bee", 67, 6);
    lvl_rect(L, 72, 9, 73, 9, T_ONEWAY);

    lvl_ground(L, 75, 95, 9);
    lvl_put(L, "flag", 77, 8);
    lvl_rect(L, 82, 8, 84, 8, T_SPIKES);
    lvl_put(L, "letter", 88, 8);
    lvl_put(L, "bug", 91, 8);
    lvl_gems(L, 79, 81, 6);

    lvl_ground(L, 96, 111, 11);
    lvl_rect(L, 99, 7, 104, 7, T_ONEWAY);
    lvl_put(L, "letter", 101, 6);
    lvl_put(L, "bee", 106, 5);
    lvl_put(L, "spring", 110, 10);
    lvl_rect(L, 112, 6, 114, 14, T_SOLID);
    lvl_put(L, "letter", 113, 5);
    lvl_put(L, "egg", 112, 5);

    lvl_ground(L, 115, 149, 11);
    // A spring back up onto the pillar, so a missed glide over the room below can be retried.
    lvl_put(L, "spring", 116, 10);
    lvl_put(L, "bug", 120, 10);
    lvl_rect(L, 126, 8, 126, 10, T_CRACK);
    lvl_rect(L, 126, 7, 131, 7, T_SOLID);
    lvl_rect(L, 131, 8, 131, 10, T_SOLID);
    lvl_put(L, "letter", 128, 10);

    // Boss arena: the Hothead Hen guards the exit and one letter of the word.
    L.arena = [132, 146];
    lvl_put(L, "letter", 134, 10);
    lvl_rect(L, 137, 7, 141, 7, T_ONEWAY);
    lvl_put(L, "letter", 139, 6);
    lvl_put(L, "egg", 144, 10);
    lvl_put(L, "boss_hen", 141, 10);
    lvl_put(L, "door", 148, 10);
    return L;
}

function level_list()
{
    return [level_greenleaf, level_mushroom];
}
