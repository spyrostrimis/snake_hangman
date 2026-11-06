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
if (keyboard_check_pressed(ord("M")))
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

    case "play":
        level_time++;
        if (_pause)
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
            state = "title";
        }
        break;
}
