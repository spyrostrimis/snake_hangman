/// Per-frame update: effects, then the arcade state machine.

frame++;
if (state_timer > 0) state_timer--;

// ---------- Effects ----------
for (var _i = array_length(popups) - 1; _i >= 0; _i--)
{
    var _pp = popups[_i];
    _pp.y -= 0.35;
    _pp.life -= 1;
    if (_pp.life <= 0) array_delete(popups, _i, 1);
}
for (var _i = array_length(pops) - 1; _i >= 0; _i--)
{
    var _pb = pops[_i];
    _pb.life -= 1;
    if (_pb.life <= 0) array_delete(pops, _i, 1);
}
for (var _i = 0; _i < array_length(bubbles); _i++) bubbles[_i].age++;
for (var _i = array_length(flyers) - 1; _i >= 0; _i--)
{
    var _f = flyers[_i];
    _f.t += 0.035;
    if (_f.t >= 1)
    {
        slot_filled[_f.slot] = true;
        array_delete(flyers, _i, 1);
    }
}
for (var _i = 0; _i < array_length(attract_bubbles); _i++)
{
    var _b = attract_bubbles[_i];
    _b.y -= _b.spd;
    if (_b.y < -12)
    {
        _b.y = 252;
        _b.x = random(320);
    }
}
if (hurry_flash > 0) hurry_flash--;

// ---------- Keys that work everywhere ----------
if (keyboard_check_pressed(ord("M")) && state != "initials")
{
    sound_on = !sound_on;
    if (!sound_on) music_stop();
    else if (state == "play") music_start();
}
if (keyboard_check_pressed(ord("C")) && state != "initials") crt_on = !crt_on;

var _confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);

switch (state)
{
    case "attract":
        if (_confirm) new_game();
        break;

    case "ready":
        if (state_timer <= 0)
        {
            state = "play";
            music_start();
        }
        break;

    case "paused":
        if (keyboard_check_pressed(ord("P")) || keyboard_check_pressed(vk_escape) || _confirm)
        {
            state = "play";
            music_start();
        }
        break;

    case "play":
        if (keyboard_check_pressed(ord("P")) || keyboard_check_pressed(vk_escape))
        {
            state = "paused";
            music_stop();
            break;
        }
        read_input();
        round_timer++;

        // Hurry up: after 40 seconds the music stops being polite.
        if (!hurry && round_timer > 60 * 40)
        {
            hurry = true;
            hurry_flash = 150;
            play_sfx(sfx.hurry);
            move_interval = max(4, move_interval - 2);
            spawn_fizz();
        }

        if (!is_undefined(treat))
        {
            treat.life--;
            if (treat.life <= 0) treat = undefined;
        }

        move_timer++;
        if (move_timer >= move_interval)
        {
            move_timer -= move_interval;
            advance_snake();
        }

        // Fizz touches the head.
        if (state == "play")
        {
            var _hx = snake[0].gx * CELL + CELL / 2;
            var _hy = snake[0].gy * CELL + CELL / 2;
            var _hit = false;
            with (obj_fizz) if (point_distance(px, py, _hx, _hy) < 10) _hit = true;
            if (_hit) lose_life("ZAPPED!", false);
        }
        break;

    case "clear":
        // Every bubble still on the field pops for a little bonus.
        if (state_timer mod 10 == 0 && array_length(bubbles) > 0)
        {
            var _b = bubbles[0];
            array_delete(bubbles, 0, 1);
            add_pop(cell_px(_b.gx), cell_py(_b.gy), _b.col);
            add_popup(cell_px(_b.gx), cell_py(_b.gy) - 6, "100", global.arc.yellow);
            add_score(100);
            play_sfx(sfx.pop);
        }
        if (state_timer <= 0 && array_length(flyers) == 0)
        {
            // Snapshot this round, set up the next, then scroll up to it.
            if (!surface_exists(surf_old)) surf_old = surface_create(field_w, field_h);
            surface_set_target(surf_old);
            draw_clear(c_black);
            draw_field(0, 0);
            surface_reset_target();
            round_num++;
            setup_round(true);
            state = "transition";
            state_timer = 70;
        }
        break;

    case "transition":
        if (state_timer <= 0) enter_ready(120);
        break;

    case "dying":
        if (state_timer <= 0)
        {
            if (lives <= 0)
            {
                state = "gameover";
                state_timer = 210;
                play_sfx(sfx.over);
                with (obj_fizz) instance_destroy();
            }
            else
            {
                if (new_word_after_death) setup_round(false);
                else reset_snake();
                enter_ready(100);
            }
        }
        break;

    case "gameover":
        if (state_timer <= 0 || (_confirm && state_timer < 150))
        {
            if (hiscore_qualifies(hiscores, score_now))
            {
                state = "initials";
                init_letters = [0, 0, 0];
                init_pos = 0;
                keyboard_lastchar = "";
            }
            else
            {
                state = "attract";
                state_timer = 0;
            }
        }
        break;

    case "initials":
        // Arcade initials: up/down change the letter, left/right move, or just type them.
        if (keyboard_check_pressed(vk_up))    { init_letters[init_pos] = (init_letters[init_pos] + 1) mod 26; play_sfx(sfx.tick); }
        if (keyboard_check_pressed(vk_down))  { init_letters[init_pos] = (init_letters[init_pos] + 25) mod 26; play_sfx(sfx.tick); }
        if (keyboard_check_pressed(vk_left))  init_pos = max(0, init_pos - 1);
        if (keyboard_check_pressed(vk_right)) init_pos = min(2, init_pos + 1);
        var _typed = string_upper(keyboard_lastchar);
        keyboard_lastchar = "";
        if (string_length(_typed) == 1 && ord(_typed) >= ord("A") && ord(_typed) <= ord("Z"))
        {
            init_letters[init_pos] = ord(_typed) - ord("A");
            init_pos = min(2, init_pos + 1);
            play_sfx(sfx.tick);
        }
        if (keyboard_check_pressed(vk_enter))
        {
            var _name = chr(ord("A") + init_letters[0]) + chr(ord("A") + init_letters[1]) + chr(ord("A") + init_letters[2]);
            hiscore_mine = hiscore_insert(hiscores, { initials: _name, points: score_now, round: round_num });
            hiscore_save(hiscores);
            play_sfx(sfx.extra);
            state = "attract";
            state_timer = 0;
            frame = 360;   // open the attract loop on the score table
        }
        break;
}
