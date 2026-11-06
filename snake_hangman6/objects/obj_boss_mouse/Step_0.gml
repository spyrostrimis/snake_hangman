event_inherited();
if (obj_game.state != "play" || !active) exit;

var _angry = hp <= hp_max / 2;   // faster in the second half of the fight
timer--;
switch (state)
{
    case "walk":
        var _dist = face_player();
        vx = facing * (_angry ? 1.8 : 1.2);
        image_index = (obj_game.frame div 10) mod 2;
        if (timer <= 0)
        {
            if (_dist > 140 && irandom(1) == 0) { state = "throw"; timer = 24; throws = _angry ? 4 : 3; }
            else { state = "windup"; timer = _angry ? 28 : 40; }
        }
        break;

    case "windup":
        // Shakes on the spot, glove pulled back: a clear warning before the charge.
        vx = 0;
        image_index = 2;
        x += irandom_range(-1, 1);
        if (timer <= 0) { state = "charge"; timer = 70; obj_game.play_sfx(obj_game.sfx.charge); }
        break;

    case "charge":
        vx = facing * (_angry ? 7 : 5.8);
        image_index = 2;
        if (hit_wall != 0 || x <= arena_x1 || x >= arena_x2)
        {
            // Bonk! Dizzy for a moment: the best time to strike.
            state = "dizzy";
            timer = 70;
            vx = 0;
            obj_game.play_sfx(obj_game.sfx.smash);
            part_particles_create(obj_game.ps, x + facing * hw, y, obj_game.pt_rock, 8);
        }
        else if (timer <= 0) { state = "walk"; timer = 80; }
        break;

    case "dizzy":
        vx = 0;
        image_index = 3;
        if (timer <= 0) { state = "walk"; timer = 60; }
        break;

    case "throw":
        vx = 0;
        face_player();
        image_index = 2;
        if (timer <= 0)
        {
            var _target = instance_nearest(x, y, obj_player);
            var _d = (_target != noone) ? _target.x - x : facing * 200;
            shoot(spr_cheese, x + facing * 20, y - 30, clamp(_d / 45, -5, 5), -7, 0.32);
            obj_game.play_sfx(obj_game.sfx.throw_);
            throws--;
            timer = 22;
            if (throws <= 0) { state = "walk"; timer = 90; }
        }
        else if (timer > 12) image_index = 0;
        break;
}

vy = min(vy + gravity_pull, 9);
entity_move();
