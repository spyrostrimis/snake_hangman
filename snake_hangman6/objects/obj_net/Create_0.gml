/// The online link: hosts or joins a room by code, finds the other game over the internet
/// (STUN + a public relay + UDP hole punching, see scr_net) and then carries packets
/// straight between the two PCs. obj_game creates one of these and uses host(), join(),
/// join_ip(), stop(), send_wave() and send_game(); the state and status are for its screens.

state  = "idle";    // idle | stun | signal | punch | connected | lost | failed
role   = "";        // host | join
code   = "";
key    = "";
topic  = "";
status = "";        // a line for the screen
detail = "";        // a second, smaller line

sock  = -1;
lport = -1;         // our local UDP port
nonce = irandom(2147483000) + 1;   // tells our packets and messages apart from the other game's

// What the STUN servers see: our public address.
stun_servers = [["stun.l.google.com", 19302], ["stun1.l.google.com", 19302], ["stun.cloudflare.com", 3478]];
stun_txn = [];      // transaction ids sent (one per server)
stun_ports = [];    // public ports reported
stun_started = 0;
stun_last = 0;
stun_refresh = 0;
pub_ip = "";
pub_port = -1;
nat_symmetric = false;   // different servers saw different ports: punching will probably fail

// The other game.
cands = [];         // [ip, port] addresses to try
peer_ip = "";
peer_port = -1;
peer_nonce = 0;
link = "";          // "this PC" | "home network" | "internet"
direct_ip = "";     // join by IP: the host's address

// Relay (ntfy.sh) messages.
http_kind = {};     // request id -> "poll" | "publish"
poll_last = 0;
poll_every = 2000;
poll_since = "30m";
offer_found = false;
published_at = -infinity;
answer_count = 0;
relay_errors = 0;

// Timing and stats.
punch_started = 0;
punch_last = 0;
broadcast_last = 0;
last_recv = 0;
ping_last = 0;
ping_ms = -1;
waves_in = 0;
waves_out = 0;
on_game = undefined;    // step 3: function(_buffer, _offset, _size) for game packets

out_buf = buffer_create(512, buffer_grow, 1);
tag_buf = buffer_create(1024, buffer_grow, 1);

// ---------- Socket ----------

/// Opens our UDP socket: the host on NET_PORT if it can, otherwise the next free port.
open_socket = function()
{
    for (var _p = NET_PORT; _p < NET_PORT + 40; _p++)
    {
        sock = network_create_socket_ext(network_socket_udp, _p);
        if (sock >= 0) { lport = _p; return true; }
    }
    return false;
};

// ---------- Packets ----------
// Layout: "SH", version 1, type, our nonce (u32), payload..., then an 8-character tag
// (part of a SHA-1 of the room key and everything before it).

/// Starts a packet of _type in out_buf; write the payload after it, then call send_to().
begin_packet = function(_type)
{
    buffer_seek(out_buf, buffer_seek_start, 0);
    buffer_write(out_buf, buffer_u8, ord("S"));
    buffer_write(out_buf, buffer_u8, ord("H"));
    buffer_write(out_buf, buffer_u8, 1);
    buffer_write(out_buf, buffer_u8, _type);
    buffer_write(out_buf, buffer_u32, nonce);
};

/// The tag of _size bytes of _buf from _offset.
packet_tag = function(_buf, _offset, _size)
{
    buffer_seek(tag_buf, buffer_seek_start, 0);
    buffer_write(tag_buf, buffer_text, key);
    var _klen = buffer_tell(tag_buf);
    if (buffer_get_size(tag_buf) < _klen + _size) buffer_resize(tag_buf, _klen + _size + 64);
    buffer_copy(_buf, _offset, _size, tag_buf, _klen);
    return string_copy(buffer_sha1(tag_buf, 0, _klen + _size), 1, 8);
};

/// Finishes the packet in out_buf with its tag and sends it to (_ip, _port).
send_to = function(_ip, _port)
{
    var _size = buffer_tell(out_buf);
    var _tag = packet_tag(out_buf, 0, _size);
    buffer_write(out_buf, buffer_text, _tag);
    network_send_udp_raw(sock, _ip, _port, out_buf, _size + 8);
    buffer_seek(out_buf, buffer_seek_start, _size);   // so it can be sent again unchanged
};

/// Sends the packet in out_buf to the other game (once connected).
send_peer = function()
{
    if (peer_port > 0) send_to(peer_ip, peer_port);
};

/// Sends a packet of _type with no payload to every address we know for the other game.
send_all = function(_type)
{
    begin_packet(_type);
    for (var _i = 0; _i < array_length(cands); _i++) send_to(cands[_i][0], cands[_i][1]);
};

// ---------- STUN: our public address ----------

