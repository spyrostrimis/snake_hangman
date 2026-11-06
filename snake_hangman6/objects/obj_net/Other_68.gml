/// Async Networking: STUN answers and packets from the other game arrive here.
if (async_load[? "id"] != sock || async_load[? "type"] != network_type_data) exit;
var _buf  = async_load[? "buffer"];
var _size = async_load[? "size"];
var _ip   = async_load[? "ip"];
var _port = async_load[? "port"];

if (stun_receive(_buf, _size)) exit;

// Our packets start with "SH" 1. (A broadcast may arrive with GameMaker's own header in
// front, so look a little way in.)
var _at = -1;
for (var _i = 0; _i <= min(16, _size - 16); _i++)
{
    if (buffer_peek(_buf, _i, buffer_u8) == ord("S") && buffer_peek(_buf, _i + 1, buffer_u8) == ord("H") && buffer_peek(_buf, _i + 2, buffer_u8) == 1) { _at = _i; break; }
}
if (_at < 0 || key == "") exit;
var _len = _size - _at;

// Check the tag: only a game with the same room code makes the right one.
buffer_seek(_buf, buffer_seek_start, _size - 8);
var _tag = "";
repeat (8) _tag += chr(buffer_read(_buf, buffer_u8));
if (_tag != packet_tag(_buf, _at, _len - 8)) exit;

var _type  = buffer_peek(_buf, _at + 3, buffer_u8);
var _from  = buffer_peek(_buf, _at + 4, buffer_u32);
var _body  = _at + 8;               // payload start
var _bsize = _len - 8 - 8;          // payload size
if (_from == nonce) exit;           // our own broadcast
if (peer_nonce != 0 && _from != peer_nonce) exit;   // someone else with the code, once connected

switch (_type)
{
    case NET_PK.punch:
        if (state == "signal" || state == "punch")
        {
            connected(_ip, _port, _from);
        }
        else if (state == "connected")
        {
            begin_packet(NET_PK.punch_ack);
            send_to(_ip, _port);
        }
        break;

    case NET_PK.punch_ack:
        if (state == "signal" || state == "punch") connected(_ip, _port, _from);
        break;

    case NET_PK.ping:
        if (state == "connected")
        {
            begin_packet(NET_PK.pong);
            buffer_write(out_buf, buffer_f64, buffer_peek(_buf, _body, buffer_f64));
            send_peer();
        }
        break;

    case NET_PK.pong:
        var _rtt = current_time - buffer_peek(_buf, _body, buffer_f64);
        ping_ms = (ping_ms < 0) ? _rtt : lerp(ping_ms, _rtt, 0.2);
        break;

    case NET_PK.wave:
        waves_in++;
        break;

    case NET_PK.bye:
        if (state == "connected")
        {
            state = "lost";
            status = "Your friend left.";
            detail = "";
        }
        break;

    case NET_PK.game:
        if (!is_undefined(on_game)) on_game(_buf, _body, _bsize);
        break;
}

if (state == "connected")
{
    last_recv = current_time;
    // Their router may have moved them to a new port: follow it. (Only on packets sent after
    // connecting: late punches can still arrive by other routes.)
    if ((_type == NET_PK.ping || _type == NET_PK.pong || _type == NET_PK.game) && (_ip != peer_ip || _port != peer_port)) set_peer(_ip, _port);
}
