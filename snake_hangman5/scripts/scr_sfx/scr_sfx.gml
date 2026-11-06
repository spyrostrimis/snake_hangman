/// Sound effects synthesised in code (as in v4). The music is streamed from Ogg files instead.

#macro SFX_RATE 22050

function osc(_wave, _p)
{
    switch (_wave)
    {
        case "square":   return (_p < 0.5) ? 1 : -1;
        case "pulse":    return (_p < 0.25) ? 1 : -1;
        case "triangle": return 1 - 4 * abs(_p - 0.5);
        case "saw":      return 2 * _p - 1;
        case "noise":    return random_range(-1, 1);
    }
    return sin(_p * 2 * pi);
}

/// A pitch sweep from _f1 to _f2 Hz.
function sfx_sweep(_f1, _f2, _wave, _seconds, _volume)
{
    var _n = floor(SFX_RATE * _seconds);
    var _buffer = buffer_create(_n * 2, buffer_fixed, 2);
    var _phase = 0;
    for (var _i = 0; _i < _n; _i++)
    {
        var _t = _i / _n;
        _phase += lerp(_f1, _f2, _t) / SFX_RATE;
        var _env = min(1, _t * 40) * (1 - _t);
        buffer_write(_buffer, buffer_s16, round(osc(_wave, _phase - floor(_phase)) * _env * _volume * 32767));
    }
    return { sound: audio_create_buffer_sound(_buffer, buffer_s16, SFX_RATE, 0, _n * 2, audio_mono), buffer: _buffer };
}

/// Notes in Hz played in equal steps.
function sfx_notes(_notes, _wave, _seconds, _volume)
{
    var _n = floor(SFX_RATE * _seconds);
    var _buffer = buffer_create(_n * 2, buffer_fixed, 2);
    var _per = _n / array_length(_notes);
    var _phase = 0;
    for (var _i = 0; _i < _n; _i++)
    {
        var _k = min(array_length(_notes) - 1, floor(_i / _per));
        _phase += _notes[_k] / SFX_RATE;
        var _t = (_i - _k * _per) / _per;
        var _env = min(1, _t * 30) * power(1 - _t, 1.2);
        buffer_write(_buffer, buffer_s16, round(osc(_wave, _phase - floor(_phase)) * _env * _volume * 32767));
    }
    return { sound: audio_create_buffer_sound(_buffer, buffer_s16, SFX_RATE, 0, _n * 2, audio_mono), buffer: _buffer };
}

function sfx_init()
{
    return {
        jump:    sfx_sweep(260, 620, "square", 0.14, 0.12),
        copter:  sfx_sweep(500, 520, "pulse", 0.08, 0.05),
        tongue:  sfx_sweep(1200, 300, "triangle", 0.12, 0.3),
        slurp:   sfx_sweep(300, 900, "sine", 0.1, 0.35),
        pop:     sfx_sweep(400, 1300, "sine", 0.1, 0.35),
        gem:     sfx_notes([1568, 2093], "square", 0.1, 0.08),
        right:   sfx_notes([784, 988, 1175, 1568], "pulse", 0.32, 0.14),
        wrong:   sfx_sweep(220, 110, "saw", 0.3, 0.2),
        hurt:    sfx_sweep(700, 150, "square", 0.25, 0.15),
        spring:  sfx_sweep(200, 900, "triangle", 0.25, 0.35),
        ball:    sfx_sweep(150, 350, "triangle", 0.12, 0.25),
        smash:   sfx_sweep(0, 0, "noise", 0.25, 0.25),
        gulp:    sfx_sweep(500, 140, "sine", 0.3, 0.45),
        boss_hit: sfx_sweep(900, 200, "square", 0.18, 0.18),
        charge:  sfx_sweep(120, 420, "saw", 0.35, 0.14),
        throw_:  sfx_sweep(700, 350, "triangle", 0.12, 0.25),
        flap:    sfx_sweep(200, 120, "noise", 0.15, 0.18),
        boss_win: sfx_notes([523, 659, 784, 1047, 784, 1047, 1319], "pulse", 0.9, 0.15),
        flag:    sfx_notes([659, 784, 1047], "square", 0.3, 0.12),
        door:    sfx_notes([392, 523, 659, 784, 1047], "pulse", 0.7, 0.15),
        die:     sfx_sweep(800, 60, "square", 0.9, 0.15),
        select:  sfx_notes([880, 1320], "square", 0.1, 0.08)
    };
}

function sfx_free(_effects)
{
    var _names = variable_struct_get_names(_effects);
    for (var _i = 0; _i < array_length(_names); _i++)
    {
        var _e = _effects[$ _names[_i]];
        audio_free_buffer_sound(_e.sound);
        buffer_delete(_e.buffer);
    }
}
