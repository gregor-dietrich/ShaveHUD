if string.lower(RequiredScript) == "lib/units/weapons/raycastweaponbase" then
	if ShaveHUD:getSetting({"Fixes", "BOT_BULLET_COLLISION"}, true) then
		local init_original = RaycastWeaponBase.init
		local setup_original = RaycastWeaponBase.setup
	
		function RaycastWeaponBase:init(...)
			init_original(self, ...)
			self._bullet_slotmask = self._bullet_slotmask - World:make_slot_mask(16)
		end
	
		function RaycastWeaponBase:setup(...)
			setup_original(self, ...)
			self._bullet_slotmask = self._bullet_slotmask - World:make_slot_mask(16)
		end
	end

	if ShaveHUD:getSetting({"Fixes", "BULLET_PUSH"}, true) then
		function InstantBulletBase:_get_character_push_multiplier(weapon_unit, died)
			return nil
		end
	end

	if ShaveHUD:getSetting({"Fixes", "AUTO_FIRE_SOUND"}, true) then
		--Original mod by 90e, uploaded by DarKobalt.
		--Reverb fixed by Doctor Mister Cool, aka Didn'tMeltCables, aka DinoMegaCool
		--New version uploaded and maintained by Offyerrocker.

		--[[ this is here for debugging reasons, ignore it
		local function dbug(...)
			OffyLib:c_log(...)
		end
		--]]

		_G.AutoFireSoundFixBlacklist = {
			["saw"] = true,
			["saw_secondary"] = true,
			["flamethrower_mk2"] = true,
			["m134"] = true,
			["mg42"] = true,
			["shuno"] = true,
			["system"] = true
		}

		--Allows users/modders to easily edit this blacklist from outside of this mod
		Hooks:Register("AFSF2_OnWriteBlacklist")
		Hooks:Add("BaseNetworkSessionOnLoadComplete","AFSF2_OnLoadComplete",function()
			Hooks:Call("AFSF2_OnWriteBlacklist",AutoFireSoundFixBlacklist)
		end)
		--if you would like to edit this blacklist, you can use the following example:
		--[[

		Hooks:Add("AFSF2_OnWriteBlacklist","PlaceholderHookIdGoesHere",function(blacklist_table)
			blacklist_table.mg42 = false --"nil" (no quotation marks) would also work instead of false
			blacklist_table.peacemaker = true
		end)

		--]]
		--(in this example, i remove the mg42 and add the peacekeeper .45 revolver)
		--You can hook this basically anywhere. I recommend "lib/units/weapons/raycastweaponbase" (same as AFSF2) if you don't know where to hook it. You could also change this version and uncomment it here, but then your changes would be removed when you update AFSF2. 

		--This blacklist defines which weapons are prevented from playing their single-fire sound in AFSF.
			--Weapons not on this list will repeatedly play their single-fire sound rather than their auto-fire loop.
			--Weapons on this list will play their sound as normal
			-- either due to being an unconventional weapon (saw, flamethrower, other saw, other flamethrower), or lacking a singlefire sound (minigun, mg42, other minigun).
		--I could define this in the function but meh	
			

		--Check for if AFSF's fix code should apply to this particular weapon
		function RaycastWeaponBase:_soundfix_should_play_normal()
			local name_id = self:get_name_id() or "xX69dank420blazermachineXx" --if somehow get_name_id() returns nil, crashing won't be my fault. though i guess you'll have bigger problems in that case. also you'll look dank af B)
			if not self._setup.user_unit == managers.player:player_unit() then
				--don't apply fix for NPCs or other players
				return true
			elseif tweak_data.weapon[name_id].use_fix ~= nil then 
				--for custom weapons
				return tweak_data.weapon[name_id].use_fix
			elseif AutoFireSoundFixBlacklist[name_id] then
				--blacklisted sound
				return true
			elseif not self:weapon_tweak_data().sounds.fire_single then
				--no singlefire sound; should play normal
				return true
			end
			return false
			--else, AFSF2 can apply fix to this weapon
		end

		--Prevent playing sounds except for blacklisted weapons
		local orig_fire_sound = RaycastWeaponBase._fire_sound
		function RaycastWeaponBase:_fire_sound(...)
			if self:_soundfix_should_play_normal() then
				return orig_fire_sound(self,...)
			end
		end

		--Play sounds here instead for fix-applicable weapons; or else if blacklisted, use original function and don't play the fixed single-fire sound
		--U200: there goes AFSF2's compatibility with other mods
		Hooks:PreHook(RaycastWeaponBase,"fire","autofiresoundfix2_raycastweaponbase_fire",function(self,...)
			self._bullets_fired = 0
			if not self:_soundfix_should_play_normal() then
				self:play_tweak_data_sound(self:weapon_tweak_data().sounds.fire_single,"fire_single")
			end
		end)

		--stop_shooting is only used for fire sound loops, so playing individual single-fire sounds means it doesn't need to be called
		local orig_stop_shooting = RaycastWeaponBase.stop_shooting
		function RaycastWeaponBase:stop_shooting(...)
			if self:_soundfix_should_play_normal() then
				return orig_stop_shooting(self,...)
			end
		--	if self._sound_fire then 
		--		self._sound_fire:stop() --stops sounds immediately and without a reverb. unfortunately this cuts off the fire sound prematurely because it is VERY immediate.
		--	end
		end
	end
