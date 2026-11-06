/// The arcade "best 5" table with three-letter initials, saved in an .ini file
/// (on Windows, %LOCALAPPDATA%\snake_hangman4\hiscore.ini).

#macro HISCORE_SIZE 5
#macro HISCORE_FILE "hiscore.ini"

/// The table, best first: [{ initials, points, round }]. Starts with a few made-up scores to beat.
function hiscore_load()
{
    var _table = [];
    ini_open(HISCORE_FILE);
    var _count = ini_read_real("table", "count", -1);
    if (_count < 0)
    {
        _table = [
            { initials: "SNK", points: 30000, round: 5 },
            { initials: "BUB", points: 20000, round: 4 },
            { initials: "POP", points: 10000, round: 3 },
            { initials: "ABC", points: 5000,  round: 2 },
            { initials: "XYZ", points: 1000,  round: 1 }
        ];
    }
    else
    {
        for (var _i = 0; _i < min(_count, HISCORE_SIZE); _i++)
        {
            array_push(_table, {
                initials: ini_read_string("table", "initials" + string(_i), "AAA"),
                points: ini_read_real("table", "points" + string(_i), 0),
                round: ini_read_real("table", "round" + string(_i), 1)
            });
        }
    }
    ini_close();
    return _table;
}

function hiscore_save(_table)
{
    ini_open(HISCORE_FILE);
    ini_write_real("table", "count", array_length(_table));
    for (var _i = 0; _i < array_length(_table); _i++)
    {
        ini_write_string("table", "initials" + string(_i), _table[_i].initials);
        ini_write_real("table", "points" + string(_i), _table[_i].points);
        ini_write_real("table", "round" + string(_i), _table[_i].round);
    }
    ini_close();
}

function hiscore_qualifies(_table, _points)
{
    if (_points <= 0) return false;
    var _n = array_length(_table);
    return _n < HISCORE_SIZE || _points > _table[_n - 1].points;
}

/// Inserts below equal scores, trims to HISCORE_SIZE, returns the new row's index or -1.
function hiscore_insert(_table, _entry)
{
    var _at = 0;
    while (_at < array_length(_table) && _table[_at].points >= _entry.points) _at++;
    array_insert(_table, _at, _entry);
    if (array_length(_table) > HISCORE_SIZE) array_resize(_table, HISCORE_SIZE);
    return (_at < HISCORE_SIZE) ? _at : -1;
}

function ordinal(_n)
{
    var _tens = _n mod 100;
    var _suffix = "TH";
    if (_tens < 11 || _tens > 13)
    {
        switch (_n mod 10)
        {
            case 1: _suffix = "ST"; break;
            case 2: _suffix = "ND"; break;
            case 3: _suffix = "RD"; break;
        }
    }
    return string(_n) + _suffix;
}
