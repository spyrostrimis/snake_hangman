/// Draw GUI at 640 x 360 (the camera view size): the HUD during play, and the title,
/// credits, pause, tally, game-over and victory screens.

// Everything below is laid out in 640 x 360; this scales it to the 1280 x 720 GUI.
matrix_set(matrix_world, matrix_build(0, 0, 0, 0, 0, 0, 2, 2, 1));
var _blink = (frame div 25) mod 2 == 0;
var _cx = camera_get_view_x(view_camera[0]);
var _cy = camera_get_view_y(view_camera[0]);

// Floating scores, from world positions to the screen.
for (var _i = 0; _i < array_length(popups); _i++)
{
    var _p = popups[_i];
    hud_text(_p.x - _cx, _p.y - _cy, _p.text, 0.4, fa_center, c_white, min(1, _p.life / 20));
}

if (state == "title" || state == "credits")
{
    draw_set_colour(c_black);
    draw_set_alpha(0.35);
    draw_rectangle(0, 0, 640, 360, false);
    draw_set_alpha(1);
}

switch (state)
{
    case "title":
        draw_sprite_ext(spr_logo, 0, 320, 92 + sin(frame * 0.04) * 4, 0.82, 0.82, sin(frame * 0.03) * 1.5, c_white, 1);
        hud_text(320, 168, "JUNGLE JAM", 0.75, fa_center, make_colour_rgb(255, 200, 80));
        if (_blink) hud_text(320, 206, "PRESS ENTER TO START", 0.55, fa_center);
        body_text(320, 238, "Arrows: move    Z / Space: jump (hold in the air to tail-spin)", c_white, fa_center);
        body_text(320, 256, "X: tongue lash    C / Shift: curl into a ball    Down + jump: drop through logs", c_white, fa_center);
        body_text(320, 274, "Grab the letters of the secret word to open the exit door. Wrong letters are misses!", make_colour_rgb(255, 230, 140), fa_center);
        body_text(320, 300, "C: credits    M: music on/off    P: pause", make_colour_rgb(190, 210, 255), fa_center);
        body_text(320, 334, "A tribute to the 90s PC platformers. Made with GameMaker.", make_colour_rgb(170, 190, 230), fa_center);
        break;

    case "credits":
        hud_text(320, 24, "CREDITS", 0.8, fa_center, make_colour_rgb(255, 200, 80));
        body_text(320, 68, "Game, art and code: Spyros Trimis and Claude, made with GameMaker", c_white, fa_center);
        body_text(320, 96, "Music: \"Jazz Jackrabbit 2 - 20th Anniversary Tribute Album\" by the JJ20 Team", make_colour_rgb(255, 230, 140), fa_center);
        body_text(320, 114, "jj20.bandcamp.com - licensed CC BY-NC-ND 4.0, used unchanged", make_colour_rgb(255, 230, 140), fa_center);
        body_text(320, 140, "Tubelectric: Megahit    Jazz Jackrabbit 2 Theme: Zyrit    Carrotus: Vincenzo", c_white, fa_center);
        body_text(320, 158, "Pull Back the Bass, Water Level: BPStudio    Dark Groove: Gridscape", c_white, fa_center);
        body_text(320, 176, "Bonus Stage: Bitrotator    Labratory Level: SIDNIFY    Jazz be Damned: Ziona", c_white, fa_center);
        body_text(320, 202, "The album covers music by Alexander Brandon; Jazz Jackrabbit 2 belongs to Epic Games.", make_colour_rgb(190, 210, 255), fa_center);
        body_text(320, 220, "This game is a free, unofficial fan tribute and is not endorsed by Epic Games.", make_colour_rgb(190, 210, 255), fa_center);
        if (_blink) hud_text(320, 290, "PRESS ENTER", 0.5, fa_center);
        break;

    case "play":
    case "paused":
    case "clear":
        // Score, top left, seven digits like the old games.
        var _sc = string(score_now);
        while (string_length(_sc) < 7) _sc = "0" + _sc;
        hud_text(10, 6, _sc, 0.62);
        draw_sprite_ext(spr_gem, 0, 18, 44, 0.8, 0.8, 0, c_white, 1);
        hud_text(30, 35, "x" + string(gems), 0.42);

        // Hearts, top right.
        for (var _i = 0; _i < 5; _i++)
        {
            draw_sprite_ext(spr_heart, 0, 626 - _i * 22, 16, 1, 1, 0, (_i < hearts) ? c_white : make_colour_rgb(50, 40, 60), (_i < hearts) ? 1 : 0.6);
        }

        // The word, top centre: a bubble per letter.
        var _n = string_length(word);
        var _wx = 320 - (_n * 26) / 2 + 13;
        for (var _i = 0; _i < _n; _i++)
        {
            var _ch = string_char_at(word, _i + 1);
            var _found = letter_is_guessed(guessed, _ch);
            draw_sprite_ext(spr_orb, 0, _wx + _i * 26, 22, 0.72, 0.72, 0, _found ? c_white : make_colour_rgb(90, 100, 140), 1);
            hud_text(_wx + _i * 26, 13, _found ? _ch : "?", 0.42, fa_center, _found ? c_white : make_colour_rgb(160, 170, 210));
        }

        // Lives, bottom left.
        draw_sprite_ext(spr_snake_head, 0, 24, 340, 0.75, 0.75, 0, c_white, 1);
        hud_text(42, 326, "x" + string(lives), 0.5);

        // Misses, bottom right: the wrong letters with a red cross.
        hud_text(452, 330, "MISSES", 0.34, fa_left, make_colour_rgb(255, 170, 170));
        for (var _i = 0; _i < MAX_MISSES; _i++)
        {
            var _mx = 520 + _i * 19;
            draw_set_colour(make_colour_rgb(20, 24, 60));
            draw_set_alpha(0.6);
            draw_roundrect(_mx - 8, 326, _mx + 8, 348, false);
            draw_set_alpha(1);
            if (_i < string_length(miss_letters))
            {
                hud_text(_mx, 327, string_char_at(miss_letters, _i + 1), 0.4, fa_center, make_colour_rgb(200, 200, 220));
                draw_set_colour(make_colour_rgb(255, 40, 60));
                draw_line_width(_mx - 7, 346, _mx + 7, 328, 2);
            }
        }

        // Messages, one at a time, middle of the screen.
        if (array_length(messages) > 0 && state == "play")
        {
            var _m = messages[0];
            var _a = min(1, _m.life / 20);
            hud_text(320, 120, _m.text, 0.5, fa_center, c_white, _a);
        }

        if (state == "paused")
        {
            draw_set_colour(c_black);
            draw_set_alpha(0.5);
            draw_rectangle(0, 0, 640, 360, false);
            draw_set_alpha(1);
            hud_text(320, 150, "PAUSED", 0.9, fa_center);
            body_text(320, 200, "Press P to carry on", c_white, fa_center);
        }
        if (state == "clear")
        {
            draw_set_colour(make_colour_rgb(10, 20, 60));
            draw_set_alpha(0.7);
            draw_roundrect(120, 80, 520, 290, false);
            draw_set_alpha(1);
            hud_text(320, 96, "LEVEL COMPLETE!", 0.8, fa_center, make_colour_rgb(160, 255, 140));
            hud_text(320, 140, word, 0.7, fa_center, make_colour_rgb(255, 220, 90));
            body_text(320, 184, "Letters x1000, time bonus, and 500 for every miss you saved", c_white, fa_center);
            hud_text(320, 206, "BONUS " + string(tally.shown), 0.6, fa_center);
            if (tally.shown >= tally.bonus && _blink) hud_text(320, 250, "PRESS ENTER", 0.5, fa_center);
        }
        break;

    case "gameover":
        hud_text(320, 130, "GAME OVER", 1.1, fa_center, make_colour_rgb(255, 90, 110));
        hud_text(320, 186, "THE WORD WAS " + word, 0.5, fa_center);
        hud_text(320, 214, "SCORE " + string(score_now), 0.5, fa_center);
        if (_blink) hud_text(320, 260, "PRESS ENTER", 0.5, fa_center);
        break;

    case "victory":
        draw_set_colour(c_black);
        draw_set_alpha(0.4);
        draw_rectangle(0, 0, 640, 360, false);
        draw_set_alpha(1);
        hud_text(320, 110, "YOU DID IT!", 1.1, fa_center, make_colour_rgb(160, 255, 140));
        body_text(320, 170, "Every word found, every door open. The jungle is safe!", c_white, fa_center);
        hud_text(320, 200, "SCORE " + string(score_now), 0.6, fa_center);
        if (_blink) hud_text(320, 260, "PRESS ENTER", 0.5, fa_center);
        break;
}
matrix_set(matrix_world, matrix_build_identity());
