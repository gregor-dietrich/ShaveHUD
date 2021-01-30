if not ShaveHUD:getSetting({"Fixes", "COUNTER_TASER"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/units/beings/player/states/playertased" then
	Hooks:PostHook( PlayerTased, "on_tase_ended", "crash_prevent_1", function(self)
		self._tase_ended = true
	end)

	Hooks:PostHook( PlayerTased, "exit", "crash_prevent_2", function(self, state_data, enter_data)
		self._tase_ended = nil
	end)

	function PlayerTased:call_teammate(line, t, no_gesture, skip_alert)
		local voice_type, plural, prime_target = self:_get_unit_intimidation_action(true, false, false, true, false)
		local interact_type, queue_name
		if voice_type == "stop_cop" or voice_type == "mark_cop" then
			local prime_target_tweak = tweak_data.character[prime_target.unit:base()._tweak_table]
			local shout_sound = prime_target_tweak.priority_shout
			shout_sound = managers.groupai:state():whisper_mode() and prime_target_tweak.silent_priority_shout or shout_sound
			if shout_sound then
				interact_type = "cmd_point"
				queue_name = "s07x_sin"
				if managers.player:has_category_upgrade("player", "special_enemy_highlight") then
					prime_target.unit:contour():add(managers.player:get_contour_for_marked_enemy(), true, managers.player:upgrade_value("player", "mark_enemy_time_multiplier", 1))
				end
				if not self._tase_ended and managers.player:has_category_upgrade("player", "escape_taser") and prime_target.unit:key() == self._unit:character_damage():tase_data().attacker_unit:key() then
					self:_start_action_counter_tase(t, prime_target)
				end
			end
		end
		if interact_type then
			if not no_gesture then
			else
			end
			--self:_do_action_intimidate(t, interact_type or nil, queue_name, skip_alert)
		end
	end
end