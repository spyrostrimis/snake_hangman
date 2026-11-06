/// A letter in a glass bubble. obj_game sets ch when it builds the level.
event_inherited();
ch = "?";
on_collect = function(_by) { obj_game.on_letter(ch, x, y, _by); };
