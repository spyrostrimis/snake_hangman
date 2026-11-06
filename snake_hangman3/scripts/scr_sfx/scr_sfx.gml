/// Sound effects made in code: each one is a buffer of 16-bit samples, synthesised at start-up
/// and turned into a sound with audio_create_buffer_sound. No audio files needed.

#macro SFX_RATE 44100

/// Builds one sound. _notes: frequencies in Hz played one after another (0 = rest);
/// _wave: "square", "sine", "saw" or "noise"; _seconds: total length; _volume: 0..1.
function sfx_make(_notes, _wave, _seconds, _volume)
{
    var _n = floor(SFX_RATE * _seconds);
    var _buffer = buffer_create(_n * 2, buffer_fixed, 2);
    var _per_note = _n / array_length(_notes);
    var _phase = 0;
    for (var _i = 0; _i < _n; _i++)
    {
        var _note = min(array_length(_notes) - 1, floor(_i / _per_note));
        var _f = _notes[_note];
        _phase += _f / SFX_RATE;
        var _p = _phase - floor(_phase);
        var _v = 0;
        switch (_wave)
        {
            case "square": _v = (_p < 0.5) ? 1 : -1; break;
            case "sine":   _v = sin(_p * 2 * pi); break;
            case "saw":    _v = 2 * _p - 1; break;
            case "noise":  _v = random_range(-1, 1); break;
        }
        if (_f <= 0 && _wave != "noise") _v = 0;
        // Short attack, then a fade within each note so notes don't click.
        var _in_note = (_i - _note * _per_note) / _per_note;
        var _env = min(1, _in_note * 40) * power(1 - _in_note, 1.5);
        buffer_write(_buffer, buffer_s16, round(_v * _env * _volume * 32767));
    }
    var _sound = audio_create_buffer_sound(_buffer, buffer_s16, SFX_RATE, 0, _n * 2, audio_mono);
    return { sound: _sound, buffer: _buffer };
}

/// Builds every effect once; returns a struct of { sound, buffer } pairs.
function sfx_init()
{
    return {
        right: sfx_make([660, 990], "square", 0.14, 0.18),
        wrong: sfx_make([180, 120], "saw", 0.26, 0.22),
        crash: sfx_make([0], "noise", 0.45, 0.28),
        clear: sfx_make([523, 659, 784, 1047, 0, 1047], "square", 0.6, 0.16),
        hint:  sfx_make([880, 1175, 1568], "sine", 0.32, 0.3),
        turn:  sfx_make([1400], "sine", 0.03, 0.05),
        spawn: sfx_make([300, 600], "sine", 0.12, 0.12)
    };
}

function sfx_play(_effect)
{
    audio_play_sound(_effect.sound, 1, false);
}

/// Frees the sounds and their buffers (Clean Up event).
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
