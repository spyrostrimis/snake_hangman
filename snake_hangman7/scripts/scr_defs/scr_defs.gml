/// Embersand: constants, unit and structure stats, sides and missions.

#macro CELL 32
#macro HALF 16
#macro GUI_W 1280
#macro GUI_H 720
#macro TOP_H 28
#macro SIDE_X 1024
#macro VIEW_W 512
#macro VIEW_H 346
#macro ZOOM 2
#macro T_SAND 0
#macro T_ROCK 1
#macro T_CRAG 2
#macro LUMEN_MAX 300
#macro PLAYER 0
#macro DEPTH_BASE 5000

function defs_init()
{
    // Units. Ranges and sight are in cells; speeds in pixels per frame; reload in frames.
    global.udef = {
        trooper:   { name: "Rifle Squad",    kind: "inf", hp: 45,  spd: 0.5,  turn: 360, range: 3,   minr: 0,   dmg: 5,  reload: 32,  weapon: "bullet",    sight: 4, cost: 90,  tech: 1, at: "barracks", needs: [],                    spr: spr_trooper,   tur: -1,                  radius: 4,  squad: 3, cameo: 8,  desc: "Three riflemen. Cheap, quick to train, good against infantry." },
        rocketeer: { name: "Rocket Trooper", kind: "inf", hp: 40,  spd: 0.45, turn: 360, range: 4.5, minr: 0,   dmg: 30, reload: 100, weapon: "rocket",    sight: 5, cost: 120, tech: 2, at: "barracks", needs: ["radar"],             spr: spr_rocketeer, tur: -1,                  radius: 4,  squad: 1, cameo: 9,  desc: "Shoulder rockets. Slow to reload, deadly to vehicles." },
        buggy:     { name: "Dune Raider",    kind: "veh", hp: 130, spd: 1.9,  turn: 7,   range: 3.5, minr: 0,   dmg: 6,  reload: 14,  weapon: "bullet",    sight: 5, cost: 260, tech: 1, at: "factory",  needs: [],                    spr: spr_buggy,     tur: -1,                  radius: 8,  squad: 1, cameo: 10, desc: "A fast four-wheel scout with a machine gun." },
        tank:      { name: "Warden Tank",    kind: "veh", hp: 320, spd: 1.0,  turn: 3,   range: 4.2, minr: 0,   dmg: 28, reload: 64,  weapon: "shell",     sight: 5, cost: 520, tech: 2, at: "factory",  needs: [],                    spr: spr_tank,      tur: spr_tank_turret,     radius: 10, squad: 1, cameo: 11, desc: "The main battle tank. Armoured, with a turning turret." },
        launcher:  { name: "Lancer",         kind: "veh", hp: 160, spd: 0.9,  turn: 3,   range: 8,   minr: 2.5, dmg: 40, reload: 150, weapon: "artillery", sight: 5, cost: 700, tech: 3, at: "factory",  needs: ["radar"],             spr: spr_launcher,  tur: spr_launcher_turret, radius: 10, squad: 1, cameo: 12, desc: "Long-range rocket carrier. Fragile up close." },
        heavy:     { name: "Bastion",        kind: "veh", hp: 600, spd: 0.65, turn: 2,   range: 4.6, minr: 0,   dmg: 34, reload: 80,  weapon: "shell",     sight: 5, cost: 950, tech: 3, at: "factory",  needs: ["radar"],             spr: spr_heavy,     tur: spr_heavy_turret,    radius: 12, squad: 1, cameo: 13, shots: 2, desc: "Heavy twin-cannon tank. Slow and very hard to stop." },
        harvester: { name: "Harvester",      kind: "veh", hp: 500, spd: 0.8,  turn: 3,   range: 0,   minr: 0,   dmg: 0,  reload: 0,   weapon: "",          sight: 3, cost: 650, tech: 1, at: "factory",  needs: ["refinery"],          spr: spr_harvester, tur: -1,                  radius: 13, squad: 1, cameo: 14, desc: "Gathers lumen crystals and brings them to a Refinery." }
    };
    // Structures. Sizes in cells. Power: positive makes, negative uses.
    global.bdef = {
        yard:     { name: "Command Yard",  w: 2, h: 2, hp: 1500, cost: 1000, power: 0,   tech: 9, needs: [],           spr: spr_b_yard,     cameo: 15, sight: 5, desc: "Builds every structure. Protect it." },
        power:    { name: "Power Core",    w: 2, h: 2, hp: 650,  cost: 300,  power: 100, tech: 1, needs: [],           spr: spr_b_power,    cameo: 0,  sight: 3, desc: "Makes 100 power. Low power slows building and turrets." },
        refinery: { name: "Refinery",      w: 3, h: 2, hp: 1000, cost: 900,  power: -30, tech: 1, needs: ["power"],    spr: spr_b_refinery, cameo: 1,  sight: 4, desc: "Turns lumen into credits. Comes with a Harvester." },
        barracks: { name: "Barracks",      w: 2, h: 2, hp: 650,  cost: 300,  power: -15, tech: 1, needs: ["power"],    spr: spr_b_barracks, cameo: 2,  sight: 3, desc: "Trains infantry." },
        factory:  { name: "Motor Works",   w: 3, h: 2, hp: 1100, cost: 800,  power: -30, tech: 1, needs: ["refinery"], spr: spr_b_factory,  cameo: 3,  sight: 3, desc: "Builds vehicles." },
        radar:    { name: "Radar Post",    w: 2, h: 2, hp: 700,  cost: 600,  power: -35, tech: 2, needs: ["factory"],  spr: spr_b_radar,    cameo: 4,  sight: 7, desc: "Turns on the map. Unlocks advanced units." },
        gun:      { name: "Gun Turret",    w: 1, h: 1, hp: 450,  cost: 220,  power: -10, tech: 1, needs: ["barracks"], spr: spr_b_gun,      cameo: 5,  sight: 5, weapon: "shell",  range: 5, dmg: 16, reload: 40, tur: spr_gun_head,    desc: "Short-range cannon turret." },
        rocket:   { name: "Rocket Tower",  w: 1, h: 1, hp: 550,  cost: 450,  power: -25, tech: 2, needs: ["radar"],    spr: spr_b_rocket,   cameo: 6,  sight: 7, weapon: "rocket", range: 7, dmg: 30, reload: 85, tur: spr_rocket_head, desc: "Long-range rocket tower." },
        wall:     { name: "Wall",          w: 1, h: 1, hp: 350,  cost: 25,   power: 0,   tech: 1, needs: ["power"],    spr: spr_b_wall,     cameo: 7,  sight: 1, desc: "Blocks the way. Cheap." }
    };
    global.build_list = ["power", "refinery", "barracks", "factory", "radar", "gun", "rocket", "wall"];
    global.inf_list = ["trooper", "rocketeer"];
    global.veh_list = ["buggy", "tank", "launcher", "heavy", "harvester"];

    global.sides = [
        { name: "Azure Concord",    short: "Concord",     col: make_colour_rgb(70, 132, 236) },
        { name: "Jade Directorate", short: "Directorate", col: make_colour_rgb(64, 186, 96) },
        { name: "Scarlet Dominion", short: "Dominion",    col: make_colour_rgb(214, 60, 48) }
    ];
    global.difficulties = ["Easy", "Normal", "Hard"];
}

