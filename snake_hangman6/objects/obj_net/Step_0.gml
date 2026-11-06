/// Drives the connection: STUN, relay polling, hole punching, pings and timeouts.
var _now = current_time;

switch (state)
{
    case "stun":
        // Ask again every 400 ms; carry on once two servers answered, or after 1.5 s with
        // one answer, or after 4 s with none (then only this PC / the home network work).
        if (_now - stun_last > 400) stun_send();
        var _answers = array_length(stun_ports);
        if (pub_port > 0 && (nat_symmetric || _answers >= 2 || _now - stun_started > 1500)) after_stun();
        else if (_now - stun_started > 4000) after_stun();
        break;

    case "signal":
    case "punch":
        // The relay: the host posts its address once (again if it changes) and checks for
        // a joiner; a joiner checks for the host's address, then posts its own.
        if (direct_ip == "")
        {
            if (role == "host" && _now - published_at > 600000) relay_publish("offer");
            if (role == "join" && offer_found && state == "punch" && answer_count < 4 && _now - published_at > 8000)
            {
                relay_publish("answer");
                answer_count++;
            }
            if (_now - poll_last > poll_every) relay_poll();
        }

        // Keep the router's door open, and notice if our public port changes.
        if (_now - stun_refresh > 20000) { stun_refresh = _now; stun_send(); }

        if (state == "punch")
        {
            if (_now - punch_last >= 100)
            {
                punch_last = _now;
                send_all(NET_PK.punch);
            }
            // On a home network, shout for the host on its usual port too.
            if (role == "join" && _now - broadcast_last >= 500)
            {
                broadcast_last = _now;
                begin_packet(NET_PK.punch);
                var _size = buffer_tell(out_buf);
                buffer_write(out_buf, buffer_text, packet_tag(out_buf, 0, _size));
                network_send_broadcast(sock, NET_PORT, out_buf, _size + 8);
            }
            var _waited = _now - punch_started;
            if (_waited > 8000) detail = "Still trying... (" + string(_waited div 1000) + " s)";
            if (role == "join" && _waited > NET_PUNCH_TIMEOUT)
            {
                state = "failed";
                status = "Couldn't connect.";
                detail = "Your routers may block direct links (CGNAT / symmetric NAT). Try joining by IP.";
            }
        }
        else if (role == "join" && offer_found == false && _now - stun_started > 60000)
        {
            state = "failed";
            status = "No room " + code + " found.";
            detail = "Check the code, and that your friend is hosting.";
        }
        break;

    case "connected":
        if (_now - ping_last >= 500)
        {
            ping_last = _now;
            begin_packet(NET_PK.ping);
            buffer_write(out_buf, buffer_f64, _now);
            send_peer();
        }
        if (_now - last_recv > NET_DROP_TIMEOUT)
        {
            state = "lost";
            status = "Connection lost.";
            detail = "Nothing heard from your friend for " + string(NET_DROP_TIMEOUT div 1000) + " seconds.";
        }
        break;
}
