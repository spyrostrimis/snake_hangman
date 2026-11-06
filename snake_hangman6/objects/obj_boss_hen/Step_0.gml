event_inherited();
if (obj_game.state != "play" || !active) exit;

var _angry = hp <= hp_max / 2;
var _fly = false;
timer--;
switch (state)
{
    case "hop":
        // Big flapping hops towards the snake.
        image_index = on_ground ? 0 : 1;
        if (on_ground)
        {
            vx = 0;
            if (timer <= 0)
            {
                face_player();
                vy = -8.5;
                vx = facing * (_angry ? 3.4 : 2.6);
                hops--;
                timer = 18;
                obj_game.play_sfx(obj_game.sfx.flap);
                if (hops < 0)
                {
                    vy = 0;
                    vx = 0;
                    if (irandom(1) == 0) { state = "rise"; fly_y = y - 110; }
                    else { state = "windup"; timer = _angry ? 24 : 34; }
                }
            }
        }
        break;

    case "windup":
        vx = 0;
        face_player();
        image_index = 2;
        x += irandom_range(-1, 1);
        if (timer <= 0) { state = "peck"; timer = 55; obj_game.play_sfx(obj_game.sfx.charge); }
        break;

    case "peck":
        vx = facing * (_angry ? 6.5 : 5.5);
        image_index = 2;
        if (hit_wall != 0 || x <= arena_x1 || x >= arena_x2 || timer <= 0)
        {
            state = "hop";
            hops = _angry ? 3 : 2;
            timer = 40;
            vx = 0;
        }
        break;

    case "rise":
        // Flap up high...
        _fly = true;
        image_index = (obj_game.frame div 6) mod 2;
        vx = 0;
        vy = (fly_y - y) * 0.08;
        if (abs(y - fly_y) < 4) { state = "rain"; timer = 30; drops = _angry ? 7 : 5; }
        break;

    case "rain":
        // ...then sweep across, dropping feathers on the snake.
        _fly = true;
        image_index = (obj_game.frame div 6) mod 2;
        face_player();
        vx = facing * 1.6;
        vy = (fly_y - y) * 0.1 + sin(obj_game.frame * 0.1) * 0.6;
        if (timer <= 0)
        {
            var _f = shoot(spr_feather, x, y + 10, random_range(-0.6, 0.6), 2.2, 0);
            _f.sway = true;
            obj_game.play_sfx(obj_game.sfx.throw_);
            drops--;
            timer = 22;
            if (drops <= 0) { state = "hop"; hops = 2; timer = 50; }
        }
        break;
}

if (!_fly) vy = min(vy + gravity_pull, 9);
entity_move();
if (on_ground && state == "hop" && timer < 0) timer = 18;
