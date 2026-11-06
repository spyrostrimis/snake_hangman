/// A spinning red gem: points.
event_inherited();
spin = true;
on_collect = function(_by)
{
    var _g = obj_game;
    var _p = stats_of(_by);
    _p.gems++;
    _g.add_score(100, undefined, undefined, _p);
    _g.play_sfx(_g.sfx.gem);
    _g.burst(x, y, make_colour_rgb(255, 80, 120), 6);
};