stun_send = function()
{
    stun_txn = [];
    var _b = buffer_create(20, buffer_fixed, 1);
    for (var _s = 0; _s < array_length(stun_servers); _s++)
    {
        // Binding Request: type 0x0001, length 0, magic cookie 0x2112A442, 12-byte id.
        buffer_seek(_b, buffer_seek_start, 0);
        buffer_write(_b, buffer_u8, 0x00); buffer_write(_b, buffer_u8, 0x01);
        buffer_write(_b, buffer_u8, 0x00); buffer_write(_b, buffer_u8, 0x00);
        buffer_write(_b, buffer_u8, 0x21); buffer_write(_b, buffer_u8, 0x12);
        buffer_write(_b, buffer_u8, 0xA4); buffer_write(_b, buffer_u8, 0x42);
        var _id = "";
        for (var _i = 0; _i < 12; _i++)
        {
            var _r = irandom(255);
            buffer_write(_b, buffer_u8, _r);
            _id += string(_r) + ".";
        }
        array_push(stun_txn, _id);
        network_send_udp_raw(sock, stun_servers[_s][0], stun_servers[_s][1], _b, 20);
    }
    buffer_delete(_b);
    stun_last = current_time;
};

/// Reads a STUN answer; returns true if it was one.
stun_receive = function(_buf, _size)
{
    if (_size < 20 || buffer_peek(_buf, 0, buffer_u8) != 0x01 || buffer_peek(_buf, 1, buffer_u8) != 0x01) return false;
    if (buffer_peek(_buf, 4, buffer_u8) != 0x21 || buffer_peek(_buf, 5, buffer_u8) != 0x12) return false;
    var _id = "";
    for (var _i = 8; _i < 20; _i++) _id += string(buffer_peek(_buf, _i, buffer_u8)) + ".";
    var _known = false;
    for (var _i = 0; _i < array_length(stun_txn); _i++) if (stun_txn[_i] == _id) _known = true;
    if (!_known) return true;

    // Walk the attributes for XOR-MAPPED-ADDRESS (0x0020), or MAPPED-ADDRESS (0x0001).
    var _pos = 20;
    var _ip = "";
    var _port = -1;
    while (_pos + 4 <= _size)
    {
        var _type = buffer_peek(_buf, _pos, buffer_u8) * 256 + buffer_peek(_buf, _pos + 1, buffer_u8);
        var _len = buffer_peek(_buf, _pos + 2, buffer_u8) * 256 + buffer_peek(_buf, _pos + 3, buffer_u8);
        var _v = _pos + 4;
        if ((_type == 0x0020 || _type == 0x0001) && _len >= 8 && buffer_peek(_buf, _v + 1, buffer_u8) == 0x01)
        {
            var _x = (_type == 0x0020);
            var _p = buffer_peek(_buf, _v + 2, buffer_u8) * 256 + buffer_peek(_buf, _v + 3, buffer_u8);
            if (_x) _p = _p ^ 0x2112;
            var _cookie = [0x21, 0x12, 0xA4, 0x42];
            var _parts = [];
            for (var _i = 0; _i < 4; _i++) array_push(_parts, string(buffer_peek(_buf, _v + 4 + _i, buffer_u8) ^ (_x ? _cookie[_i] : 0)));
            _ip = _parts[0] + "." + _parts[1] + "." + _parts[2] + "." + _parts[3];
            _port = _p;
            if (_x) break;
        }
        _pos = _v + ((_len + 3) div 4) * 4;
    }
    if (_port <= 0) return true;

    if (array_length(stun_ports) > 0 && !array_contains(stun_ports, _port)) nat_symmetric = true;
    if (!array_contains(stun_ports, _port)) array_push(stun_ports, _port);
    var _changed = (_ip != pub_ip || _port != pub_port);
    pub_ip = _ip;
    pub_port = _port;
    // The host's public port moved (its router dropped the old mapping): tell the relay again.
    if (_changed && role == "host" && state != "stun" && state != "connected") published_at = -infinity;
    return true;
};

// ---------- Relay (ntfy.sh) ----------

relay_publish = function(_kind)
{
    var _msg = json_stringify({ k: _kind, n: nonce, ip: pub_ip, p: pub_port, lp: lport });
    var _h = ds_map_create();
    ds_map_add(_h, "Content-Type", "text/plain");
    var _id = http_request(NET_SIGNAL_URL + topic, "POST", _h, net_seal(key, _msg));
    ds_map_destroy(_h);
    http_kind[$ string(_id)] = "publish";
    published_at = current_time;
};

relay_poll = function()
{
    var _id = http_get(NET_SIGNAL_URL + topic + "/json?poll=1&since=" + poll_since);
    http_kind[$ string(_id)] = "poll";
    poll_last = current_time;
};

/// A message from the other game arrived through the relay.
relay_message = function(_m)
{
    if (!is_struct(_m) || !variable_struct_exists(_m, "k") || _m.n == nonce) return;
    if (state == "connected" || state == "lost" || state == "failed") return;
    if (role == "join" && _m.k == "offer")
    {
        add_peer_addresses(_m.ip, _m.p, _m.lp);
        if (!offer_found)
        {
            offer_found = true;
            relay_publish("answer");
            answer_count = 1;
            start_punching();
            status = "Room found! Connecting...";
        }
    }
    else if (role == "host" && _m.k == "answer")
    {
        add_peer_addresses(_m.ip, _m.p, _m.lp);
        if (state != "punch")
        {
            start_punching();
            status = "Your friend is here! Connecting...";
        }
    }
};

