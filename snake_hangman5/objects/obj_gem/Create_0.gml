/// A spinning red gem: points.
event_inherited();
spin = true;
on_collect = function()
{
    var _g = obj_game;
    _g.gems++;
    _g.add_score(100);
    _g.play_sfx(_g.sfx.gem);
    _g.burst(x, y, make_colour_rgb(255, 80, 120), 6);
};
