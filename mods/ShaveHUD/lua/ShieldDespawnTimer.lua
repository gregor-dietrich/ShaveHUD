if not ShaveHUD:getSetting({"Misc", "SHIELD_DESPAWN_TIMER"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/units/enemies/cop/copinventory" then
	local this = {
		min_value = 3,
		max_value = 12
	}

	if not ShieldDespawnTimer then
		ShieldDespawnTimer = ShieldDespawnTimer or {}

		function ShieldDespawnTimer:get_time( skip_time )
			local valid = type( self.timer ) == "number" and self.timer >= this.min_value and self.timer <= this.max_value
			self.timer = valid and self.timer or this.min_value

			return ( skip_time and 0 or Application:time() ) + self.timer
		end
		
		Hooks:PostHook( CopInventory, "drop_shield", "ShieldDespawnTimer", function( u )
			if alive( u._shield_unit ) then
				local function clbk_hide()
					if alive( u._shield_unit ) then
						managers.enemy:unregister_shield( u._shield_unit )
						u._shield_unit:set_slot( 0 )
						u._shield_unit = nil
					end
				end

				managers.enemy:add_delayed_clbk( "", clbk_hide, ShieldDespawnTimer:get_time() )
			end
		end)
	end
end