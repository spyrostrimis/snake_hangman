/// Draw GUI at 640 x 360 (the single camera view size): the HUD during play (one per snake,
/// in its own half of the screen with two players), and the title, credits, pause, tally,
/// game-over and victory screens.

// Everything below is laid out in 640 x 360; this scales it to the 1280 x 720 GUI.
matrix_set(matrix_world, matrix_build(0, 0, 0, 0, 0, 0, 2, 2, 1));
var _blink = (frame div 25) mod 2 == 0;
var _playing = state == "play" || state == "paused" || state == "clear";
var _views = (_playing && split_on) ? 2 : 1;
var _vh = 360 / _views;     // height of each snake's part of the HUD

// Floating scores, from world positions to the screen, in every view.
for (var _v = 0; _v < _views; _v++)
{
    var _cam = view_camera[_v];
    var _cx = camera_get_view_x(_cam);
    var _cy = camera_get_view_y(_cam);
    var _sx = 640 / camera_get_view_width(_cam);
    var _sy = _vh / camera_get_view_height(_cam);
    for (var _i = 0; _i < array_length(popups); _i++)
    {
        var _p = popups[_i];
        var _px = (_p.x - _cx) * _sx;
        var _py = (_p.y - _cy) * _sy;
        if (_px > -40 && _px < 680 && _py > -20 && _py < _vh) hud_text(_px, _v * _vh + _py, _p.text, 0.4 * _sx, fa_center, c_white, min(1, _p.life / 20));
    }
}

if (state == "title" || state == "credits" || state == "online")
{
    draw_set_colour(c_black);
    draw_set_alpha((state == "online") ? 0.6 : 0.35);
    draw_rectangle(0, 0, 640, 360, false);
    draw_set_alpha(1);
}

