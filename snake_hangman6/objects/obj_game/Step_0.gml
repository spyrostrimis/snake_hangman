/// The run's state machine; the snake and creatures update themselves only during play.

frame++;
for (var _k = 0; _k < array_length(pl); _k++)
{
    var _msgs = pl[_k].messages;
    for (var _i = array_length(_msgs) - 1; _i >= 0; _i--)
    {
        // Only the oldest message counts down, so they show one after another.
        if (_i == 0) _msgs[0].life--;
        if (_msgs[_i].life <= 0) array_delete(_msgs, _i, 1);
    }
}
for (var _i = array_length(popups) - 1; _i >= 0; _i--)
{
    var _p = popups[_i];
    _p.y -= 0.6;
    _p.life -= 1;
    if (_p.life <= 0) array_delete(popups, _i, 1);
}

var _enter = menu_confirm();
var _pause = keyboard_check_pressed(ord("P")) || keyboard_check_pressed(vk_escape) || any_pad_pressed(gp_start);
var _typing = state == "online" && (online_mode == "type" || online_mode == "type_ip");
if (keyboard_check_pressed(ord("M")) && !_typing)
{
    sound_on = !sound_on;
    if (!sound_on) stop_music();
    else if (state == "play") play_music(lvl.music);
    else if (state == "title" || state == "credits") play_music("music_02.ogg");
}

switch (state)
{
    case "title":
        title_pan += 0.6;
        if (_enter) { play_sfx(sfx.select); new_game(); }
        else if (keyboard_check_pressed(ord("C"))) { play_sfx(sfx.select); state = "credits"; }
        else if (keyboard_check_pressed(ord("O"))) { play_sfx(sfx.select); state = "online"; online_mode = "menu"; }
        else if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("W")) || keyboard_check_pressed(ord("S")))
        {
            // One or two players.
            players_n = 3 - players_n;
            play_sfx(sfx.select);
        }
        else if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("A")) || keyboard_check_pressed(ord("D")))
        {
            // Choose the snake (with two players: which one player 1 gets).
            var _step = (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) ? -1 : 1;
            character = (character + _step + array_length(snakes)) mod array_length(snakes);
            play_sfx(sfx.select);
        }
        else
        {
            // Level select: number keys 1, 2, ... start a new game at that level.
            for (var _i = 0; _i < min(array_length(levels), 9); _i++)
            {
                if (keyboard_check_pressed(ord(string(_i + 1))) || keyboard_check_pressed(vk_numpad1 + _i))
                {
                    play_sfx(sfx.select);
                    new_game(_i);
                    break;
                }
            }
        }
        break;

    case "credits":
        title_pan += 0.6;
        if (_enter || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("C"))) { play_sfx(sfx.select); state = "title"; }
        break;

    case "online":
        // Step 2's connection test: host or join a room and see the link work.
        title_pan += 0.6;
        var _esc = keyboard_check_pressed(vk_escape);
        switch (online_mode)
        {
            case "menu":
                if (keyboard_check_pressed(ord("H")))
                {
                    play_sfx(sfx.select);
                    net.host();
                    clipboard_set_text(net.code);
                    online_mode = "room";
                }
                else if (keyboard_check_pressed(ord("J"))) { play_sfx(sfx.select); online_ip = ""; keyboard_string = ""; online_mode = "type"; }
                else if (keyboard_check_pressed(ord("I"))) { play_sfx(sfx.select); online_ip = ""; keyboard_string = ""; online_mode = "type_ip"; }
                else if (_esc) { play_sfx(sfx.select); state = "title"; }
                break;

            case "type_ip":
                var _t = "";
                for (var _i = 1; _i <= string_length(keyboard_string) && string_length(_t) < 15; _i++)
                {
                    var _c = string_char_at(keyboard_string, _i);
                    if (string_pos(_c, "0123456789.") > 0) _t += _c;
                }
                keyboard_string = _t;
                online_ip = _t;
                if (keyboard_check_pressed(vk_enter) && string_length(_t) >= 7) { play_sfx(sfx.select); keyboard_string = ""; online_mode = "type"; }
                else if (_esc) { play_sfx(sfx.select); online_mode = "menu"; }
                break;

            case "type":
                online_code = net_clean_code(keyboard_string);
                keyboard_string = online_code;
                if (keyboard_check_pressed(vk_enter) && string_length(online_code) == NET_CODE_LEN)
                {
                    play_sfx(sfx.select);
                    if (online_ip != "") net.join_ip(online_ip, online_code); else net.join(online_code);
                    online_mode = "room";
                }
                else if (_esc) { play_sfx(sfx.select); online_mode = "menu"; }
                break;

            case "room":
                // The lobby: once connected, the host picks the snakes and starts the game.
                if (net.state == "connected" && net_mode == "") net_begin(net.role);
                if (net.state != "connected" && net_mode != "") net_end();
                if (keyboard_check_pressed(vk_space) && net.state == "connected") { play_sfx(sfx.jump); net.send_wave(); }
                if (net_mode == "host")
                {
                    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(vk_right)) { character = 1 - character; play_sfx(sfx.select); }
                    if (keyboard_check_pressed(vk_enter)) { play_sfx(sfx.select); players_n = 2; new_game(0); }
                    else
                    {
                        for (var _i = 0; _i < min(array_length(levels), 9); _i++)
                        {
                            if (keyboard_check_pressed(ord(string(_i + 1))) || keyboard_check_pressed(vk_numpad1 + _i))
                            {
                                play_sfx(sfx.select);
                                players_n = 2;
                                new_game(_i);
                                break;
                            }
                        }
                    }
                }
                if (_esc) { play_sfx(sfx.select); net.stop(); net_end(); online_mode = "menu"; }
                break;
        }
        break;

    case "play":
        level_time++;
        if (net_mode != "")
        {
            // Online there is no pause: P / Esc asks whether to leave the game.
            if (_pause) net_quit_ask = !net_quit_ask;
            else if (net_quit_ask && keyboard_check_pressed(vk_enter)) net_leave();
            else if (net_mode == "host" && keyboard_check_pressed(ord("N"))) skip_level();
        }
        else if (_pause)
        {
            state = "paused";
            audio_pause_all();
        }
        else if (keyboard_check_pressed(ord("N"))) skip_level();
        break;

    case "paused":
        if (keyboard_check_pressed(ord("N"))) skip_level();
        else if (_pause || _enter)
        {
            state = "play";
            audio_resume_all();
        }
        break;

    case "clear":
        // Online, the joiner sees the host's tally and waits for the host to carry on.
        if (net_mode == "client") break;
        // Count each snake's bonus up like the old tally screens.
        var _counting = false;
        for (var _k = 0; _k < array_length(pl); _k++)
        {
            var _p = pl[_k];
            if (_p.shown < _p.bonus)
            {
                var _step = min(_p.bonus - _p.shown, 150);
                _p.shown += _step;
                _p.score_now += _step;
                _counting = true;
            }
        }
        if (_counting)
        {
            if (frame mod 4 == 0) play_sfx(sfx.gem);
        }
        else if (_enter)
        {
            level_index++;
            if (level_index >= array_length(levels))
            {
                state = "victory";
                play_music("music_02.ogg");
            }
            else start_level();
        }
        break;

    case "gameover":
    case "victory":
        if (_enter)
        {
            load_level(0, false);
            // Online, back to the room, still connected, for another go.
            if (net_mode != "") { state = "online"; online_mode = "room"; }
            else state = "title";
        }
        break;

    case "netlost":
        if (_enter) net_leave();
        break;
}