// ---------- Connecting ----------

add_cand = function(_ip, _port)
{
    if (_ip == "" || _port <= 0) return;
    for (var _i = 0; _i < array_length(cands); _i++) if (cands[_i][0] == _ip && cands[_i][1] == _port) return;
    array_push(cands, [_ip, _port]);
};

/// The addresses to try for the other game: its public address, its public IP with its
/// local port (many routers keep the port), and this PC (two copies on one computer).
add_peer_addresses = function(_ip, _port, _lport)
{
    add_cand(_ip, _port);
    add_cand(_ip, _lport);
    add_cand("127.0.0.1", _lport);
};

start_punching = function()
{
    if (state != "punch") punch_started = current_time;
    state = "punch";
};

/// Where the other game's packets come from, and what kind of link that is. (Same public
/// IP as ours means both PCs are behind the same router.)
set_peer = function(_ip, _port)
{
    peer_ip = _ip;
    peer_port = _port;
    if (_ip == "127.0.0.1") link = "this PC";
    else if (net_is_private(_ip) || _ip == pub_ip) link = "home network";
    else link = "internet";
};

connected = function(_ip, _port, _nonce)
{
    set_peer(_ip, _port);
    peer_nonce = _nonce;
    state = "connected";
    last_recv = current_time;
    ping_last = 0;
    status = "CONNECTED!";
    detail = "";
    // Tell the other side straight away, in case it is still punching.
    begin_packet(NET_PK.punch_ack);
    send_peer();
};

/// After STUN (or without it): the host shows its code and waits; a joiner looks for the room.
after_stun = function()
{
    stun_refresh = current_time;
    if (role == "host")
    {
        state = "signal";
        status = "Room ready. Tell your friend the code!";
        poll_every = 6000;      // the relay allows about one request every 5 seconds
        poll_last = current_time - 4000;
    }
    else if (direct_ip != "")
    {
        add_cand(direct_ip, NET_PORT);
        start_punching();
        status = "Connecting to " + direct_ip + "...";
    }
    else
    {
        state = "signal";
        status = "Looking for room " + code + "...";
        poll_every = 2000;
        poll_last = 0;
    }
    if (pub_ip == "") detail = "Couldn't reach the STUN servers: only this PC or your home network will work.";
    else if (nat_symmetric) detail = "Your router changes ports (symmetric NAT): connecting over the internet may fail.";
};

/// Starts everything for room code _code as host or joiner.
begin_room = function(_role, _code)
{
    stop();
    role = _role;
    code = _code;
    key = net_key(_code);
    topic = net_topic(_code);
    if (!open_socket())
    {
        state = "failed";
        status = "Couldn't open a network port.";
        return;
    }
    state = "stun";
    status = "Finding your internet address...";
    detail = "";
    stun_started = current_time;
    stun_send();
};

// ---------- What obj_game calls ----------

host = function() { begin_room("host", net_new_code()); };

join = function(_code) { direct_ip = ""; begin_room("join", net_clean_code(_code)); };

/// Joins a host straight at its IP (Tailscale, a forwarded port or the home network).
/// The room code is still needed: it is the key.
join_ip = function(_ip, _code) { begin_room("join", net_clean_code(_code)); direct_ip = _ip; };

stop = function()
{
    if (sock >= 0)
    {
        if (state == "connected") { begin_packet(NET_PK.bye); send_peer(); }
        network_destroy(sock);
    }
    sock = -1;
    lport = -1;
    state = "idle";
    role = "";
    status = "";
    detail = "";
    cands = [];
    peer_ip = "";
    peer_port = -1;
    peer_nonce = 0;
    pub_ip = "";
    pub_port = -1;
    stun_ports = [];
    stun_txn = [];
    nat_symmetric = false;
    offer_found = false;
    published_at = -infinity;
    answer_count = 0;
    relay_errors = 0;
    http_kind = {};
    ping_ms = -1;
    waves_in = 0;
    waves_out = 0;
    nonce = irandom(2147483000) + 1;
};

send_wave = function()
{
    if (state != "connected") return;
    waves_out++;
    begin_packet(NET_PK.wave);
    send_peer();
};

/// Step 3: sends _size bytes of _buf (from _offset) to the other game.
send_game = function(_buf, _offset, _size)
{
    if (state != "connected") return;
    begin_packet(NET_PK.game);
    var _at = buffer_tell(out_buf);
    if (buffer_get_size(out_buf) < _at + _size + 16) buffer_resize(out_buf, _at + _size + 64);
    buffer_copy(_buf, _offset, _size, out_buf, _at);
    buffer_seek(out_buf, buffer_seek_relative, _size);
    send_peer();
};
