/// A rare egg: the snake gulps it down whole for two hearts.
event_inherited();
on_collect = function(_by)
{
    var _g = obj_game;
    var _p = stats_of(_by);
    _p.hearts = min(5, _p.hearts + 2);
    _g.add_score(250, x, y - 16, _p);
    _g.play_sfx(_g.sfx.gulp);
    _g.burst(x, y, make_colour_rgb(255, 240, 200), 10);
    _g.say("GULP! +2 HEARTS", 90, _p);
    if (instance_exists(_by)) _by.gulp_t = 45;
};
client_fx = function(_by)
{
    obj_game.play_sfx(obj_game.sfx.gulp);
    obj_game.burst(x, y, make_colour_rgb(255, 240, 200), 10);
    if (instance_exists(_by)) _by.gulp_t = 45;
};
