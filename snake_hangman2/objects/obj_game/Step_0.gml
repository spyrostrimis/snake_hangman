/// Per-frame update: effects always tick; the snake moves only while playing.

frame++;

for (var _i = array_length(particles) - 1; _i >= 0; _i--)
{
    var _p = particles[_i];
    _p.px += _p.vx;
    _p.py += _p.vy;
    _p.vx *= 0.92;
    _p.vy *= 0.92;
    _p.life--;
    if (_p.life <= 0) array_delete(particles, _i, 1);
}
shake = max(0, shake - 0.6);
flash_alpha = max(0, flash_alpha - 0.03);
for (var _i = 0; _i < array_length(reveal_timers); _i++)
{
    if (reveal_timers[_i] > 0) reveal_timers[_i]--;
}
for (var _i = 0; _i < array_length(letters); _i++) letters[_i].age++;

var _confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
var _pause = keyboard_check_pressed(ord("P")) || keyboard_check_pressed(vk_escape);

switch (state)
{
    case "title":
        if (_confirm) start_round(true);
        break;

    case "won":
        if (_confirm)
        {
            level++;
            start_round(false);
        }
        break;

    case "lost":
        if (naming)
        {
            // Typing a name for the Hall of Fame: letters and digits only.
            keyboard_string = clean_player_name(keyboard_string);
            if (keyboard_check_pressed(vk_enter)) save_entry();
            else if (keyboard_check_pressed(vk_escape)) naming = false;
        }
        else if (_confirm)
        {
            start_round(true);
        }
        break;

    case "paused":
        if (_pause || _confirm) state = "play";
        break;

    case "play":
        if (_pause)
        {
            state = "paused";
            break;
        }
        read_input();
        move_timer++;
        if (move_timer >= move_interval)
        {
            move_timer -= move_interval;
            advance_snake();
        }
        break;
}
