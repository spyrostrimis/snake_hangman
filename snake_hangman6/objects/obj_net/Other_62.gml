/// Async HTTP: answers from the relay (ntfy.sh).
var _id = string(async_load[? "id"]);
if (!variable_struct_exists(http_kind, _id)) exit;
if (async_load[? "status"] == 1) exit;      // still downloading
var _kind = http_kind[$ _id];
variable_struct_remove(http_kind, _id);

var _http = async_load[? "http_status"];
if (async_load[? "status"] < 0 || _http < 200 || _http >= 300)
{
    relay_errors++;
    // Too many requests: slow down.
    if (_http == 429) poll_every = min(poll_every * 2, 30000);
    if (relay_errors >= 3 && state == "signal") detail = "Trouble reaching the relay (ntfy.sh): " + ((_http > 0) ? "HTTP " + string(_http) : "no internet?");
    exit;
}
relay_errors = 0;
if (_kind != "poll") exit;

// One JSON object per line; messages carry our sealed text.
var _lines = string_split(async_load[? "result"], "\n", true);
for (var _i = 0; _i < array_length(_lines); _i++)
{
    var _ev = undefined;
    try { _ev = json_parse(_lines[_i]); } catch (_e) { continue; }
    if (!is_struct(_ev) || !variable_struct_exists(_ev, "event") || _ev.event != "message") continue;
    poll_since = _ev.id;        // next time, only what came after this one
    var _text = net_open(key, _ev.message);
    if (is_undefined(_text)) continue;
    var _m = undefined;
    try { _m = json_parse(_text); } catch (_e) { continue; }
    relay_message(_m);
}
