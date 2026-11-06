/// A shot. team, weapon, dmg, tx, ty, target and owner are set by fire_weapon.
sx = x;
sy = y;
px = x;
py = y;
dist = max(1, point_distance(x, y, tx, ty));
dir = point_direction(x, y, tx, ty);
t = 0;
switch (weapon)
{
    case "bullet":    spd = 9;   splash = 0;  break;
    case "shell":     spd = 6;   splash = 8;  break;
    case "rocket":    spd = 2.6; splash = 10; break;
    case "artillery": spd = 3.6; splash = 26; break;
}
life = (weapon == "rocket") ? 150 : ceil(dist / spd) + 1;
