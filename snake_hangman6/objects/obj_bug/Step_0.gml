// Online, the joiner's creatures copy the host's instead of thinking.
if (net_mirror()) { mirror_step(); exit; }
event_inherited();
var _s = obj_game.state;
if (_s != "play" && _s != "title" && _s != "credits") exit;

vx = facing * walk_speed;
vy = min(vy + 0.4, 8);
entity_move();
if (hit_wall != 0) facing = -facing;
// Turn round rather than walk off the edge.
if (on_ground)
{
    var _ahead = tile_at(x + facing * (hw + 2), y + hh + 6);
    if (!is_blocking(_ahead) && _ahead != T_ONEWAY) facing = -facing;
}
