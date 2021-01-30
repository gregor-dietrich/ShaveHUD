if not ShaveHUD:getSetting({"Misc", "DISABLE_TELEMETRY"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/utils/accelbyte/telemetry" then
  local base_url = "http://localhost/"

    local function get_geolocation()
        return
    end

    local function get_total_playtime()
        return
    end

    local function update_total_playtime(new_playtime)
        return
    end

    local function send_telemetry(telemetry_body)
        return
    end

    local function send_telemetry(telemetry_body)
        return
    end

    function Telemetry:init()
        return
    end
    function Telemetry:update(t, dt)
        return
    end
    function Telemetry:send_on_player_change_loadout(stats)
        return
    end
    function Telemetry:send_on_player_economy_event(event_origin, currency, amount, transaction_type)
        return
    end
    function Telemetry:on_start_heist(...)
        return
    end
    function Telemetry:send_on_player_tutorial()
        return
    end
    function Telemetry:on_end_heist()
        return
    end
    function Telemetry:last_quickplay_room_id()
        return
    end
    function Telemetry:send_on_player_logged_out()
        return
    end
    function Telemetry:send_batch_immediately()
        return
    end
    function Telemetry:send_telemetry_immediately(event_name, payload, event_namespace, callback)
        return
    end
    function Telemetry:send_on_player_lobby_setting()
        return
    end
    function Telemetry:send_on_player_heartbeat()
        return
    end
    function Telemetry:send_on_player_heist_end()
        return
    end
    function Telemetry:send_on_player_heist_start()
        return
    end
    function Telemetry:enable(is_enable)
        return false
    end
    function Telemetry:set_mission_payout(payout)
        return
    end
    function Telemetry:on_login_screen_passed()
        return
    end
    function Telemetry:send(event_name, payload, event_namespace)
        return
    end
    function Telemetry:on_login()
        return false
    end
    function Telemetry:send_on_heist_start()
        return
    end
    function Telemetry:send_on_heist_end(end_reason)
        return
    end
end