elseif string.lower(RequiredScript) == "lib/units/enemies/tank/logics/tankcoplogicattack" then
	if not ShaveHUD:getSetting({"Fixes", "DOZER_SPRINT"}, true) then
		return
	end
	local old_chase = TankCopLogicAttack._chk_request_action_walk_to_chase_pos
	function TankCopLogicAttack._chk_request_action_walk_to_chase_pos(data, my_data, speed, end_rot)
		local new_speed = speed
		local focus_enemy = data.attention_obj
		if focus_enemy then
			local dist = focus_enemy.verified_dis
			local run_dist = focus_enemy.verified and 1500 or 800
			if dist < run_dist then
				new_speed = "walk"
			end
		end
		return old_chase(data, my_data, new_speed, end_rot)
	end
elseif string.lower(RequiredScript) == "lib/network/base/hostnetworksession" then
	if not ShaveHUD:getSetting({"Fixes", "STALE_LOBBY"}, true) then
		return
	end

	if _G.StaleLobbyContractFix then
		return
	else
		_G.StaleLobbyContractFix = true
	end

	-- This gets called at various points, including the mission briefing GUI and menu lobby (after completing / terminating a
	-- contract)
	local chk_server_joinable_state_actual = HostNetworkSession.chk_server_joinable_state
	function HostNetworkSession:chk_server_joinable_state(...)
		chk_server_joinable_state_actual(self, ...)

		-- From HostNetworkSession:on_load_complete()
		if Global.load_start_menu_lobby and MenuCallbackHandler ~= nil then
			-- Force a server attributes refresh so that completed / terminated contracts do not continue to be sent to prospective
			-- clients. Verify the change by inspecting the table returned by MenuCallbackHandler:get_matchmake_attributes() before
			-- and after the following calls
			MenuCallbackHandler:update_matchmake_attributes()
			MenuCallbackHandler:_on_host_setting_updated()
		end
	end
elseif string.lower(RequiredScript) == "lib/modifiers/modifiershieldphalanx" then
	if not ShaveHUD:getSetting({"Fixes", "CRIMESPREE_PHALANX_SPAWN_LIMIT"}, true) then
		return
	end
	function ModifierShieldPhalanx:init(data)
		ModifierShieldPhalanx.super.init(data)
		
		tweak_data.group_ai.unit_categories.CS_shield = deep_clone(tweak_data.group_ai.unit_categories.Phalanx_minion)
		tweak_data.group_ai.unit_categories.FBI_shield = deep_clone(tweak_data.group_ai.unit_categories.Phalanx_minion)
		
		tweak_data.group_ai.unit_categories.CS_shield.is_captain = false
		tweak_data.group_ai.unit_categories.FBI_shield.is_captain = false
	end
