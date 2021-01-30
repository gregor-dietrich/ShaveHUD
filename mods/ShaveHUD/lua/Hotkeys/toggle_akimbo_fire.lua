if ShaveHUD.settings.ShaveHUD_aft_value then return end

if managers.player and managers.player:get_current_state() then
	local current_state = managers.player:get_current_state()
	local equipped_wpn = current_state:get_equipped_weapon()
    
    if equipped_wpn.toggle_akimbo_fire then
        equipped_wpn:toggle_akimbo_fire()
    end
end
