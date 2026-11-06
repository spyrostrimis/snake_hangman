/// A carrot: one heart back.
event_inherited();
on_collect = function()
{
    var _g = obj_game;
    _g.hearts = min(5, _g.hearts + 1);
    _g.add_score(100, x, y - 16);
    _g.play_sfx(_g.sfx.carrot);
    _g.burst(x, y, make_colour_rgb(255, 160, 40), 10);
};
