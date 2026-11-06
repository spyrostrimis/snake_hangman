/// Stages for Snake Hangman v3. Each is 22 x 15 cells: "#" is a wall.
/// The snake always starts at (6, 7) facing right, so cells (3..12, 7) stay clear.
/// Debris floats over walls along a path (grid points, closed loop or back and forth).

#macro GRID_W 22
#macro GRID_H 15
#macro START_GX 6
#macro START_GY 7

function level_layouts()
{
    return [
        {
            name: "Docking bay",
            rows: [
                "......................",
                "......................",
                "...####........####...",
                "......................",
                "......................",
                "..........##..........",
                "..........##..........",
                "......................",
                "..........##..........",
                "..........##..........",
                "......................",
                "......................",
                "...####........####...",
                "......................",
                "......................"
            ],
            debris: []
        },
        {
            name: "Asteroid lane",
            rows: [
                "......................",
                "......................",
                "......................",
                "...######....######...",
                "......................",
                "......................",
                "......................",
                "......................",
                "......................",
                "......................",
                "......................",
                "...######....######...",
                "......................",
                "......................",
                "......................"
            ],
            debris: [
                { points: [[16, 0], [16, 14]], closed: false, speed: 1.5 }
            ]
        },
        {
            name: "Hangar",
            rows: [
                "......................",
                ".####............####.",
                ".#..................#.",
                ".#..................#.",
                "......................",
                ".......########.......",
                "......................",
                "......................",
                "......................",
                ".......########.......",
                "......................",
                ".#..................#.",
                ".#..................#.",
                ".####............####.",
                "......................"
            ],
            debris: [
                { points: [[3, 4], [18, 4], [18, 10], [3, 10]], closed: true, speed: 1.4 }
            ]
        },
        {
            name: "Reactor maze",
            rows: [
                "......................",
                "..######......######..",
                "..#...................",
                "..#.....######.....#..",
                "...................#..",
                ".........#............",
                ".........#.....###....",
                "......................",
                "....###.....#.........",
                "............#.........",
                "..#...................",
                "..#.....######.....#..",
                "...................#..",
                "..######......######..",
                "......................"
            ],
            debris: [
                { points: [[3, 4], [17, 4]], closed: false, speed: 1.6 },
                { points: [[4, 10], [18, 10]], closed: false, speed: 1.3 }
            ]
        }
    ];
}

/// Parses a layout's rows into a GRID_W x GRID_H array of booleans (true = wall).
function level_walls(_layout)
{
    var _walls = array_create(GRID_W);
    for (var _x = 0; _x < GRID_W; _x++)
    {
        _walls[_x] = array_create(GRID_H, false);
        for (var _y = 0; _y < GRID_H; _y++)
        {
            _walls[_x][_y] = string_char_at(_layout.rows[_y], _x + 1) == "#";
        }
    }
    return _walls;
}

/// Flood fill from (_sx, _sy): a GRID_W x GRID_H array, true where the snake can reach.
/// Letters only spawn on reachable cells, so a wall can never trap a letter.
function level_reachable(_walls, _sx, _sy)
{
    var _seen = array_create(GRID_W);
    for (var _x = 0; _x < GRID_W; _x++) _seen[_x] = array_create(GRID_H, false);
    var _queue = [[_sx, _sy]];
    _seen[_sx][_sy] = true;
    while (array_length(_queue) > 0)
    {
        var _c = _queue[0];
        array_delete(_queue, 0, 1);
        var _steps = [[1, 0], [-1, 0], [0, 1], [0, -1]];
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
