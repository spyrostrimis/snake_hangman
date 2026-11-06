/// A letter in a glass bubble. obj_game sets ch when it builds the level.
event_inherited();
ch = "?";
on_collect = function(_by) { obj_game.on_letter(ch, x, y, _by); };
client_fx = function(_by)
{
    var _g = obj_game;
    if (word_has_letter(_g.word, ch))
    {
        _g.play_sfx(_g.sfx.right);
        _g.burst(x, y, make_colour_rgb(80, 255, 120), 18);
        if (instance_exists(_by)) _by.body_len = min(14, _by.body_len + 1);
    }
    else
    {
        _g.play_sfx(_g.sfx.wrong);
        _g.burst(x, y, make_colour_rgb(255, 60, 90), 18);
    }
};
