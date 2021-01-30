if not ShaveHUD:getSetting({"Misc", "NO_BAG_TILT"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/units/beings/player/states/playercarry" then
    PlayerCarry.target_tilt = 0 --original: -5
end