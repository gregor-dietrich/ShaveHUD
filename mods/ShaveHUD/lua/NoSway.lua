if not ShaveHUD:getSetting({"Misc", "NO_SWAY"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/tweak_data/playertweakdata" then
	if not _PlayerTweakData_init then _PlayerTweakData_init = PlayerTweakData.init end
	function PlayerTweakData:init()
	_PlayerTweakData_init(self)
		for k, v in pairs(self.stances) do
			v.steelsight.shakers.breathing.amplitude = 0
		end
	end
end