elseif string.lower(RequiredScript) == "lib/network/matchmaking/networkmatchmakingsteam" then
	if not ShaveHUD:getSetting({"Fixes", "CRIMESPREE_RANKSPREAD_FILTER"}, true) then
		return
	end
	
	if CrimeSpreeFilterFix_NetworkMatchMakingSTEAM_Hooked then
		return
	else
		CrimeSpreeFilterFix_NetworkMatchMakingSTEAM_Hooked = true
	end
	-- Current as at U143
	function NetworkMatchMakingSTEAM:search_lobby(friends_only, no_filters)
		self._search_friends_only = friends_only
		if not self:_has_callback("search_lobby") then
			return
		end
		local is_key_valid = function(key)
			return key ~= "value_missing" and key ~= "value_pending"
		end
		if friends_only then
			self:get_friends_lobbies()
		else
			local function refresh_lobby()
				if not self.browser then
					return
				end
				local lobbies = self.browser:lobbies()
				local info = {
					room_list = {},
					attribute_list = {}
				}
				if lobbies then
					for _, lobby in ipairs(lobbies) do
						if self._difficulty_filter == 0 or self._difficulty_filter == tonumber(lobby:key_value("difficulty")) then
							table.insert(info.room_list, {
								owner_id = lobby:key_value("owner_id"),
								owner_name = lobby:key_value("owner_name"),
								room_id = lobby:id(),
								owner_level = lobby:key_value("owner_level")
							})
							local attributes_data = {
								numbers = self:_lobby_to_numbers(lobby)
							}
							attributes_data.mutators = self:_get_mutators_from_lobby(lobby)
							local crime_spree_key = lobby:key_value("crime_spree")
							if is_key_valid(crime_spree_key) then
								attributes_data.crime_spree = tonumber(crime_spree_key)
								attributes_data.crime_spree_mission = lobby:key_value("crime_spree_mission")
							end
							table.insert(info.attribute_list, attributes_data)
						end
					end
				end
				self:_call_callback("search_lobby", info)
			end
			self.browser = LobbyBrowser(refresh_lobby, function()
			end)
			local interest_keys = {
				"owner_id",
				"owner_name",
				"level",
				"difficulty",
				"permission",
				"state",
				"num_players",
				"drop_in",
				"min_level",
				"kick_option",
				"job_class_min",
				"job_class_max"
			}
			if self._BUILD_SEARCH_INTEREST_KEY then
				table.insert(interest_keys, self._BUILD_SEARCH_INTEREST_KEY)
			end
			self.browser:set_interest_keys(interest_keys)
			self.browser:set_distance_filter(self._distance_filter)
			local use_filters = not no_filters
			if Global.game_settings.gamemode_filter == GamemodeCrimeSpree.id then
				use_filters = false
			end
			self.browser:set_lobby_filter(self._BUILD_SEARCH_INTEREST_KEY, "true", "equal")
			if use_filters then
				self.browser:set_lobby_filter("min_level", managers.experience:current_level(), "equalto_less_than")
				if Global.game_settings.search_appropriate_jobs then
					local min_ply_jc = managers.job:get_min_jc_for_player()
					local max_ply_jc = managers.job:get_max_jc_for_player()
					self.browser:set_lobby_filter("job_class_min", min_ply_jc, "equalto_or_greater_than")
					self.browser:set_lobby_filter("job_class_max", max_ply_jc, "equalto_less_than")
				end
			end
			if not no_filters then
				if Global.game_settings.gamemode_filter == GamemodeCrimeSpree.id then
					-- BEGIN MOD --
	--				local min_level = 0
	--				if 0 <= Global.game_settings.crime_spree_max_lobby_diff then
	--					min_level = managers.crime_spree:spree_level() - (Global.game_settings.crime_spree_max_lobby_diff or 0)
	--					min_level = math.max(min_level, 0)
	--				end
	--				self.browser:set_lobby_filter("crime_spree", min_level, "equalto_or_greater_than")
					-- Don't bother with all the rank restriction crap and just use the user's settings directly. The call to
					-- math.max() is to ensure that non-Crime Spree lobbies (i.e. -1 rank) do not appear
					self.browser:set_lobby_filter("crime_spree", math.max(Global.game_settings.crime_spree_max_lobby_diff or 0, 0), "equalto_or_greater_than")
					-- END MOD --
				elseif Global.game_settings.gamemode_filter == GamemodeStandard.id then
					self.browser:set_lobby_filter("crime_spree", -1, "equalto_less_than")
				end
			end
			if use_filters then
				for key, data in pairs(self._lobby_filters) do
					if data.value and data.value ~= -1 then
						self.browser:set_lobby_filter(data.key, data.value, data.comparision_type)
						print(data.key, data.value, data.comparision_type)
					end
				end
			end
			self.browser:set_max_lobby_return_count(self._lobby_return_count)
			if Global.game_settings.playing_lan then
				self.browser:refresh_lan()
			else
				self.browser:refresh()
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/crimespreetweakdata" then
	if not ShaveHUD:getSetting({"Fixes", "CRIMESPREE_CRASH_LOSS"}, true) then
		return
	end
	Hooks:PostHook( CrimeSpreeTweakData, "init", "BLEH", function(self, tweak_data)
		self.crash_causes_loss = false
	end)
