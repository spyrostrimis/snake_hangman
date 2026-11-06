/// Controls: arrows / A D to move, Z / Space / Up to jump (hold in the air to tail-spin),
/// X / J to lash the tongue, C / Shift to curl into a ball, Down + jump to drop through logs.

var _g = obj_game;
if (_g.state != "play") exit;

var _left  = keyboard_check(vk_left)  || keyboard_check(ord("A"));
var _right = keyboard_check(vk_right) || keyboard_check(ord("D"));
var _down  = keyboard_check(vk_down)  || keyboard_check(ord("S"));
var _jump_pressed = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"));
var _jump_held    = keyboard_check(ord("Z")) || keyboard_check(vk_space) || keyboard_check(vk_up) || keyboard_check(ord("W"));
var _tongue = keyboard_check_pressed(ord("X")) || keyboard_check_pressed(ord("J"));
var _ball_key = keyboard_check_pressed(ord("C")) || keyboard_check_pressed(vk_shift);

if (invuln > 0) invuln--;
if (blink > 0) blink--; else if (irandom(180) == 0) blink = 8;

// ---------- Curl into a ball (and back) ----------
if (_ball_key && tongue_t == 0)
{
    ball = !ball;
    _g.play_sfx(_g.sfx.ball);
    if (ball && abs(vx) < 2) vx = facing * 3;
}

// ---------- Run ----------
var _dir = _right - _left;
var _max = ball ? ball_max : run_max;
if (_dir != 0)
{
    vx += _dir * (ball ? 0.25 : run_accel) * (on_ground ? 1 : 0.7);
    if (tongue_t == 0) facing = _dir;
}
else if (on_ground)
{
    vx = ball ? vx * 0.985 : approach(vx, 0, 0.4);
}
vx = clamp(vx, -_max, _max);
if (ball)
{
    ball_angle -= vx * 4;
    // A ball that has nearly stopped uncurls by itself.
    if (abs(vx) < 0.6 && on_ground) { if (++ball_slow > 40) ball = false; } else ball_slow = 0;
}

// ---------- Jump, coyote time, jump buffer, drop through logs ----------
if (on_ground) coyote = 6; else if (coyote > 0) coyote--;
if (_jump_pressed) jump_buffer = 6; else if (jump_buffer > 0) jump_buffer--;
drop_through = false;
if (jump_buffer > 0 && coyote > 0)
{
    if (_down && on_ground && row_oneway(y + hh + 2, x - hw + 1, x + hw - 1) && !row_blocked(y + hh + 2, x - hw + 1, x + hw - 1))
    {
        drop_through = true;
        y += 2;
    }
    else
    {
        vy = -jump_speed * (ball ? 1.08 : 1);
        _g.play_sfx(_g.sfx.jump);
        part_particles_create(_g.ps, x, y + hh, _g.pt_dust, 4);
    }
    jump_buffer = 0;
    coyote = 0;
}
// Let go early for a shorter jump.
if (!_jump_held && vy < -3) vy *= 0.6;

// ---------- Gravity and the tail-spin glide ----------
vy = min(vy + gravity_pull, fall_max);
copter = !ball && !on_ground && _jump_held && vy > 0;
if (copter)
{
    vy = min(vy, 1.2);
    if (_g.frame mod 8 == 0) _g.play_sfx(_g.sfx.copter);
}

// ---------- A rolling ball smashes cracked blocks ----------
if (ball)
{
    var _ahead = x + sign(vx) * (hw + 6);
    for (var _yy = y - hh + 2; _yy <= y + hh - 2; _yy += 10)
    {
        if (abs(vx) > 2.5 && tile_at(_ahead, _yy) == T_CRACK) smash(floor(_ahead / TILE), floor(_yy / TILE));
    }
    if (vy > 2) for (var _xx = x - hw + 2; _xx <= x + hw - 2; _xx += 9) if (tile_at(_xx, y + hh + 4) == T_CRACK) smash(floor(_xx / TILE), floor((y + hh + 4) / TILE));
}

// ---------- Move ----------
var _was_air = !on_ground;
var _fall_speed = vy;
entity_move();
if (on_ground && _was_air && _fall_speed > 4) part_particles_create(_g.ps, x, y + hh, _g.pt_dust, 5);
if (ball && hit_wall != 0) { vx = -hit_wall * 2; _g.play_sfx(_g.sfx.ball); }

// The level's bottom is a bottomless pit.
if (y > _g.lvl_h * TILE + 40)
{
    _g.player_died();
    exit;
}
if (touching_spikes() && invuln == 0)
{
    vy = -7;
    take_hit();
}

// ---------- Tongue: lash out, hold, pull back ----------
if (_tongue && tongue_t == 0 && !ball)
{
    tongue_t = 1;
    _g.play_sfx(_g.sfx.tongue);
}
if (tongue_t > 0)
{
    tongue_t++;
    tongue_len = (tongue_t <= 7) ? tongue_t / 7 * 104 : (tongue_t <= 11 ? 104 : max(0, 104 - (tongue_t - 11) / 8 * 104));
    if (tongue_t > 19) { tongue_t = 0; tongue_len = 0; }
    var _mx = mouth_x();
    var _my = mouth_y();
    var _tip = _mx + facing * tongue_len;
    if (tongue_t <= 11)
    {
        // Anything the tongue touches: creatures are knocked out, items are pulled in.
        with (obj_enemy) if (point_segment_distance(x, y, _mx, _my, _tip, _my) < hh + 4) kill();
        with (obj_pickup) if (!grabbed && point_segment_distance(x, y, _mx, _my, _tip, _my) < 16) { grabbed = true; _g.play_sfx(_g.sfx.slurp); }
    }
}

// ---------- Creatures ----------
with (obj_enemy)
{
    if (abs(x - other.x) < hw + other.hw && abs(y - other.y) < hh + other.hh)
    {
        if (other.ball) kill();
        else if (other.vy > 1.5 && other.y < y - 4)
        {
            kill();
            other.vy = -7;
        }
        else if (other.invuln == 0) with (other) take_hit(sign(x - other.x));
    }
}

// ---------- Items, springs, the checkpoint and the door ----------
with (obj_pickup) if (!grabbed && abs(x - other.x) < 18 && abs(y - other.y) < 20) collect_now();
with (obj_spring)
{
    if (other.vy > 0 && abs(x - other.x) < 18 && other.y + other.hh >= y - 26 && other.y + other.hh <= y - 4)
    {
        other.vy = -14;
        squash = 12;
        _g.play_sfx(_g.sfx.spring);
    }
}
with (obj_flag)
{
    if (!reached && abs(x - other.x) < 20 && abs((y - 24) - other.y) < 30)
    {
        reached = true;
        image_index = 1;
        _g.checkpoint_x = x;
        _g.checkpoint_y = y - 12;
        _g.play_sfx(_g.sfx.flag);
        _g.say("CHECKPOINT!", 90);
    }
}
with (obj_door)
{
    if (abs(x - other.x) < 16 && abs((y - 30) - other.y) < 34)
    {
        if (open) _g.level_complete();
        else if (hint_cooldown == 0)
        {
            hint_cooldown = 150;
            var _todo = array_length(word_hidden_letters(_g.word, _g.guessed));
            _g.say("LOCKED! " + string(_todo) + " LETTER" + (_todo == 1 ? "" : "S") + " TO GO", 120);
        }
    }
}

// ---------- The body follows like a rope ----------
update_body();

// ---------- Face ----------
if (invuln > 90) image_index = 3;
else if (tongue_t > 0) image_index = 2;
else if (blink > 0) image_index = 1;
else image_index = 0;
