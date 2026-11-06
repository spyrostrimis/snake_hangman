/// Chiptune sound made in code: square, triangle and noise voices are synthesised into 16-bit
/// buffers at start-up and turned into sounds with audio_create_buffer_sound. The tunes are
/// original, written for this game.

#macro SFX_RATE 22050

/// "C5" -> 523.25 Hz; "R" (rest) -> 0.
function note_freq(_name)
{
    if (_name == "R") return 0;
    var _names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    var _octave = real(string_char_at(_name, string_length(_name)));
    var _key = string_copy(_name, 1, string_length(_name) - 1);
    var _semi = 0;
    for (var _i = 0; _i < 12; _i++) if (_names[_i] == _key) _semi = _i;
    var _midi = (_octave + 1) * 12 + _semi;
    return 440 * power(2, (_midi - 69) / 12);
}

/// One oscillator sample for phase _p (0..1).
function osc(_wave, _p)
{
    switch (_wave)
    {
        case "square":  return (_p < 0.5) ? 1 : -1;
        case "pulse":   return (_p < 0.25) ? 1 : -1;
        case "triangle": return 1 - 4 * abs(_p - 0.5);
        case "saw":     return 2 * _p - 1;
        case "noise":   return random_range(-1, 1);
    }
    return sin(_p * 2 * pi);
}

/// A short effect: _notes are note names or Hz values played in equal steps.
function sfx_make(_notes, _wave, _seconds, _volume)
{
    var _n = floor(SFX_RATE * _seconds);
    var _buffer = buffer_create(_n * 2, buffer_fixed, 2);
    var _per = _n / array_length(_notes);
    var _phase = 0;
    for (var _i = 0; _i < _n; _i++)
    {
        var _k = min(array_length(_notes) - 1, floor(_i / _per));
        var _f = is_string(_notes[_k]) ? note_freq(_notes[_k]) : _notes[_k];
        _phase += _f / SFX_RATE;
        var _v = (_f <= 0 && _wave != "noise") ? 0 : osc(_wave, _phase - floor(_phase));
        var _t = (_i - _k * _per) / _per;
        var _env = min(1, _t * 30) * power(1 - _t, 1.2);
        buffer_write(_buffer, buffer_s16, round(_v * _env * _volume * 32767));
    }
    return { sound: audio_create_buffer_sound(_buffer, buffer_s16, SFX_RATE, 0, _n * 2, audio_mono), buffer: _buffer };
}

/// A pitch sweep from _f1 to _f2 Hz (pops, deaths, power-ups).
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

/// The round music: a pulse-wave melody over a triangle bass, one note per beat, looped.
function music_make(_melody, _bass, _beat)
{
    var _per = floor(SFX_RATE * _beat);
    var _n = _per * array_length(_melody);
    var _buffer = buffer_create(_n * 2, buffer_fixed, 2);
    var _pm = 0;
    var _pb = 0;
    for (var _i = 0; _i < _n; _i++)
    {
        var _k = _i div _per;
        var _t = (_i mod _per) / _per;
        var _fm = note_freq(_melody[_k]);
        var _fb = note_freq(_bass[_k]);
        _pm += _fm / SFX_RATE;
        _pb += _fb / SFX_RATE;
        var _vm = (_fm > 0) ? osc("pulse", _pm - floor(_pm)) * min(1, _t * 25) * (1 - 0.6 * _t) * 0.13 : 0;
        var _vb = (_fb > 0) ? osc("triangle", _pb - floor(_pb)) * min(1, _t * 25) * (1 - 0.3 * _t) * 0.22 : 0;
        buffer_write(_buffer, buffer_s16, round((_vm + _vb) * 32767));
    }
    return { sound: audio_create_buffer_sound(_buffer, buffer_s16, SFX_RATE, 0, _n * 2, audio_mono), buffer: _buffer };
}

function sfx_init()
{
    return {
        music: music_make(
            ["E5","G5","A5","G5", "E5","C5","D5","E5", "F5","A5","B5","A5", "G5","E5","D5","C5",
             "E5","G5","C6","B5", "A5","F5","G5","A5", "G5","E5","C5","D5", "C5","G4","C5","R"],
            ["C3","G3","E3","G3", "A2","E3","C3","E3", "F2","C3","A2","C3", "G2","D3","B2","D3",
             "C3","G3","E3","G3", "F2","C3","A2","C3", "G2","D3","B2","D3", "C3","G2","C3","R"],
            0.17),
        start:  sfx_make(["C5","E5","G5","C6","R","G5","C6","C6"], "square", 0.9, 0.16),
        clear:  sfx_make(["C5","E5","G5","C6","E6","G6","C7","C7"], "pulse", 0.75, 0.16),
        extra:  sfx_make(["G5","C6","E6","G6","E6","G6"], "square", 0.6, 0.16),
        over:   sfx_make(["G4","R","E4","R","C4","R","G3","G3"], "square", 1.4, 0.18),
        hurry:  sfx_make([880, 660, 880, 660, 880, 660], "square", 0.6, 0.14),
        pop:    sfx_sweep(500, 1400, "sine", 0.09, 0.35),
        right:  sfx_make(["E6","A6"], "pulse", 0.12, 0.14),
        wrong:  sfx_make([200, 150], "saw", 0.25, 0.2),
        treat:  sfx_make(["C6","E6","G6","C7"], "triangle", 0.25, 0.3),
        death:  sfx_sweep(900, 80, "square", 0.8, 0.16),
        step:   sfx_make(["C7"], "triangle", 0.02, 0.06),
        tick:   sfx_make(["A6"], "square", 0.03, 0.08)
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