elseif string.lower(RequiredScript) == "lib/units/enemies/cop/copmovement" then
	if not ShaveHUD:getSetting({"Fixes", "MAG_DROP"}, true) then
		return
	end
	function CopMovement:allow_dropped_magazines()
		if managers.weapon_factory:use_thq_weapon_parts() then
			return ShaveHUD:getSetting({"Fixes", "MAG_DROP"}, true)
		else
			return false
		end
	end
	Hooks:PostHook(CopMovement, "action_request", "action_request_mag_fix", function(self)
		if self._active_actions[3] and self._active_actions[3]:type() ~= "reload" and self._magazine_data and alive(self._magazine_data.unit) then
			self._magazine_data.unit:set_slot(0)
			self._magazine_data = nil
			
			local equipped_weapon = self._unit:inventory():equipped_unit()
	
			if alive(equipped_weapon) then
				for part_id, part_data in pairs(equipped_weapon:base()._parts) do
					local part = tweak_data.weapon.factory.parts[part_id]
	
					if part and part.type == "magazine" then
						part_data.unit:set_visible(true)
					end
				end
			end
		end
	end)
elseif string.lower(RequiredScript) == "lib/units/beings/player/huskplayermovement" then
	if not ShaveHUD:getSetting({"Fixes", "MAG_DROP"}, true) then
		return
	end
	function HuskPlayerMovement:allow_dropped_magazines()
		if managers.weapon_factory:use_thq_weapon_parts() then
			return ShaveHUD:getSetting({"Fixes", "MAG_DROP"}, true)
		else
			return false
		end
	end
	Hooks:PostHook(HuskPlayerMovement, "update", "husk_update_mag_fix", function(self)
		if not self._ext_anim.reload and self._magazine_data and alive(self._magazine_data.unit) then
			self._magazine_data.unit:set_slot(0)
			self._magazine_data = nil
			
			local equipped_weapon = self._unit:inventory():equipped_unit()
	
			if alive(equipped_weapon) then
				for part_id, part_data in pairs(equipped_weapon:base()._parts) do
					local part = tweak_data.weapon.factory.parts[part_id]
	
					if part and part.type == "magazine" then
						part_data.unit:set_visible(true)
					end
				end
			end
		end
	end)
elseif string.lower(RequiredScript) == "lib/managers/enemymanager" then
	if not ShaveHUD:getSetting({"Fixes", "MAG_DROP"}, true) then
		return
	end
	function EnemyManager:add_magazine(magazine, collision)
		local max_magazines = math.round(ShaveHUD:getSetting({"Fixes", "MAG_DROP_LIMIT"}, 30)) or 30
		self._magazines = self._magazines or {}
	
		table.insert(self._magazines, {
			magazine,
			collision
		})
	
		if max_magazines < #self._magazines then
			self:cleanup_magazines()
		end
	end
	function EnemyManager:cleanup_magazines()
		local max_magazines = math.round(ShaveHUD:getSetting({"Fixes", "MAG_DROP_LIMIT"}, 30)) or 30
		for i = 1, #self._magazines - max_magazines, 1 do
			for _, unit in ipairs(self._magazines[1]) do
				if alive(unit) then
					unit:set_slot(0)
				end
			end
	
			table.remove(self._magazines, 1)
		end
	end
end