if ShaveHUD:getSetting({"SkipIt", "SKIP_BLACKSCREEN"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
	function HUDManager:set_blackscreen_skip_circle(current, total)
		IngameWaitingForPlayersState._skip_data = {total = 0, current = 1}
		managers.hud._hud_blackscreen:set_skip_circle(current, total)
	end
end