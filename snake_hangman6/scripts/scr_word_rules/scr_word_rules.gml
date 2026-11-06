/// Hangman rules for Snake / Hangman.
/// Pure functions: they read only their arguments, never the game object.
/// A round is a hidden word plus the string of letters eaten so far.

#macro MAX_MISSES 6

/// The words a round can hide. All uppercase A-Z.
function game_word_list()
{
    return [
        "DOOR", "ROBOT", "PLANET", "GARDEN", "WINDOW", "PUZZLE", "RIVER",
        "CASTLE", "JUNGLE", "ROCKET", "MIRROR", "LANTERN", "THUNDER",
        "PENCIL", "BRIDGE", "WIZARD", "COFFEE", "VIOLIN", "SHADOW", "KITTEN"
    ];
}

/// True if _letter (one uppercase character) appears in _word.
function word_has_letter(_word, _letter)
{
    return string_pos(_letter, _word) > 0;
}

/// How many times _letter appears in _word.
function word_count_letter(_word, _letter)
{
    return string_count(_letter, _word);
}

/// True if _letter is among the letters already eaten.
function letter_is_guessed(_guessed, _letter)
{
    return string_pos(_letter, _guessed) > 0;
}

/// True once every letter of _word has been eaten.
function word_is_solved(_word, _guessed)
{
    var _n = string_length(_word);
    for (var _i = 1; _i <= _n; _i++)
    {
        if (!letter_is_guessed(_guessed, string_char_at(_word, _i))) return false;
    }
    return true;
}

/// Misses so far: eaten letters that are not in the word.
function word_miss_count(_word, _guessed)
{
    var _misses = 0;
    var _n = string_length(_guessed);
    for (var _i = 1; _i <= _n; _i++)
    {
        if (!word_has_letter(_word, string_char_at(_guessed, _i))) _misses++;
    }
    return _misses;
}

/// The distinct letters of _word not yet eaten, as an array of one-letter strings.
function word_hidden_letters(_word, _guessed)
{
    var _seen = "";
    var _hidden = [];
    var _n = string_length(_word);
    for (var _i = 1; _i <= _n; _i++)
    {
        var _ch = string_char_at(_word, _i);
        if (letter_is_guessed(_guessed, _ch) || string_pos(_ch, _seen) > 0) continue;
        _seen += _ch;
        array_push(_hidden, _ch);
    }
    return _hidden;
}
