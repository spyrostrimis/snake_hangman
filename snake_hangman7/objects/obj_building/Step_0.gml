if (global.paused || global.state != "play") exit;
if (flash > 0) flash--;

// Going up
if (anim < 1)
{
    anim = min(1, anim + 1 / 50);
    if (global.frame mod 4 == 0) part_particles_create(global.ps, x + random(w * CELL), y + h * CELL * (1 - anim), global.pt_dust, 1);
    if (anim >= 1) building_complete();
    exit;
}

var _tm = global.teams[team];
if (variable_struct_exists(def, "weapon")) turret_step();
if (btype == "radar" && !_tm.power_low) dish = (dish + 0.12) mod 16;

// Repairs cost 40% of the price for a full repair, over ten seconds
if (repairing)
{
    var _heal = maxhp / 600, _price = def.cost * 0.4 / 600;
    if (hp >= maxhp) repairing = false;
    else if (_tm.credits >= _price)
    {
        _tm.credits -= _price;
        hp = min(maxhp, hp + _heal);
        if (global.frame mod 12 == 0) part_particles_create(global.ps, x + random(w * CELL), y + random(h * CELL), global.pt_spark, 1);
    }
}

// Damage smoke and fire
smoke_t--;
if (smoke_t <= 0 && hp < maxhp * 0.5)
{
    smoke_t = (hp < maxhp * 0.25) ? 6 : 14;
    var _px = x + 6 + random(w * CELL - 12), _py = y + 6 + random(h * CELL - 12);
    part_particles_create(global.ps, _px, _py, global.pt_smoke, 1);
    if (hp < maxhp * 0.25) part_particles_create(global.ps, _px, _py, global.pt_fire, 2);
}
