/// The door, and above it the word so far, like a sign: "_ A _ _ E _".
draw_self();
var _g = obj_game;
var _sign = "";
for (var _i = 1; _i <= string_length(_g.word); _i++)
{
    var _ch = string_char_at(_g.word, _i);
    _sign += letter_is_guessed(_g.guessed, _ch) ? _ch : "-";
}
hud_text(x, y - 92, _sign, 0.42, fa_center, open ? make_colour_rgb(160, 255, 160) : c_white);
hud_text(x, y - 76, open ? "OPEN!" : "EXIT", 0.32, fa_center);
