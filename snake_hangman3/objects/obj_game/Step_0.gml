/// Per-frame update.

frame++;

// ---------- Effects ----------
shake = max(0, shake - 0.6);
hit   = max(0, hit - 0.035);
glow  = max(0, glow - 0.04);
punch = max(0, punch - 0.025);
if (banner_timer > 0) banner_timer--;
for (var _i = 0; _i < array_length(reveal_timers); _i++)
{
    if (reveal_timers[_i] > 0) reveal_timers[_i]--;
}
for (var _i = 0; _i < array_length(letters); _i++) letters[_i].age++;

// The warp starfield streams out of the middle of the field.
repeat (2)
{
    part_particles_create(ps_back, field_w / 2 + random_range(-30, 30), field_h / 2 + random_range(-20, 20), pt_warp, 1);
}
part_system_update(ps_back);
part_system_update(ps_front);

// Debris leaves a faint orange trail.
if (frame mod 3 == 0)
{
    with (obj_debris)
    {
        if (path_speed != 0) part_particles_create_colour(other.ps_front, x - other.grid_x, y - other.grid_y, other.pt_trail, global.site.artsy, 1);
    }
}

// ---------- Keys that work everywhere ----------
if (keyboard_check_pressed(ord("M"))) sound_on = !sound_on;

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
        if (_confirm) start_round(true);
        break;

    case "paused":
        if (_pause || _confirm)
        {
            state = "play";
            set_debris_moving(true);
        }
        break;

    case "play":
        if (_pause)
        {
            state = "paused";
            set_debris_moving(false);
            break;
        }
        read_input();
        if (!launched) break;

        // Han's hint orb: appears now and then, fades if nobody eats it.
        if (hint_timer > 0) hint_timer--;
        if (is_undefined(hint_orb))
        {
            if (hint_timer == 0)
            {
                hint_cooldown--;
                if (hint_cooldown <= 0)
                {
                    var _c = find_free_cell();
                    if (!is_undefined(_c))
                    {
                        hint_orb = { gx: _c.gx, gy: _c.gy, life: hint_orb_life };
                        play_sfx(sfx.spawn);
                        part_particles_create_colour(ps_front, cell_cx(_c.gx), cell_cy(_c.gy), pt_ring, global.site.han, 2);
                    }
                    hint_cooldown = 600;
                }
            }
        }
        else
        {
            hint_orb.life--;
            if (hint_orb.life <= 0) hint_orb = undefined;
        }

        move_timer++;
        if (move_timer >= move_interval)
        {
            move_timer -= move_interval;
            advance_snake();
        }

        // Debris: touching the head ends the run.
        if (state == "play")
        {
            var _hx = grid_x + cell_cx(snake[0].gx);
            var _hy = grid_y + cell_cy(snake[0].gy);
            var _struck = false;
            with (obj_debris)
            {
                if (point_distance(x, y, _hx, _hy) < debris_radius + 9) _struck = true;
            }
            if (_struck) lose_round("Space debris hit you");
        }
        break;
}