/// How much of a weapon's damage gets through each kind of armour.
function dmg_mod(_weapon, _armor)
{
    switch (_weapon)
    {
        case "bullet":    return (_armor == "inf") ? 1.0 : ((_armor == "veh") ? 0.3 : 0.2);
        case "shell":     return (_armor == "inf") ? 0.55 : ((_armor == "veh") ? 1.0 : 0.8);
        case "rocket":    return (_armor == "inf") ? 0.4 : ((_armor == "veh") ? 1.2 : 0.9);
        case "artillery": return (_armor == "inf") ? 1.0 : ((_armor == "veh") ? 0.8 : 1.2);
    }
    return 1;
}

function missions_init()
{
    global.missions = [
        {
            title: "Landfall", w: 48, h: 48, seed: 4121, tech: 1, credits: 1500,
            goal: "credits", goal_amount: 4000, fields: 6, outcrops: 7,
            player: { cx: 9, cy: 38 },
            start_units: ["trooper", "trooper", "buggy"],
            enemies: [
                { cx: 38, cy: 9, side: 2,
                  base: ["power", "barracks", "refinery", "gun"],
                  order: ["power", "barracks", "refinery", "gun", "power", "factory", "gun"],
                  units: ["trooper", "trooper", "trooper", "buggy"],
                  mix: { trooper: 4, buggy: 2 },
                  first_wave: 210, wave_every: 140, wave: 3, wave_grow: 1, wave_max: 6, credits: 600 }
            ],
            brief: "Welcome to Embersand, Commander. Up here it is all sand and black rock, but the lumen crystals under the dunes power half the colonies in this sector.\n\nBuild a Power Core, then a Refinery, and let the Harvester work. Collect 4,000 credits to secure our claim.\n\nThe Scarlet Dominion has a camp to the north-east. Expect raiders on buggies.",
            objective: "Collect 4,000 credits.",
            unlocks: "Rifle Squad, Dune Raider, Harvester, Gun Turret, Wall"
        },
        {
            title: "Hold the Ridge", w: 64, h: 64, seed: 9917, tech: 2, credits: 2000,
            goal: "destroy", goal_amount: 0, fields: 9, outcrops: 11,
            player: { cx: 10, cy: 53 },
            start_units: ["trooper", "buggy", "buggy", "tank"],
            enemies: [
                { cx: 53, cy: 11, side: 2,
                  base: ["power", "refinery", "barracks", "power", "factory", "gun", "gun", "radar"],
                  order: ["power", "refinery", "barracks", "power", "factory", "gun", "gun", "radar", "power", "rocket", "gun", "refinery"],
                  units: ["tank", "tank", "trooper", "trooper", "buggy", "rocketeer"],
                  mix: { trooper: 3, rocketeer: 2, buggy: 2, tank: 4 },
                  first_wave: 240, wave_every: 150, wave: 4, wave_grow: 2, wave_max: 12, credits: 1500 }
            ],
            brief: "The Dominion wants the ridge fields for itself. Their base sits across the valley, behind a line of turrets.\n\nOur engineers have finished the Radar Post, the Rocket Tower and the Warden tank. Build up, hold your fields, then go and take theirs.\n\nDestroy every Dominion structure.",
            objective: "Destroy all enemy structures.",
            unlocks: "Radar Post, Rocket Tower, Rocket Trooper, Warden Tank"
        },
        {
            title: "Ashfall", w: 72, h: 72, seed: 31337, tech: 3, credits: 2500,
            goal: "destroy", goal_amount: 0, fields: 12, outcrops: 14,
            player: { cx: 10, cy: 61 },
            start_units: ["tank", "tank", "trooper", "trooper", "buggy"],
            enemies: [
                { cx: 61, cy: 10, side: 2,
                  base: ["power", "refinery", "barracks", "power", "factory", "gun", "rocket", "radar", "gun"],
                  order: ["power", "refinery", "barracks", "power", "factory", "radar", "gun", "rocket", "power", "gun", "rocket", "refinery", "power"],
                  units: ["tank", "tank", "launcher", "trooper", "rocketeer", "heavy"],
                  mix: { trooper: 2, rocketeer: 2, buggy: 1, tank: 4, launcher: 2, heavy: 2 },
                  first_wave: 270, wave_every: 150, wave: 5, wave_grow: 2, wave_max: 14, credits: 2000 },
                { cx: 61, cy: 58, side: -1,
                  base: ["power", "refinery", "barracks", "factory", "gun", "power", "gun"],
                  order: ["power", "refinery", "barracks", "factory", "power", "gun", "gun", "radar", "rocket", "power"],
                  units: ["tank", "buggy", "buggy", "trooper", "trooper"],
                  mix: { trooper: 3, rocketeer: 1, buggy: 3, tank: 3, launcher: 1 },
                  first_wave: 330, wave_every: 170, wave: 4, wave_grow: 2, wave_max: 12, credits: 1500 }
            ],
            brief: "Ashfall. Two camps are closing in on us from the east: the Dominion, and the {other}, who have chosen this week to stop being our friends.\n\nThe labs have released the Lancer rocket carrier and the Bastion heavy tank. Use the Lancers from behind your tanks.\n\nBreak both bases, Commander. Then Embersand is ours.",
            objective: "Destroy all structures of both enemy camps.",
            unlocks: "Lancer, Bastion"
        }
    ];
}