switch (state)
{
    case "title":
        draw_sprite_ext(spr_logo, 0, 320, 88 + sin(frame * 0.04) * 4, 0.78, 0.78, sin(frame * 0.03) * 1.5, c_white, 1);
        hud_text(320, 158, "JUNGLE JAM", 0.7, fa_center, make_colour_rgb(255, 200, 80));

        // One or two players (Up / Down).
        var _sel = make_colour_rgb(255, 230, 120);
        var _dim = make_colour_rgb(150, 160, 200);
        hud_text(250, 184, "1 PLAYER", 0.36, fa_center, players_n == 1 ? _sel : _dim);
        hud_text(390, 184, "2 PLAYERS", 0.36, fa_center, players_n == 2 ? _sel : _dim);
        var _fx = (players_n == 1) ? 250 : 390;
        draw_set_colour(_blink ? _sel : make_colour_rgb(190, 150, 60));
        draw_roundrect(_fx - 58, 181, _fx + 58, 198, true);
        draw_set_colour(c_white);

        var _arrow_col = _blink ? c_white : make_colour_rgb(190, 210, 255);
        if (players_n == 1)
        {
            // Snake choice: the chosen snake's head between arrows, its name and its power.
            var _sn = snakes[character];
            title_arrow(196, 212, -1, _arrow_col);
            title_arrow(444, 212, 1, _arrow_col);
            draw_sprite_ext(_sn.head, 0, 224, 211, 0.8, 0.8, 0, c_white, 1);
            hud_text(334, 203, _sn.name, 0.4, fa_center, _sn.colour);
            body_text(334, 219, _sn.power, c_white, fa_center);
            if (_blink) hud_text(320, 238, "PRESS ENTER TO START", 0.42, fa_center);
            body_text(320, 256, "Arrows: move    Z / Space: jump    Left / Right on this screen: choose snake", c_white, fa_center);
            body_text(320, 271, "X: tongue    Hold Shift: roll    C: boost (knocks out creatures)    Down + jump: drop through logs", c_white, fa_center);
        }
        else
        {
            // Two players: P1 on the top half, P2 on the bottom; Left / Right swaps the snakes.
            var _s1 = snakes[character];
            var _s2 = snakes[1 - character];
            title_arrow(140, 212, -1, _arrow_col);
            title_arrow(500, 212, 1, _arrow_col);
            draw_sprite_ext(_s1.head, 0, 172, 211, 0.7, 0.7, 0, c_white, 1);
            hud_text(232, 203, "P1 " + string_replace(_s1.name, " SNAKE", ""), 0.34, fa_center, _s1.colour);
            draw_sprite_ext(_s2.head, 0, 372, 211, 0.7, 0.7, 0, c_white, 1);
            hud_text(432, 203, "P2 " + string_replace(_s2.name, " SNAKE", ""), 0.34, fa_center, _s2.colour);
            body_text(320, 219, "Shared word, own lives and misses. P1 plays on top, P2 below.", c_white, fa_center);
            if (_blink) hud_text(320, 238, "PRESS ENTER TO START", 0.42, fa_center);
            body_text(320, 256, "P1: A D move   W jump   S down   F tongue   hold G roll   H boost", _s1.colour, fa_center);
            body_text(320, 271, "P2: Arrows move / jump / down   J tongue   hold K roll   L boost", _s2.colour, fa_center);
        }
        body_text(320, 286, "Gamepads: stick, A jump, X tongue, hold RB roll, B boost.  Grab the letters to open the door!", make_colour_rgb(255, 230, 140), fa_center);
        body_text(320, 302, "Up / Down: players    O: online    C: credits    M: music on/off    P: pause", make_colour_rgb(190, 210, 255), fa_center);
        body_text(320, 317, "1-" + string(min(array_length(levels), 9)) + ": start at that level    N (in game): skip level", make_colour_rgb(190, 210, 255), fa_center);
        body_text(320, 334, "A tribute to the 90s PC platformers. Made with GameMaker.", make_colour_rgb(170, 190, 230), fa_center);
        break;

    case "online":
        hud_text(320, 22, "ONLINE", 0.8, fa_center, make_colour_rgb(255, 200, 80));
        body_text(320, 62, "Connection test: host or join a room, and see the link between the two PCs work.", make_colour_rgb(190, 210, 255), fa_center);
        var _gold = make_colour_rgb(255, 230, 120);
        switch (online_mode)
        {
            case "menu":
                hud_text(320, 110, "H: HOST A ROOM", 0.5, fa_center, _gold);
                hud_text(320, 145, "J: JOIN WITH A CODE", 0.5, fa_center, _gold);
                hud_text(320, 180, "I: JOIN BY IP", 0.5, fa_center, _gold);
                body_text(320, 216, "Join by IP is the fallback when the code doesn't connect: type the host's IP", c_white, fa_center);
                body_text(320, 232, "(for example its Tailscale address), then the room code.", c_white, fa_center);
                body_text(320, 300, "Esc: back", make_colour_rgb(190, 210, 255), fa_center);
                break;

            case "type_ip":
                hud_text(320, 120, "HOST IP", 0.5, fa_center);
                hud_text(320, 160, online_ip + (_blink ? "-" : " "), 0.7, fa_center, _gold);
                body_text(320, 220, "Type the IP, then Enter.    Esc: back", c_white, fa_center);
                break;

            case "type":
                hud_text(320, 120, "ROOM CODE", 0.5, fa_center);
                var _shown = online_code;
                while (string_length(_shown) < NET_CODE_LEN) _shown += "-";
                hud_text(320, 158, _shown, 1, fa_center, _gold);
                if (online_ip != "") body_text(320, 214, "Joining " + online_ip, c_white, fa_center);
                body_text(320, 232, "Type the 5-character code your friend sees, then Enter.    Esc: back", c_white, fa_center);
                break;

            case "room":
                var _n = net;
                if (_n.role == "host")
                {
                    body_text(320, 92, "Your room code (copied to the clipboard):", c_white, fa_center);
                    hud_text(320, 108, _n.code, 1.1, fa_center, _gold);
                }
                else hud_text(320, 108, "ROOM " + _n.code, 0.7, fa_center, _gold);
                var _col = (_n.state == "connected") ? make_colour_rgb(140, 255, 140) : ((_n.state == "failed" || _n.state == "lost") ? make_colour_rgb(255, 130, 140) : c_white);
                body_text(320, 168, _n.status, _col, fa_center);
                if (_n.detail != "") body_text(320, 186, _n.detail, make_colour_rgb(255, 230, 140), fa_center);
                if (_n.state == "connected")
                {
                    hud_text(320, 206, "PING " + ((_n.ping_ms < 0) ? "..." : string(round(_n.ping_ms)) + " MS"), 0.5, fa_center, make_colour_rgb(140, 255, 140));
                    body_text(320, 236, "Linked over " + _n.link + " with " + _n.peer_ip + ":" + string(_n.peer_port), c_white, fa_center);
                    body_text(320, 256, "Space: wave to your friend    You waved " + string(_n.waves_out) + "    Your friend waved " + string(_n.waves_in), _gold, fa_center);
                }
                var _me = (_n.pub_ip != "") ? _n.pub_ip + ":" + string(_n.pub_port) : "unknown";
                body_text(320, 296, "Your internet address: " + _me + "    Local port: " + string(_n.lport), make_colour_rgb(170, 190, 230), fa_center);
                body_text(320, 318, "Esc: leave the room", make_colour_rgb(190, 210, 255), fa_center);
                break;
        }
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
        // One HUD per snake, each in its own part of the screen (the whole of it when alone).
        for (var _k = 0; _k < array_length(pl); _k++)
        {
            var _p = pl[_k];
            var _oy = _k * _vh;

            // Score, top left, seven digits like the old games.
            var _sc = string(_p.score_now);
            while (string_length(_sc) < 7) _sc = "0" + _sc;
            hud_text(10, _oy + 6, _sc, 0.62);
            draw_sprite_ext(spr_gem, 0, 18, _oy + 44, 0.8, 0.8, 0, c_white, 1);
            hud_text(30, _oy + 35, "x" + string(_p.gems), 0.42);

            // Hearts, top right.
            for (var _i = 0; _i < 5; _i++)
            {
                draw_sprite_ext(spr_heart, 0, 626 - _i * 22, _oy + 16, 1, 1, 0, (_i < _p.hearts) ? c_white : make_colour_rgb(50, 40, 60), (_i < _p.hearts) ? 1 : 0.6);
            }

            // The shared word, top centre: a bubble per letter.
            var _n = string_length(word);
            var _wx = 320 - (_n * 26) / 2 + 13;
            for (var _i = 0; _i < _n; _i++)
            {
                var _ch = string_char_at(word, _i + 1);
                var _found = letter_is_guessed(guessed, _ch);
                draw_sprite_ext(spr_orb, 0, _wx + _i * 26, _oy + 22, 0.72, 0.72, 0, _found ? c_white : make_colour_rgb(90, 100, 140), 1);
                hud_text(_wx + _i * 26, _oy + 13, _found ? _ch : "?", 0.42, fa_center, _found ? c_white : make_colour_rgb(160, 170, 210));
            }

            // A boss's name and health bar, under the word.
            if (instance_exists(boss) && boss.active)
            {
                var _bw = 220;
                var _bx = 320 - _bw / 2;
                hud_text(320, _oy + 42, boss.boss_name, 0.36, fa_center, make_colour_rgb(255, 160, 120));
                draw_set_colour(make_colour_rgb(20, 16, 40));
                draw_roundrect(_bx - 3, _oy + 60, _bx + _bw + 3, _oy + 72, false);
                var _f = max(0, boss.hp / boss.hp_max);
                draw_rectangle_colour(_bx, _oy + 63, _bx + _bw * _f, _oy + 69, c_red, make_colour_rgb(255, 200, 60), make_colour_rgb(255, 200, 60), c_red, false);
                draw_set_colour(c_white);
                draw_roundrect(_bx - 3, _oy + 60, _bx + _bw + 3, _oy + 72, true);
            }

            // Lives, bottom left: this snake's own head.
            var _by = _oy + _vh;
            draw_sprite_ext(_p.skin.head, 0, 24, _by - 20, 0.75, 0.75, 0, c_white, 1);
            hud_text(42, _by - 34, "x" + string(_p.lives_left), 0.5);

            // Misses, bottom right: this snake's wrong letters with a red cross.
            hud_text(452, _by - 30, "MISSES", 0.34, fa_left, make_colour_rgb(255, 170, 170));
            for (var _i = 0; _i < MAX_MISSES; _i++)
            {
                var _mx = 520 + _i * 19;
                draw_set_colour(make_colour_rgb(20, 24, 60));
                draw_set_alpha(0.6);
                draw_roundrect(_mx - 8, _by - 34, _mx + 8, _by - 12, false);
                draw_set_alpha(1);
                if (_i < string_length(_p.miss_letters))
                {
                    hud_text(_mx, _by - 33, string_char_at(_p.miss_letters, _i + 1), 0.4, fa_center, make_colour_rgb(200, 200, 220));
                    draw_set_colour(make_colour_rgb(255, 40, 60));
                    draw_line_width(_mx - 7, _by - 14, _mx + 7, _by - 32, 2);
                }
            }

            // Out of lives: say so over this snake's half, which now follows the other snake.
            if (_p.out)
            {
                draw_set_colour(c_black);
                draw_set_alpha(0.35);
                draw_rectangle(0, _oy, 640, _oy + _vh, false);
                draw_set_alpha(1);
                hud_text(320, _oy + _vh / 2 - 22, _p.skin.name + " IS OUT", 0.6, fa_center, make_colour_rgb(255, 120, 130));
                body_text(320, _oy + _vh / 2 + 4, "Back with one life on the next level", c_white, fa_center);
            }
            // Messages, one at a time, in the middle of this snake's screen.
            else if (array_length(_p.messages) > 0 && state == "play")
            {
                var _m = _p.messages[0];
                hud_text(320, _oy + ((_views == 1) ? 120 : 84), _m.text, (_views == 1) ? 0.5 : 0.42, fa_center, c_white, min(1, _m.life / 20));
            }
        }

        // The line between the two halves.
        if (_views == 2)
        {
            draw_set_colour(make_colour_rgb(16, 26, 64));
            draw_rectangle(0, 178, 640, 181, false);
            draw_set_colour(c_white);
        }

        if (state == "paused")
        {
            draw_set_colour(c_black);
            draw_set_alpha(0.5);
            draw_rectangle(0, 0, 640, 360, false);
            draw_set_alpha(1);
            hud_text(320, 150, "PAUSED", 0.9, fa_center);
            body_text(320, 200, "Press P to carry on    N: skip level", c_white, fa_center);
        }
        if (state == "clear")
        {
            draw_set_colour(make_colour_rgb(10, 20, 60));
            draw_set_alpha(0.7);
            draw_roundrect(120, 80, 520, 290, false);
            draw_set_alpha(1);
            hud_text(320, 96, "LEVEL COMPLETE!", 0.8, fa_center, make_colour_rgb(160, 255, 140));
            hud_text(320, 140, word, 0.7, fa_center, make_colour_rgb(255, 220, 90));
            body_text(320, 178, "Letters x1000, time bonus, and 500 for every miss you saved", c_white, fa_center);
            var _done = true;
            for (var _k = 0; _k < array_length(pl); _k++)
            {
                var _p = pl[_k];
                if (_p.shown < _p.bonus) _done = false;
                var _label = (array_length(pl) == 1) ? "BONUS " : string_replace(_p.skin.name, " SNAKE", "") + " BONUS ";
                hud_text(320, 200 + _k * 22, _label + string(_p.shown), 0.5, fa_center, (array_length(pl) == 1) ? c_white : _p.skin.colour);
            }
            if (_done && _blink) hud_text(320, 254, "PRESS ENTER", 0.5, fa_center);
        }
        break;

    case "gameover":
        hud_text(320, 130, "GAME OVER", 1.1, fa_center, make_colour_rgb(255, 90, 110));
        hud_text(320, 186, "THE WORD WAS " + word, 0.5, fa_center);
        for (var _k = 0; _k < array_length(pl); _k++)
        {
            var _p = pl[_k];
            var _label = (array_length(pl) == 1) ? "SCORE " : string_replace(_p.skin.name, " SNAKE", "") + " ";
            hud_text(320, 214 + _k * 24, _label + string(_p.score_now), 0.5, fa_center, (array_length(pl) == 1) ? c_white : _p.skin.colour);
        }
        if (_blink) hud_text(320, 274, "PRESS ENTER", 0.5, fa_center);
        break;

    case "victory":
        draw_set_colour(c_black);
        draw_set_alpha(0.4);
        draw_rectangle(0, 0, 640, 360, false);
        draw_set_alpha(1);
        hud_text(320, 110, "YOU DID IT!", 1.1, fa_center, make_colour_rgb(160, 255, 140));
        body_text(320, 170, "Every word found, every door open. The jungle is safe!", c_white, fa_center);
        for (var _k = 0; _k < array_length(pl); _k++)
        {
            var _p = pl[_k];
            var _label = (array_length(pl) == 1) ? "SCORE " : string_replace(_p.skin.name, " SNAKE", "") + " ";
            hud_text(320, 200 + _k * 24, _label + string(_p.score_now), 0.6, fa_center, (array_length(pl) == 1) ? c_white : _p.skin.colour);
        }
        if (_blink) hud_text(320, 270, "PRESS ENTER", 0.5, fa_center);
        break;
}
matrix_set(matrix_world, matrix_build_identity());
