/// A rare egg: the snake gulps it down whole for two hearts.
event_inherited();
on_collect = function()
{
    var _g = obj_game;
    _g.hearts = min(5, _g.hearts + 2);
    _g.add_score(250, x, y - 16);
    _g.play_sfx(_g.sfx.gulp);
    _g.burst(x, y, make_colour_rgb(255, 240, 200), 10);
    _g.say("GULP! +2 HEARTS", 90);
    with (obj_player) gulp_t = 45;
};
