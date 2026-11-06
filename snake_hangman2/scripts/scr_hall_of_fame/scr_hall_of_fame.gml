/// Local Hall of Fame: the best runs on this computer, ranked like the site's Hall of Fame.
/// Stored in an .ini file in the game's save folder (on Windows, %LOCALAPPDATA%\snake_hangman2).

#macro HALL_SIZE 5
#macro HALL_FILE "hall_of_fame.ini"
#macro NAME_MAX_LENGTH 12

/// Arcade-style places, as on the site: equal scores share a place (1st, 2nd, 2nd, 4th).
function hall_rank(_entries, _index)
{
    var _rank = 1;
    for (var _i = 0; _i < array_length(_entries); _i++)
    {
        if (_entries[_i].points > _entries[_index].points) _rank++;
    }
    return _rank;
}

/// 1 -> "1st", 2 -> "2nd", 11 -> "11th", as on the site.
function ordinal(_n)
{
    var _tens = _n mod 100;
    var _suffix = "th";
    if (_tens < 11 || _tens > 13)
    {
        switch (_n mod 10)
        {
            case 1: _suffix = "st"; break;
            case 2: _suffix = "nd"; break;
            case 3: _suffix = "rd"; break;
        }
    }
    return string(_n) + _suffix;
}

/// 2015 -> "2,015".
function format_points(_n)
{
    var _digits = string(floor(abs(_n)));
    var _out = "";
    var _len = string_length(_digits);
    for (var _i = 1; _i <= _len; _i++)
    {
        _out += string_char_at(_digits, _i);
        var _left = _len - _i;
        if (_left > 0 && _left mod 3 == 0) _out += ",";
    }
    return ((_n < 0) ? "-" : "") + _out;
}

/// The saved table, best first: an array of { name, points, words }.
function hall_load()
{
    var _entries = [];
    ini_open(HALL_FILE);
    var _count = min(HALL_SIZE, ini_read_real("hall", "count", 0));
    for (var _i = 0; _i < _count; _i++)
    {
        array_push(_entries, {
            name: ini_read_string("hall", "name" + string(_i), "player"),
            points: ini_read_real("hall", "points" + string(_i), 0),
            words: ini_read_real("hall", "words" + string(_i), 0)
        });
    }
    ini_close();
    return _entries;
}

function hall_save(_entries)
{
    ini_open(HALL_FILE);
    ini_write_real("hall", "count", array_length(_entries));
    for (var _i = 0; _i < array_length(_entries); _i++)
    {
        ini_write_string("hall", "name" + string(_i), _entries[_i].name);
        ini_write_real("hall", "points" + string(_i), _entries[_i].points);
        ini_write_real("hall", "words" + string(_i), _entries[_i].words);
    }
    ini_close();
}

/// True if a run with _points would get a place in the table.
function hall_qualifies(_entries, _points)
{
    if (_points <= 0) return false;
    var _n = array_length(_entries);
    return _n < HALL_SIZE || _points > _entries[_n - 1].points;
}

/// Inserts _entry below every entry with at least as many points (earlier runs keep ties),
/// trims the table to HALL_SIZE and returns the new entry's index, or -1 if it fell off.
function hall_insert(_entries, _entry)
{
    var _at = 0;
    while (_at < array_length(_entries) && _entries[_at].points >= _entry.points) _at++;
    array_insert(_entries, _at, _entry);
    if (array_length(_entries) > HALL_SIZE) array_resize(_entries, HALL_SIZE);
    return (_at < HALL_SIZE) ? _at : -1;
}

/// Keeps letters and digits only, like the site's usernames, up to NAME_MAX_LENGTH.
function clean_player_name(_text)
{
    var _out = "";
    for (var _i = 1; _i <= string_length(_text); _i++)
    {
        var _ch = string_char_at(_text, _i);
        var _code = ord(_ch);
        var _ok = (_code >= ord("a") && _code <= ord("z")) || (_code >= ord("A") && _code <= ord("Z")) || (_code >= ord("0") && _code <= ord("9"));
        if (_ok && string_length(_out) < NAME_MAX_LENGTH) _out += _ch;
    }
    return _out;
}

function player_name_load()
{
    ini_open(HALL_FILE);
    var _name = ini_read_string("player", "name", "");
    ini_close();
    return _name;
}

function player_name_save(_name)
{
    ini_open(HALL_FILE);
    ini_write_string("player", "name", _name);
    ini_close();
}
