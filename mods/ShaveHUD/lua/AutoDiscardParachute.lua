if not ShaveHUD:getSetting({"EQUIPMENT", "AUTO_DISCARD_PARACHUTE"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/states/ingameparachuting" then
	local at_exit_actual = IngameParachuting.at_exit
	function IngameParachuting:at_exit(...)
		at_exit_actual(self, ...)

		local playermanager = managers.player
		if playermanager:get_my_carry_data() ~= nil then
			playermanager:drop_carry()
		end
	end
end