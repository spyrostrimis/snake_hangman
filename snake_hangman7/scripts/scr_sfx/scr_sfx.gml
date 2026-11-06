/// Sound effects synthesised in code: noise through a low-pass filter for guns and blasts, simple tones for the interface.

#macro SFX_RATE 22050

function sfx_osc(_wave, _p)
{
    switch (_wave)
    {
        case "square":   return (_p < 0.5) ? 1 : -1;
        case "pulse":    return (_p < 0.25) ? 1 : -1;
        case "triangle": return 1 - 4 * abs(_p - 0.5);
        case "saw":      return 2 * _p - 1;
    }
    return sin(_p * 2 * pi);
}

function sfx_from_buffer(_buffer, _n)
{
    return { sound: audio_create_buffer_sound(_buffer, buffer_s16, SFX_RATE, 0, _n * 2, audio_mono), buffer: _buffer };
}

/// Filtered noise with a falling cutoff, plus an optional low sine "thump" from _f1 to _f2 Hz.
function sfx_blast(_seconds, _cut1, _cut2, _noise_vol, _f1, _f2, _thump_vol, _attack)
{
    var _n = floor(SFX_RATE * _seconds);
    var _buffer = buffer_create(_n * 2, buffer_fixed, 2);
    var _y = 0, _phase = 0;
    for (var _i = 0; _i < _n; _i++)
    {
        var _t = _i / _n;
        var _a = lerp(_cut1, _cut2, sqrt(_t));
        _y += _a * (random_range(-1, 1) - _y);
        _phase += lerp(_f1, _f2, _t) / SFX_RATE;
        var _env = min(1, _t * _attack) * power(1 - _t, 2);
        var _s = (_y * _noise_vol + sin(_phase * 2 * pi) * _thump_vol) * _env;
        buffer_write(_buffer, buffer_s16, round(clamp(_s, -1, 1) * 32767));
    }
    return sfx_from_buffer(_buffer, _n);
}

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
        buffer_write(_buffer, buffer_s16, round(sfx_osc(_wave, _phase - floor(_phase)) * _env * _volume * 32767));
    }
    return sfx_from_buffer(_buffer, _n);
}

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
        buffer_write(_buffer, buffer_s16, round(sfx_osc(_wave, _phase - floor(_phase)) * _env * _volume * 32767));
    }
    return sfx_from_buffer(_buffer, _n);
}

/// A two-tone siren.
function sfx_siren(_seconds, _volume)
{
    var _n = floor(SFX_RATE * _seconds);
    var _buffer = buffer_create(_n * 2, buffer_fixed, 2);
    var _phase = 0;
    for (var _i = 0; _i < _n; _i++)
    {
        var _t = _i / _n;
        var _f = (floor(_t * 6) mod 2 == 0) ? 740 : 560;
        _phase += _f / SFX_RATE;
        var _env = min(1, _t * 30) * min(1, (1 - _t) * 8);
        buffer_write(_buffer, buffer_s16, round(sfx_osc("square", _phase - floor(_phase)) * _env * _volume * 32767));
    }
    return sfx_from_buffer(_buffer, _n);
}

function sfx_init()
{
    random_set_seed(7);
    var _s = {
        gun:       sfx_blast(0.08, 0.9, 0.3, 0.5, 300, 120, 0.15, 200),
        cannon:    sfx_blast(0.4, 0.5, 0.05, 0.6, 110, 40, 0.5, 300),
        rocket:    sfx_blast(0.45, 0.08, 0.35, 0.45, 200, 400, 0.05, 6),
        boom:      sfx_blast(1.0, 0.3, 0.015, 0.9, 70, 28, 0.55, 200),
        boom_s:    sfx_blast(0.45, 0.45, 0.04, 0.7, 120, 50, 0.35, 200),
        crunch:    sfx_blast(0.15, 0.25, 0.05, 0.5, 90, 60, 0.2, 200),
        place:     sfx_blast(0.3, 0.2, 0.02, 0.4, 140, 45, 0.6, 200),
        click:     sfx_sweep(1400, 1100, "square", 0.03, 0.1),
        select:    sfx_notes([660, 990], "pulse", 0.09, 0.1),
        ack:       sfx_sweep(500, 820, "triangle", 0.12, 0.3),
        attack:    sfx_notes([880, 660], "square", 0.12, 0.1),
        ready:     sfx_notes([523, 659, 784], "pulse", 0.3, 0.12),
        complete:  sfx_notes([392, 523, 659, 784], "pulse", 0.45, 0.12),
        error:     sfx_sweep(190, 170, "saw", 0.25, 0.18),
        alarm:     sfx_siren(0.9, 0.09),
        cash:      sfx_sweep(1900, 2300, "triangle", 0.03, 0.12),
        win:       sfx_notes([523, 659, 784, 1047, 784, 1047, 1319], "pulse", 1.0, 0.13),
        lose:      sfx_notes([523, 466, 415, 349, 262], "square", 1.2, 0.12)
    };
    randomize();
    return _s;
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
