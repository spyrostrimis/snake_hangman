/// Online play by room code: helpers for obj_net.
///
/// How two games find each other, with no server of our own and no port forwarding:
///  1. Each game opens a UDP socket and asks public STUN servers what address the internet
///     sees for it (its public IP and port).
///  2. The host makes a 5-character room code. Both games use a free public message relay
///     (ntfy.sh) for a few seconds to swap their addresses, in a topic named after a hash of
///     the code. The messages are scrambled with a key made from the code, so the topic
///     alone shows nothing useful.
///  3. Both games send UDP packets straight to each other's addresses ("hole punching")
///     until one gets through. From then on they talk directly.
/// Every packet carries a tag made with the code's key, so only someone with the code can
/// join or interfere. This is not strong encryption: it keeps strangers out, nothing more.
/// Known limit: if both players are behind a "symmetric" NAT or CGNAT, punching fails;
/// joining by IP (over Tailscale or a forwarded port) is the way round it.

#macro NET_PORT 52800               // the host listens here (joiners try it too, then the next ports)
#macro NET_SIGNAL_URL "https://ntfy.sh/"
#macro NET_CODE_CHARS "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"   // no 0/O or 1/I to mix up
#macro NET_CODE_LEN 5
#macro NET_PUNCH_TIMEOUT 30000      // ms a joiner keeps trying before giving up
#macro NET_DROP_TIMEOUT 8000        // ms without a packet before the link counts as lost

enum NET_PK
{
    punch = 1,      // "can you hear me?" while connecting
    punch_ack = 2,  // "yes"
    ping = 3,
    pong = 4,
    bye = 5,        // leaving
    wave = 6,       // the test screen's hello
    game = 10,      // game data (step 3)
}

/// A new random room code.
function net_new_code()
{
    var _s = "";
    repeat (NET_CODE_LEN) _s += string_char_at(NET_CODE_CHARS, irandom(string_length(NET_CODE_CHARS) - 1) + 1);
    return _s;
}

/// Typed text cleaned into a room code: upper case, only the code's characters, at most 5.
function net_clean_code(_text)
{
    _text = string_upper(_text);
    var _s = "";
    for (var _i = 1; _i <= string_length(_text) && string_length(_s) < NET_CODE_LEN; _i++)
    {
        var _c = string_char_at(_text, _i);
        if (_c == "0") _c = "O";        // be kind to look-alikes the code never uses
        if (_c == "1") _c = "I";
        if (string_pos(_c, NET_CODE_CHARS) > 0) _s += _c;
    }
    return _s;
}

/// The relay topic and the key for a room code. Neither shows the code itself.
function net_topic(_code) { return "snkhm-" + string_copy(sha1_string_utf8("snake-hangman-room:" + _code), 1, 24); }
function net_key(_code) { return sha1_string_utf8("snake-hangman-key:" + _code); }

/// Value of hex digit pair at position _i (1-based) of hex string _hex.
function net_hex_byte(_hex, _i)
{
    var _d = "0123456789abcdef";
    return (string_pos(string_char_at(_hex, _i), _d) - 1) * 16 + (string_pos(string_char_at(_hex, _i + 1), _d) - 1);
}

/// XORs _n bytes of buffer _buf with a keystream made from _key and _iv.
function net_xor(_buf, _n, _key, _iv)
{
    var _block = "";
    for (var _i = 0; _i < _n; _i++)
    {
        if (_i mod 20 == 0) _block = sha1_string_utf8(_key + ":" + _iv + ":" + string(_i div 20));
        var _k = net_hex_byte(_block, (_i mod 20) * 2 + 1);
        buffer_poke(_buf, _i, buffer_u8, buffer_peek(_buf, _i, buffer_u8) ^ _k);
    }
}

/// Seals a relay message: a tag (so it can be checked), then the text, scrambled, in base64.
function net_seal(_key, _text)
{
    var _iv = string_copy(sha1_string_utf8(string(get_timer()) + ":" + string(irandom(999999999))), 1, 8);
    var _plain = string_copy(sha1_string_utf8(_key + "|" + _text), 1, 12) + _text;
    var _n = string_byte_length(_plain);
    var _buf = buffer_create(_n, buffer_fixed, 1);
    buffer_write(_buf, buffer_text, _plain);
    net_xor(_buf, _n, _key, _iv);
    var _out = "SH1:" + _iv + ":" + buffer_base64_encode(_buf, 0, _n);
    buffer_delete(_buf);
    return _out;
}

/// Opens a sealed relay message; returns its text, or undefined if it isn't one of ours
/// for this key.
function net_open(_key, _msg)
{
    if (string_copy(_msg, 1, 4) != "SH1:") return undefined;
    var _iv = string_copy(_msg, 5, 8);
    var _src = buffer_base64_decode(string_delete(_msg, 1, 13));
    if (_src < 0) return undefined;
    var _n = buffer_get_size(_src);
    var _buf = buffer_create(_n + 1, buffer_fixed, 1);
    buffer_copy(_src, 0, _n, _buf, 0);
    buffer_delete(_src);
    net_xor(_buf, _n, _key, _iv);
    buffer_poke(_buf, _n, buffer_u8, 0);
    buffer_seek(_buf, buffer_seek_start, 0);
    var _plain = buffer_read(_buf, buffer_string);
    buffer_delete(_buf);
    var _text = string_delete(_plain, 1, 12);
    if (string_copy(_plain, 1, 12) != string_copy(sha1_string_utf8(_key + "|" + _text), 1, 12)) return undefined;
    return _text;
}

/// True for addresses on a home network (or this PC).
function net_is_private(_ip)
{
    if (string_copy(_ip, 1, 4) == "127." || string_copy(_ip, 1, 3) == "10." || string_copy(_ip, 1, 8) == "192.168.") return true;
    if (string_copy(_ip, 1, 4) == "172.")
    {
        var _second = real(string_digits(string_copy(_ip, 5, 3)));
        return _second >= 16 && _second <= 31;
    }
    return false;
}

// ---------- Online game (step 3) ----------

/// True on the joiner's PC during an online game: its creatures, bosses and projectiles
/// copy the host's instead of moving by themselves.
function net_mirror()
{
    var _g = obj_game;
    return _g.net_mode == "client" && _g.state != "online" && _g.state != "title" && _g.state != "credits";
}

/// Writes snake _inst (or "no snake") into buffer _b: everything needed to draw it.
function net_write_snake(_b, _inst)
{
    if (!instance_exists(_inst)) { buffer_write(_b, buffer_u8, 0); return; }
    buffer_write(_b, buffer_u8, 1);
    with (_inst)
    {
        buffer_write(_b, buffer_f32, x);
        buffer_write(_b, buffer_f32, y);
        buffer_write(_b, buffer_f32, vx);
        buffer_write(_b, buffer_f32, vy);
        buffer_write(_b, buffer_s8, facing);
        buffer_write(_b, buffer_u8, (ball ? 1 : 0) | (copter ? 2 : 0) | (on_ground ? 4 : 0) | (hidden ? 8 : 0));
        buffer_write(_b, buffer_s16, round(ball_angle) mod 360);
        buffer_write(_b, buffer_u8, clamp(boost_t, 0, 255));
        buffer_write(_b, buffer_u8, clamp(round(tongue_len), 0, 255));
        buffer_write(_b, buffer_u8, floor(image_index));
        buffer_write(_b, buffer_u8, clamp(invuln, 0, 255));
        buffer_write(_b, buffer_u8, body_len);
        buffer_write(_b, buffer_u8, clamp(gulp_t, 0, 255));
    }
}

/// Reads what net_write_snake wrote: a struct, or undefined for "no snake".
function net_read_snake(_b)
{
    if (buffer_read(_b, buffer_u8) == 0) return undefined;
    var _s = {};
    _s.x = buffer_read(_b, buffer_f32);
    _s.y = buffer_read(_b, buffer_f32);
    _s.vx = buffer_read(_b, buffer_f32);
    _s.vy = buffer_read(_b, buffer_f32);
    _s.facing = buffer_read(_b, buffer_s8);
    _s.flags = buffer_read(_b, buffer_u8);
    _s.ang = buffer_read(_b, buffer_s16);
    _s.boost = buffer_read(_b, buffer_u8);
    _s.tongue = buffer_read(_b, buffer_u8);
    _s.img = buffer_read(_b, buffer_u8);
    _s.invuln = buffer_read(_b, buffer_u8);
    _s.body = buffer_read(_b, buffer_u8);
    _s.gulp = buffer_read(_b, buffer_u8);
    return _s;
}

/// Puts a snake read by net_read_snake onto remote snake _inst.
function net_apply_snake(_inst, _s)
{
    with (_inst)
    {
        net_tx = _s.x;
        net_ty = _s.y;
        vx = _s.vx;
        vy = _s.vy;
        facing = (_s.facing == 0) ? 1 : _s.facing;
        ball = (_s.flags & 1) != 0;
        copter = (_s.flags & 2) != 0;
        on_ground = (_s.flags & 4) != 0;
        hidden = (_s.flags & 8) != 0;
        ball_angle = _s.ang;
        boost_t = _s.boost;
        tongue_len = _s.tongue;
        image_index = _s.img;
        invuln = _s.invuln;
        body_len = clamp(_s.body, 1, 14);
        gulp_t = _s.gulp;
    }
}
