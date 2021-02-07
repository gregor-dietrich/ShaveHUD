if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
	local set_teammate_ammo_amount_orig = HUDManager.set_teammate_ammo_amount
	local set_slot_ready_orig = HUDManager.set_slot_ready

	function HUDManager:set_teammate_ammo_amount(id, selection_index, max_clip, current_clip, current_left, max, ...)
		if ShaveHUD:getSetting({"CustomHUD", "USE_REAL_AMMO"}, true) then
			local total_left = current_left - current_clip
			if total_left >= 0 then
				current_left = total_left
				max = max - current_clip
			end
		end
		return set_teammate_ammo_amount_orig(self, id, selection_index, max_clip, current_clip, current_left, max, ...)
	end

	local FORCE_READY_CLICKS = 3
	local FORCE_READY_TIME = 2
	local FORCE_READY_ACTIVE_T = 90

	local force_ready_start_t = 0
	local force_ready_clicked = 0

	function HUDManager:set_slot_ready(peer, peer_id, ...)
		set_slot_ready_orig(self, peer, peer_id, ...)

		if Network:is_server() and not Global.game_settings.single_player then
			local session = managers.network and managers.network:session()
			local local_peer = session and session:local_peer()
			local time_elapsed = managers.game_play_central and managers.game_play_central:get_heist_timer() or 0
			if local_peer and local_peer:id() == peer_id then
				local t = Application:time()
				if (force_ready_start_t + FORCE_READY_TIME) > t then
					force_ready_clicked = force_ready_clicked + 1
					if force_ready_clicked >= FORCE_READY_CLICKS then
						local enough_wait_time = (time_elapsed > FORCE_READY_ACTIVE_T)
						local friends_list = not enough_wait_time and Steam:logged_on() and Steam:friends() or {}
						local abort = false
						for _, peer in ipairs(session:peers()) do
							local is_friend = false
							for _, friend in ipairs(friends_list) do
								if friend:id() == peer:user_id() then
									is_friend = true
									break
								end
							end
							if not (enough_wait_time or is_friend) or not (peer:synced() or peer:id() == local_peer:id()) then
								abort = true
								break
							end
						end
						if game_state_machine and not abort then
							local menu_options = {
								[1] = {
									text = managers.localization:text("dialog_yes"),
									callback = function(self, item)
										managers.chat:send_message(ChatManager.GAME, local_peer, "The Game was forced to start.")
										game_state_machine:current_state():start_game_intro()
									end,
								},
								[2] = {
									text = managers.localization:text("dialog_no"),
									is_cancel_button = true,
								}
							}
							QuickMenu:new( managers.localization:text("shavehud_dialog_force_start_title"), managers.localization:text("shavehud_dialog_force_start_desc"), menu_options, true )
						end
					end
				else
					force_ready_clicked = 1
					force_ready_start_t = t
				end
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/weaponfactorytweakdata" then
	if ShaveHUD:getSetting({"Misc", "AKIMBO_ANIMATIONS"}, true) then
		Hooks:PostHook(WeaponFactoryTweakData, "init", "akimboanimfactory_init", function(self)
			self.wpn_fps_pis_x_judge.override.wpn_fps_pis_judge_body_standard = {}
			self.wpn_fps_pis_x_judge.override.wpn_fps_pis_judge_body_modern = {}
			
			self.wpn_fps_pis_x_rage.override.wpn_fps_pis_rage_body_standard = {}
			self.wpn_fps_pis_x_rage.override.wpn_fps_pis_rage_body_smooth = {}
			
			self.wpn_fps_pis_x_2006m.override.wpn_fps_pis_2006m_body_standard = {}
			self.wpn_fps_pis_x_2006m.override.wpn_fps_pis_2006m_m_standard = {}
			
			self.wpn_fps_smg_x_m1928.override.wpn_fps_smg_thompson_drummag = {animations = {}}
		end)
	end

	if ShaveHUD:getSetting({"INVENTORY", "BIGGER_BETTER_REPLACED"}, true) then
		local sos_init_silencers_original = WeaponFactoryTweakData._init_silencers
		function WeaponFactoryTweakData:_init_silencers()
			sos_init_silencers_original(self)
			
			-- SpecOps Suppressed Barrel
			self.parts.wpn_fps_upg_ns_ass_smg_large.unit = "units/pd2_dlc_dec5/weapons/wpn_fps_smg_mp7_pts/wpn_fps_smg_mp7_b_suppressed"
			self.parts.wpn_fps_upg_ns_ass_smg_large.third_unit = "units/pd2_dlc_dec5/weapons/wpn_third_smg_mp7_pts/wpn_third_smg_mp7_b_suppressed"
			
			-- Jungle Ninja Suppressor
			-- self.parts.wpn_fps_upg_ns_ass_smg_large.unit = "units/pd2_dlc_butcher_mods/weapons/wpn_fps_upg_ns_pis_jungle/wpn_fps_upg_ns_pis_jungle"
			-- self.parts.wpn_fps_upg_ns_ass_smg_large.third_unit = "units/pd2_dlc_butcher_mods/weapons/wpn_third_upg_ns_pis_jungle/wpn_third_upg_ns_pis_jungle"
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/timespeedeffecttweakdata" then
	local init_original = TimeSpeedEffectTweakData.init
	local FORCE_ENABLE = {
		mission_effects = true,
	}
	function TimeSpeedEffectTweakData:init(...)
		init_original(self, ...)
		if ShaveHUD:getSetting({"SkipIt", "NO_SLOWMOTION"}, true) then
			local function disable_effect(table)
				for name, data in pairs(table) do
					if not FORCE_ENABLE[name] then
						if data.speed and data.sustain then
							data.speed = 1
							data.fade_in_delay = 0
							data.fade_in = 0
							data.sustain = 0
							data.fade_out = 0
						elseif type(data) == "table" then
							disable_effect(data)
						end
					end
				end
			end

			disable_effect(self)
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/economytweakdata" then
	if EconomyTweakData then
		-- Fix community market links for Real Weapon Names
		Hooks:PostHook(EconomyTweakData, "create_weapon_skin_market_search_url" ,"ShaveHUD_EconomyTweakDataPostCreateWeaponSkinMarketSearchUrl", function(self, weapon_id, cosmetic_id)
			local cosmetic_name = tweak_data.blackmarket.weapon_skins[cosmetic_id] and managers.localization:text(tweak_data.blackmarket.weapon_skins[cosmetic_id].name_id)
			local weapon_name = managers.localization.orig.text(managers.localization, tweak_data.weapon[weapon_id].name_id) -- bypass custom localizations
			if cosmetic_name and weapon_name then
				cosmetic_name = string.gsub(cosmetic_name, " ", "+")
				weapon_name = string.gsub(weapon_name, " ", "+")
				return string.gsub("http://steamcommunity.com/market/search?appid=218620&q=" .. cosmetic_name .. "+" .. weapon_name, "++", "+")
			end
			return nil
		end)
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/items/menuitemmultichoice" then
	if MenuItemMultiChoice then
		Hooks:PostHook( MenuItemMultiChoice , "setup_gui" , "MenuItemMultiChoicePostSetupGui_ShaveHUD" , function( self, node, row_item )
			if self:selected_option() and self:selected_option():parameters().color and row_item.choice_text then
				row_item.choice_text:set_blend_mode("normal")
			end
		end)
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/menunodegui" then
	if MenuNodeMainGui then
		Hooks:PostHook( MenuNodeMainGui , "_add_version_string" , "MenuNodeMainGuiPostAddVersionString_ShaveHUD" , function( self )
			if alive(self._version_string) then
				self._version_string:set_text("Payday 2 v" .. Application:version() .. " | ShaveHUD v" .. ShaveHUD:getVersion())
			end
		end)
	end
elseif string.lower(RequiredScript) == "lib/managers/experiencemanager" then
	local cash_string_original = ExperienceManager.cash_string

	function ExperienceManager:cash_string(...)
		local val = cash_string_original(self, ...)
		if self._cash_sign ~= "$" and val:find(self._cash_sign) then
			val = val:gsub(self._cash_sign, "") .. self._cash_sign
		end
		return val
	end
elseif string.lower(RequiredScript) == "lib/managers/moneymanager" then
	function MoneyManager:total_string()
		local total = math.round(self:total())
		return managers.experience:cash_string(total)
	end
	function MoneyManager:total_collected_string()
		local total = math.round(self:total_collected())
		return managers.experience:cash_string(total)
	end
elseif string.lower(RequiredScript) == "lib/network/handlers/unitnetworkhandler" then
	if ShaveHUD:getSetting({"GADGETS", "NO_RED_LASERS"}, true) then
		function UnitNetworkHandler:set_weapon_gadget_color(unit, red, green, blue, sender)
			if not self._verify_character_and_sender(unit, sender) then
				return
			end
			if red and green and blue then 
				local threshold = 0.66 --can be changed at will
				--log("No Red Lasers: Filtered a red player laser! Attempted values " .. tostring(red) .. "|g:" .. tostring(green) .. "|b:" .. tostring(blue) .. " from sender" .. tostring(sender))
				if red * threshold > green + blue then --i'm only sanity checking my own stuff. if the other stuff crashes that's ovk's fault
					red = 1
					green = 51
					blue = 1
					--take that you red-laser-using SCUM
				end
			end
			unit:inventory():sync_weapon_gadget_color(Color(red / 255, green / 255, blue / 255))
		end
	end
elseif string.lower(RequiredScript) == "lib/units/cameras/fpcameraplayerbase" then
	if ShaveHUD:getSetting({"Fixes", "CLOAKER_CAM_LOCK"}, true) then
		function FPCameraPlayerBase:clbk_aim_assist(col_ray)
			if managers.controller:get_default_wrapper_type() ~= "pc" and managers.user:get_setting("aim_assist") then
				self:_start_aim_assist(col_ray, self._aim_assist)
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/weapontweakdata" then
	if ShaveHUD:getSetting({"Misc", "AKIMBO_ANIMATIONS"}, true) then
		Hooks:PostHook(WeaponTweakData, "init", "akimboanim_init", function(self)
			self.x_judge.weapon_hold = "x_chinchilla"
			self.x_judge.animations.reload_name_id = "x_chinchilla"
			self.x_judge.animations.second_gun_versions = self.x_judge.animations.second_gun_versions or {}
			self.x_judge.animations.second_gun_versions.reload = "reload"
			self.x_judge.sounds.reload = {
				wp_chinchilla_cylinder_out = "wp_rbull_drum_open",
				wp_chinchilla_eject_shells = "wp_rbull_shells_out",
				wp_chinchilla_insert = "wp_rbull_shells_in",
				wp_chinchilla_cylinder_in = "wp_rbull_drum_close"
			}
			self.x_rage.weapon_hold = "x_chinchilla"
			self.x_rage.animations.reload_name_id = "x_chinchilla"
			self.x_rage.animations.second_gun_versions = self.x_rage.animations.second_gun_versions or {}
			self.x_rage.animations.second_gun_versions.reload = "reload"
			self.x_rage.sounds.magazine_empty = nil
			self.x_rage.sounds.reload = {
				wp_chinchilla_cylinder_out = "wp_rbull_drum_open",
				wp_chinchilla_eject_shells = "wp_rbull_shells_out",
				wp_chinchilla_insert = "wp_rbull_shells_in",
				wp_chinchilla_cylinder_in = "wp_rbull_drum_close"
			}
			self.x_2006m.weapon_hold = "x_chinchilla"
			self.x_2006m.animations.reload_name_id = "x_chinchilla"
			self.x_2006m.sounds.magazine_empty = nil
			self.x_2006m.hidden_parts = {
				magazine = {"g_loader_lod0"}
			}
			self.x_2006m.sounds.reload = {
				wp_chinchilla_cylinder_out = "wp_mateba_open_barrel",
				wp_chinchilla_eject_shells = "wp_mateba_empty_barrel",
				wp_chinchilla_insert = "wp_mateba_put_in_bullets",
				wp_chinchilla_twist = "wp_mateba_speedloader_lid",
				wp_rbull_shell_hit_ground = "wp_mateba_shell_hit_ground",
				wp_chinchilla_cylinder_in = "wp_mateba_close_barrel"
			}
			self.x_coal.weapon_hold = "x_akmsu"
			self.x_coal.animations.reload_name_id = "x_akmsu"
			self.x_coal.sounds.reload = {
				wp_akmsu_x_take_new = "wp_coal_take_new_mag",
				wp_akmsu_x_clip_slide_out = "wp_coal_mag_out_back",
				wp_akmsu_x_clip_slide_in = "wp_coal_mag_in_front",	
				wp_akmsu_x_clip_in_contact = "wp_coal_mag_in_back",
				wp_akmsu_x_lever_pull = "wp_coal_pull_lever",
				wp_akmsu_x_lever_release = "wp_coal_release_lever"
			}
			self.x_rota.weapon_hold = "x_akmsu"
			self.x_rota.animations.reload_name_id = "x_basset"
			self.x_rota.sounds.reload = {
				wp_foley_generic_clip_take_new = "wp_rota_x_rotate_mag",
				basset_x_mag_out = "wp_rota_x_slide_out",
				basset_x_mag_in = "wp_rota_x_slide_in",	
				basset_x_lever_release = "wp_rota_x_grab_lift"
			}
			self.x_sparrow.sounds.reload = {
				wp_g17_clip_slide_out = "wp_sparrow_mag_out",
				wp_g17_clip_slide_in = "wp_sparrow_mag_in",
				wp_g17_lever_release = "wp_sparrow_cock"
			}
			self.x_pl14.sounds.reload = {
				wp_g17_clip_slide_out = "wp_sparrow_mag_out",
				wp_g17_clip_slide_in = "wp_sparrow_mag_in",
				wp_g17_lever_release = "wp_sparrow_cock"
			}
			self.x_hs2000.sounds.reload = {
				wp_g17_clip_slide_out = "wp_usp_clip_out",
				wp_g17_clip_slide_in = "wp_usp_clip_slide_in"
			}
			self.x_1911.sounds.reload = {
				wp_g17_clip_slide_out = "wp_usp_clip_out",
				wp_g17_clip_slide_in = "wp_usp_clip_slide_in"
			}
			self.x_p226.sounds.reload = {
				wp_g17_clip_slide_out = "wp_usp_clip_out",
				wp_g17_clip_slide_in = "wp_usp_clip_slide_in"
			}
			self.x_usp.sounds.reload = {
				wp_g17_clip_slide_out = "wp_usp_clip_out",
				wp_g17_clip_slide_in = "wp_usp_clip_slide_in"
			}
			self.x_packrat.sounds.reload = {
				wp_g17_clip_slide_out = "wp_packrat_mag_throw",
				wp_g17_clip_slide_in = "wp_packrat_mag_in",
				wp_g17_clip_grab = "wp_packrat_mag_contact",
				wp_g17_lever_release = "wp_packrat_slide_release"
			}
			self.x_hajk.sounds.reload = {
				wp_akmsu_x_clip_slide_out = "hajk_throw_mag",
				wp_akmsu_x_clip_slide_in = "hajk_push_in_mag",	
				wp_akmsu_x_clip_in_contact = "hajk_mag_contact",
				wp_akmsu_x_lever_pull = "hajk_pull_lever",
				wp_akmsu_x_lever_release = "hajk_release_lever"
			}
			self.x_mac10.sounds.reload = {
				wp_akmsu_x_clip_slide_out = "wp_mac10_clip_slide_out",
				wp_akmsu_x_clip_slide_in = "wp_mac10_clip_slide_in",	
				wp_akmsu_x_clip_in_contact = "wp_mac10_clip_in_contact",
				wp_akmsu_x_lever_pull = "wp_mac10_lever_pull",
				wp_akmsu_x_lever_release = "wp_mac10_lever_release"
			}
			self.x_cobray.sounds.reload = {
				wp_akmsu_x_clip_slide_out = "wp_mac10_clip_slide_out",
				wp_akmsu_x_clip_slide_in = "wp_mac10_clip_slide_in",	
				wp_akmsu_x_clip_in_contact = "wp_mac10_clip_in_contact",
				wp_akmsu_x_lever_pull = "wp_cobray_lever_pull",
				wp_akmsu_x_lever_release = "wp_cobray_lever_release"
			}
			self.x_scorpion.sounds.reload = {
				wp_akmsu_x_take_new = "wp_scorpion_clip_grab",
				wp_akmsu_x_clip_slide_out = "wp_scorpion_clip_slide_out",
				wp_akmsu_x_clip_slide_in = "wp_scorpion_clip_slide_in",	
				wp_akmsu_x_clip_in_contact = "wp_scorpion_clip_in_contact",
				wp_akmsu_x_lever_pull = "wp_scorpion_lever_pull",
				wp_akmsu_x_lever_release = "wp_scorpion_lever_release"
			}
			self.x_baka.sounds.reload = {
				wp_akmsu_x_take_new = "wp_baka_take_new",
				wp_akmsu_x_clip_slide_out = "wp_baka_mag_slide_out",
				wp_akmsu_x_clip_slide_in = "wp_baka_mag_slide_in",	
				wp_akmsu_x_clip_in_contact = "",
				wp_akmsu_x_lever_pull = "wp_baka_lever_pull",
				wp_akmsu_x_lever_release = "wp_baka_lever_release"
			}
			self.x_mp9.sounds.reload = {
				wp_akmsu_x_clip_slide_out = "wp_mac10_clip_slide_out",
				wp_akmsu_x_clip_slide_in = "wp_mac10_clip_slide_in",	
				wp_akmsu_x_clip_in_contact = "wp_mac10_clip_in_contact",
				wp_akmsu_x_lever_pull = "wp_mac10_lever_pull",
				wp_akmsu_x_lever_release = "wp_mac10_lever_release"
			}
			self.x_olympic.sounds.reload = {
				wp_akmsu_x_take_new = "wp_m4_clip_take_new",
				wp_akmsu_x_clip_slide_out = "wp_m4_clip_grab_out",
				wp_akmsu_x_clip_slide_in = "wp_m4_clip_slide_in",	
				wp_akmsu_x_clip_in_contact = "wp_m4_clip_in_contact",
				wp_akmsu_x_lever_pull = "wp_m4_lever_pull_in",
				wp_akmsu_x_lever_release = "wp_m4_lever_release"
			}
			--Reload sounds weren't included in the akimbo soundbank :rage:
			self.x_erma.sounds.reload = {
				wp_akmsu_x_take_new = "wp_erma_mag_grab_new",
				wp_akmsu_x_clip_slide_out = "wp_erma_mag_out",
				wp_akmsu_x_clip_slide_in = "wp_erma_mag_in",	
				wp_akmsu_x_clip_in_contact = "wp_erma_mag_connect",
				wp_akmsu_x_lever_pull = "wp_erma_slide_pull",
				wp_akmsu_x_lever_release = "wp_erma_slide_release"
			}
			self.x_tec9.sounds.reload = {
				wp_akmsu_x_take_new = "wp_tec9_clip_take_new",
				wp_akmsu_x_clip_slide_out = "wp_tec9_clip_slide_out",
				wp_akmsu_x_clip_slide_in = "wp_tec9_clip_slide_in",	
				wp_akmsu_x_clip_in_contact = "wp_tec9_clip_in_contact",
				wp_akmsu_x_lever_pull = "wp_tec9_lever_pull",
				wp_akmsu_x_lever_release = "wp_tec9_lever_release"
			}
			self.x_uzi.sounds.reload = {
				wp_akmsu_x_take_new = "wp_uzi_clip_take_new",
				wp_akmsu_x_clip_slide_out = "wp_uzi_clip_slide_out",
				wp_akmsu_x_clip_slide_in = "wp_uzi_clip_slide_in",	
				wp_akmsu_x_clip_in_contact = "",
				wp_akmsu_x_lever_pull = "wp_uzi_clip_lever_pull",
				wp_akmsu_x_lever_release = "wp_uzi_clip_lever_release"
			}
			self.x_m45.sounds.reload = {
				wp_akmsu_x_take_new = "wp_m45_clip_take_new",
				wp_akmsu_x_clip_slide_out = "wp_m45_clip_grab_out",
				wp_akmsu_x_clip_slide_in = "wp_m45_clip_slide_in",	
				wp_akmsu_x_clip_in_contact = "wp_m45_clip_in_contact",
				wp_akmsu_x_lever_pull = "wp_m45_lever_pull",
				wp_akmsu_x_lever_release = "wp_m45_lever_release"
			}
			self.x_mp7.sounds.reload = {
				wp_akmsu_x_take_new = "wp_mp7_clip_take_new",
				wp_akmsu_x_clip_slide_in = "wp_mp7_clip_slide_in"
			}
		end)
	end

	if ShaveHUD:getSetting({"Fixes", "THIRD_PERSON_RECOIL"}, true) then
		Hooks:PostHook(WeaponTweakData, "init", "tpsmod_enable_anims", function(self)
			local blacklist = {
				["c45_crew"] = true,
				["x_c45_crew"] = true,
				["r870_crew"] = true,
				["mossberg_crew"] = true,
				["m95_crew"] = true,
				["msr_crew"] = true,
				["r93_crew"] = true,
				["ksg_crew"] = true,
				["winchester1874_crew"] = true,
				["m37_crew"] = true,
				["china_crew"] = true,
				["boot_crew"] = true,
				["desertfox_crew"] = true,
				["ecp_crew"] = true,
				["arblast_crew"] = true,
				["frankish_crew"] = true,
				["hunter_crew"] = true
			}
			for i,v in pairs(self) do
				if not blacklist[i] and string.match(i, "_crew") then
					self[i].has_fire_animation = true
				end
			end
		end)
	end
elseif string.lower(RequiredScript) == "lib/units/weapons/npcsawweaponbase" then
	if ShaveHUD:getSetting({"Fixes", "RECOIL_THIRD_PERSON"}, true) then
		Hooks:PostHook(NPCSawWeaponBase, "fire_blank", "tpsmod_enable_saw_anims", function(self)
			if self:weapon_tweak_data().has_fire_animation then
				self:tweak_data_anim_play("fire")
			end
		end)
	end
elseif string.lower(RequiredScript) == "lib/managers/criminalsmanager" then
	if ShaveHUD:getSetting({"Fixes", "KEEP_HEIST_OUTFITS"}, true) then
		function CriminalsManager:update_character_visual_state(character_name, visual_state)
			local character = self:character_by_name(character_name)
		
			if not character or not character.taken or not alive(character.unit) then
				return
			end
		
			visual_state = visual_state or {}
			local current_level = managers.job and managers.job:current_level_id()																								  
			local unit = character.unit
			local is_local_peer = visual_state.is_local_peer or character.visual_state.is_local_peer or false
			local visual_seed = visual_state.visual_seed or character.visual_state.visual_seed or CriminalsManager.get_new_visual_seed()
			local mask_id = visual_state.mask_id or character.visual_state.mask_id
			local armor_id = visual_state.armor_id or character.visual_state.armor_id or "level_1"
			local armor_skin = visual_state.armor_skin or character.visual_state.armor_skin or "none"
			local player_style = self:active_player_style() or managers.blackmarket:get_default_player_style()
			local suit_variation = nil
			local user_player_style = visual_state.player_style or character.visual_state.player_style or managers.blackmarket:get_default_player_style()
		
			if not self:is_active_player_style_locked() and user_player_style ~= managers.blackmarket:get_default_player_style() then
				if current_level and tweak_data.levels[current_level].player_style then
					player_style = tweak_data.levels[current_level] and tweak_data.levels[current_level].player_style
				else													 
					player_style = user_player_style
					suit_variation = visual_state.suit_variation or character.visual_state.suit_variation or "default"
				end
			end
		
			local glove_id = visual_state.glove_id or character.visual_state.glove_id or managers.blackmarket:get_default_glove_id()
			local character_visual_state = {
				is_local_peer = is_local_peer,
				visual_seed = visual_seed,
				player_style = player_style,
				suit_variation = suit_variation,
				glove_id = glove_id,
				mask_id = mask_id,
				armor_id = armor_id,
				armor_skin = armor_skin
			}
		
			local function get_value_string(value)
				return is_local_peer and tostring(value) or "third_" .. tostring(value)
			end
		
			if player_style then
				local unit_name = tweak_data.blackmarket:get_player_style_value(player_style, character_name, get_value_string("unit"))
		
				if unit_name then
					self:safe_load_asset(character, unit_name, "player_style")
				end
			end
		
			if glove_id then
				local unit_name = tweak_data.blackmarket:get_glove_value(glove_id, character_name, "unit", player_style, suit_variation)
		
				if unit_name then
					self:safe_load_asset(character, unit_name, "glove_id")
				end
			end
		
			CriminalsManager.set_character_visual_state(unit, character_name, character_visual_state)
		
			character.visual_state = {
				is_local_peer = is_local_peer,
				visual_seed = visual_seed,
				player_style = user_player_style,
				suit_variation = suit_variation,
				glove_id = glove_id,
				mask_id = mask_id,
				armor_id = armor_id,
				armor_skin = armor_skin
			}
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/levelstweakdata" then
	if ShaveHUD:getSetting({"Fixes", "LOGICAL_HEIST_OUTFITS"}, true) then
		Hooks:PostHook(LevelsTweakData, "init", "HeistOutfits", function (self)
			self.mad.player_style = "winter_suit"
			self.dinner.player_style = "slaughterhouse"
		end)
	end
elseif string.lower(RequiredScript) == "lib/managers/mission/elementfilter" then
	if ShaveHUD:getSetting({"Fixes", "DIFF_CHECK_FALLBACK"}, true) then
		Hooks:PostHook(ElementFilter, "_check_difficulty", "DiffCheckFallbackFix", function(self)
			local diff = Global.game_settings and Global.game_settings.difficulty or "hard"
			--Death Sentence fallback
			local is_difficulty_sm_wish = self._values.difficulty_sm_wish == nil and self._values.difficulty_overkill_290 or self._values.difficulty_sm_wish
		
			if is_difficulty_sm_wish and diff == "sm_wish" then
				return true
			end
			
			--Mayhem fallback
			local is_difficulty_easy_wish = self._values.difficulty_easy_wish == nil and self._values.difficulty_overkill_290 or self._values.difficulty_easy_wish
		
			if is_difficulty_easy_wish and diff == "easy_wish" then
				return true
			end
		end)
	end
elseif string.lower(RequiredScript) == "lib/managers/mission/elementspawnenemydummy" then
	if ShaveHUD:getSetting({"Fixes", "CORRECT_DIFF_ENEMIES"}, true) then
		--check for sc ai changes and dw+ ai changes
		if (SC and SC._data and SC._data.sc_ai_toggle) or (DW and DW.settings and DW.settings.dw_enemy_toggle_value) then return end

		--lazy fixes
		local ai_type = tweak_data.levels:get_ai_group_type()
		local job = Global.level_data and Global.level_data.level_id
		if ai_type ~= "america" or job == "firestarter_2" then return end

		--one down
		local sm_wish = {
				["units/payday2/characters/ene_bulldozer_1/ene_bulldozer_1"] = "units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_2/ene_zeal_bulldozer_2",
				["units/payday2/characters/ene_bulldozer_2/ene_bulldozer_2"] = "units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer_3/ene_zeal_bulldozer_3",
				["units/payday2/characters/ene_bulldozer_3/ene_bulldozer_3"] = "units/pd2_dlc_gitgud/characters/ene_zeal_bulldozer/ene_zeal_bulldozer",
				["units/payday2/characters/ene_city_swat_1/ene_city_swat_1"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_city_swat_2/ene_city_swat_2"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_city_swat_3/ene_city_swat_3"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_fbi_swat_1/ene_fbi_swat_1"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_fbi_swat_2/ene_fbi_swat_2"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_swat_1/ene_swat_1"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_swat_2/ene_swat_2"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_swat_heavy_1/ene_swat_heavy_1"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_swat_heavy_r870/ene_swat_heavy_r870"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_shield_1/ene_shield_1"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield",
				["units/payday2/characters/ene_shield_2/ene_shield_2"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield",
				["units/payday2/characters/ene_city_shield/ene_city_shield"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_shield/ene_zeal_swat_shield",
				["units/payday2/characters/ene_fbi_1/ene_fbi_1"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat",
				["units/payday2/characters/ene_fbi_2/ene_fbi_2"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat",
				["units/payday2/characters/ene_fbi_3/ene_fbi_3"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat",
				["units/payday2/characters/ene_fbi_heavy_1/ene_fbi_heavy_1"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy",
				["units/payday2/characters/ene_fbi_heavy_r870/ene_fbi_heavy_r870"] = "units/pd2_dlc_gitgud/characters/ene_zeal_swat_heavy/ene_zeal_swat_heavy"
			}
		--so much variety in the units, thanks ovk. how about giving the bulldozers correct weapons after five months?

		--dont have to do cloakers because overkill at least did those correctly

		--death wish/mayhem
		local deathwish = {
				["units/payday2/characters/ene_fbi_swat_1/ene_fbi_swat_1"] = "units/payday2/characters/ene_city_swat_1/ene_city_swat_1",
				["units/payday2/characters/ene_fbi_swat_2/ene_fbi_swat_2"] = "units/payday2/characters/ene_city_swat_2/ene_city_swat_2",
				["units/payday2/characters/ene_swat_1/ene_swat_1"] = "units/payday2/characters/ene_city_swat_1/ene_city_swat_1",
				["units/payday2/characters/ene_swat_2/ene_swat_2"] = "units/payday2/characters/ene_city_swat_2/ene_city_swat_2",
				["units/payday2/characters/ene_swat_heavy_1/ene_swat_heavy_1"] = "units/payday2/characters/ene_city_heavy_g36/ene_city_heavy_g36",
				["units/payday2/characters/ene_swat_heavy_r870/ene_swat_heavy_r870"] = "units/payday2/characters/ene_city_heavy_r870/ene_city_heavy_r870",
				["units/payday2/characters/ene_shield_1/ene_shield_1"] = "units/payday2/characters/ene_city_shield/ene_city_shield",
				["units/payday2/characters/ene_shield_2/ene_shield_2"] = "units/payday2/characters/ene_city_shield/ene_city_shield",
				["units/payday2/characters/ene_fbi_heavy_1/ene_fbi_heavy_1"] = "units/payday2/characters/ene_city_heavy_g36/ene_city_heavy_g36",
				["units/payday2/characters/ene_fbi_heavy_r870/ene_fbi_heavy_r870"] = "units/payday2/characters/ene_city_heavy_r870/ene_city_heavy_r870"
			}
		--putting gensec shotgunners in there because overkill can't be bothered, even if the fire rate is messed up

		function ElementSpawnEnemyDummy:init(...)
			ElementSpawnEnemyDummy.super.init(self, ...)
			local ai_type = tweak_data.levels:get_ai_group_type()
			local difficulty = Global.game_settings and Global.game_settings.difficulty or "normal"
			local difficulty_index = tweak_data:difficulty_to_index(difficulty)
			local job = Global.level_data and Global.level_data.level_id

			if ai_type == "america" and job ~= "firestarter_2" then --only replace enemies if we're in america and not on firestarter 2, otherwise DHS appear in FBI office and it looks fucking stupid
				if difficulty_index == 8 then --DHS over GenSec/FBI
					if sm_wish[self._values.enemy] then
						self._values.enemy = sm_wish[self._values.enemy]
					end
					self._values.enemy = sm_wish[self._values.enemy] or self._values.enemy
				elseif difficulty_index == 7 or difficulty_index == 6 then --GenSec over FBI
					if deathwish[self._values.enemy] then
						self._values.enemy = deathwish[self._values.enemy]
					end
					self._values.enemy = deathwish[self._values.enemy] or self._values.enemy
				end

				self._enemy_name = self._values.enemy and Idstring(self._values.enemy) or Idstring("units/payday2/characters/ene_swat_1/ene_swat_1")
				self._values.enemy = nil
				self._units = {}
				self._events = {}
				self:_finalize_values()
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/network/base/networkpeer" then
	if ShaveHUD:getSetting({"CrewLoadout", "IDENTIFY_VR"}, true) then
		Hooks:PreHook(NetworkPeer,"set_is_vr","idvr_setvr",function(self)
			if not self._is_vr then --if using posthook or without this check, always outputs the message twice. I don't like that.
				managers.chat:_receive_message(1,"[ID_VR]", tostring(self._name) .. " is using VR!", Color('29FFC9'))
			end
		end)
	end

	if ShaveHUD:getSetting({"CrewLoadout", "AUTOKICK_CHEAT_MODS"}, true) then
		Hooks:PostHook(NetworkPeer, "set_ip_verified", "autokick_cheaters", function(self, state)
			if not Network:is_server() then
				return
			end
			DelayedCalls:Add( "autokick_cheater", 2, function()
				local user = Steam:user(self:ip())
				if user and user:rich_presence("is_modded") == "1" or self:is_modded() then
					managers.chat:feed_system_message(1, self:name() .. " HAS MODS! Checking...")
					for i, mod in ipairs(self:synced_mods()) do
						local mod_mini = string.lower(mod.name)	
						local kick_on = {}
						local potential_hax = {}
						local prob_not_clean = nil
		
						kick_on = {
							"pirate perfection",
							"p3dhack",
							"p3dhack free",
							"dlc unlocker",
							"skin unlocker",
							"p3dunlocker",
							"arsium's weapons rebalance recoil",
							"overkill mod",
							"selective dlc unlocker",
							"the great skin unlock",
							"beyond cheats",
							"fuck the flashbangs",
							"unhittable armour",
							"nokick4u",
							"instant overdrill",
							"texturei",
							"ultimate trainer 4"
						}
		
						for _, v in pairs(kick_on) do
							if mod_mini == v then
								local identifier = "cheater_banned_" .. tostring(self:id())
								managers.ban_list:ban(identifier, self:name())
								managers.chat:feed_system_message(1, self:name() .. " has been kicked because of using the mod: " .. mod.name)
								local message_id = 0
								message_id = 6
								managers.network:session():send_to_peers("kick_peer", self:id(), message_id)
								managers.network:session():on_peer_kicked(self, self:id(), message_id)
								return
							end
						end
		
						potential_hax = {
							"pirate",
							"p3d",
							"hack",
							"cheat",
							"unlocker",
							"unlock",
							"dlc",
							"trainer",
							"silent assassin",
							"carry stacker",
							"god",
							"x-ray",
							"mvp",
							"rebalance",
							"cook faster",
							"no pager on domination"
						}
		
						for k, pc in pairs(potential_hax) do
							if string.find(mod_mini, pc) then
								log("found something!")
								managers.chat:feed_system_message(1, self:name() .. " is using a mod that can be a potential cheating mod: " .. mod.name)
								prob_not_clean = 1
							end
						end
					end
		
					if prob_not_clean then
						managers.chat:feed_system_message(1, self:name() .. " has a warning... Check his mods/profile manually to be sure.")
					else
						managers.chat:feed_system_message(1, self:name() .. " seems to be clean.")
					end
				else
					managers.chat:feed_system_message(1, self:name() .. " doesn't seem to have mods.")
				end
			end)
		end)
	end
elseif string.lower(RequiredScript) == "lib/units/beings/player/huskplayerdamage" then
    if ShaveHUD:getSetting({"Misc", "PLAYER_BLOOD"}, true) then
        Hooks:PostHook(HuskPlayerDamage, "sync_damage_bullet", "blood_splat_hpdmg", function(self, attacker_unit, damage, i_body, height_offset)
            local hit_pos = mvector3.copy(self._unit:movement():m_com())
            local attack_dir = nil
        
            if attacker_unit then
                attack_dir = hit_pos - attacker_unit:position()
        
                mvector3.normalize(attack_dir)
            else
                attack_dir = self._unit:rotation():y()
            end
        
            managers.game_play_central:sync_play_impact_flesh(hit_pos, attack_dir)
        end)
    end
	if ShaveHUD:getSetting({"Misc", "LADDER_IMPROVEMENTS"}, true) then
		local orig_damage = PlayerDamage.damage_fall
		function PlayerDamage:damage_fall(...)
			if self._unit:movement():current_state()._state_data.on_ladder then
				return --no damage if you're using the slide-down-ladders feature
			end
			return orig_damage(self,...)
		end
	end
elseif string.lower(RequiredScript) == "lib/units/beings/player/playerdamage" then
    if ShaveHUD:getSetting({"Misc", "PLAYER_BLOOD"}, true) then
        Hooks:PostHook(PlayerDamage, "damage_bullet", "blood_splat_pdmg", function(self, attack_data)
            if not self:_chk_can_take_dmg() then
                return
            end
        
            local hit_pos = mvector3.copy(self._unit:movement():m_com())
            local attack_dir = nil
            local attacker_unit = attack_data.attacker_unit
        
            if attacker_unit then
                attack_dir = hit_pos - attacker_unit:position()
                mvector3.normalize(attack_dir)
            else
                attack_dir = self._unit:rotation():y()
            end
        
            managers.game_play_central:sync_play_impact_flesh(hit_pos, attack_dir)
        end)
	end
elseif string.lower(RequiredScript) == "lib/utils/accelbyte/telemetry" then
	if not ShaveHUD:getSetting({"Misc", "DISABLE_TELEMETRY"}, true) then
		return
	end

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
elseif string.lower(RequiredScript) == "lib/tweak_data/playertweakdata" then
	if not ShaveHUD:getSetting({"Misc", "NO_SWAY"}, true) then
		return
	end

	if not _PlayerTweakData_init then _PlayerTweakData_init = PlayerTweakData.init end
	function PlayerTweakData:init()
	_PlayerTweakData_init(self)
		for k, v in pairs(self.stances) do
			v.steelsight.shakers.breathing.amplitude = 0
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudmissionbriefing" then
	if ShaveHUD:getSetting({"Misc", "STARRING"}, true) then
		Hooks:PostHook( HUDMissionBriefing, "set_player_slot", "nephud_function_post_bs", function(self, nr, params)
			local criminal_name = managers.localization:text("menu_" .. tostring(params.character))
			local current_name = params.name
			local experience = (params.rank > 0 and managers.experience:rank_string(params.rank) .. "-" or "") .. tostring(params.level)
			
			local peer_id = tostring(nr)
			
			local main_panel = managers.hud._hud_blackscreen._blackscreen_panel:child("panel_" .. peer_id)
			local text_panel = main_panel:child("name_" .. peer_id)
			text_panel:set_text(current_name .. " as " .. criminal_name)
		
			if current_name == "Nepgearsy" then
				text_panel:set_color(Color(1, 0.72, 0.35, 1))
			end
		end)
	end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudblackscreen" then
	if ShaveHUD:getSetting({"Misc", "STARRING"}, true) then
		Hooks:PostHook( HUDBlackScreen, "init", "nephud_function_custom_bs", function(self, hud)
			local Net = _G.LuaNetworking
			local stage_data = managers.job:current_stage_data()
			local level_data = managers.job:current_level_data()
			local name_id = stage_data.name_id or level_data.name_id
		
			local heist_name_panel = self._blackscreen_panel:panel({
				visible = true,
				name = "heist_name_panel",
				y = -500,
				valign = "grow",
				halign = "grow",
				layer = 1
			})
			
			local heist_name_text = heist_name_panel:text({
				text = managers.localization:to_upper_text(name_id),
				font = tweak_data.menu.pd2_large_font,
				font_size = tweak_data.menu.pd2_small_large_size,
				align = "center",
				vertical = "bottom",
				color = Color.white
			})
		
			local starring_panel = self._blackscreen_panel:panel({
				visible = true,
				name = "starring_panel",
				y = -240,
				valign = "grow",
				halign = "grow",
				layer = 1
			})
		
			local host_panel = self._blackscreen_panel:panel({
				name = "panel_1",
				visible = true,
				y = -210,
				valign = "grow",
				halign = "grow",
				layer = 1
			})
		
			local blue_panel = self._blackscreen_panel:panel({
				name = "panel_2",
				visible = true,
				y = -185,
				valign = "grow",
				halign = "grow",
				layer = 1
			})
		
			local red_panel = self._blackscreen_panel:panel({
				name = "panel_3",
				visible = true,
				y = -160,
				valign = "grow",
				halign = "grow",
				layer = 1
			})
		
			local blonde_panel = self._blackscreen_panel:panel({
				name = "panel_4",
				visible = true,
				y = -135,
				valign = "grow",
				halign = "grow",
				layer = 1
			})
		
			local extra_panel = self._blackscreen_panel:panel({
				name = "panel_5",
				visible = true,
				y = -110,
				valign = "grow",
				halign = "grow",
				layer = 1
			})
		
			local total_peers = Net:GetNumberOfPeers()
		
			local host_name = managers.network.account:username_id()
			local host_id = Net:LocalPeerID()
			local blue_name = ""
			local red_name = ""
			local blonde_name = ""
			local extra_name = ""
		
			local host_color = Color(1,1,1,1)
			local blue_color = Color(1,1,1,1)
			local red_color = Color(1,1,1,1)
			local blonde_color = Color(1,1,1,1)
		
			local starring_with = starring_panel:text({
				text = "STARRING",
				font = tweak_data.menu.pd2_large_font,
				font_size = 35,
				align = "center",
				vertical = "bottom",
				color = Color(1,1,0.70,0)
			})
		
			local host_name_text = host_panel:text({
				name = "name_1",
				text = host_name,
				font = tweak_data.menu.pd2_large_font,
				font_size = 25,
				align = "center",
				vertical = "bottom",
				color = Color(1,1,1,1)
			})
		
			local blue_name_text = blue_panel:text({
				name = "name_2",
				text = blue_name,
				font = tweak_data.menu.pd2_large_font,
				font_size = 25,
				align = "center",
				vertical = "bottom",
				color = host_color
			})
		
			local red_name_text = red_panel:text({
				name = "name_3",
				text = red_name,
				font = tweak_data.menu.pd2_large_font,
				font_size = 25,
				align = "center",
				vertical = "bottom",
				color = blue_color
			})
		
			local blonde_name_text = blonde_panel:text({
				name = "name_4",
				text = blonde_name,
				font = tweak_data.menu.pd2_large_font,
				font_size = 25,
				align = "center",
				vertical = "bottom",
				color = red_color
			})
		
			local extra_name_text = extra_panel:text({
				name = "name_5",
				text = extra_name,
				font = tweak_data.menu.pd2_large_font,
				font_size = 25,
				align = "center",
				vertical = "bottom",
				color = blonde_color
			})
		end)
	end

	if not ShaveHUD:getSetting({"Misc", "DIFFICULTY_ANIMATION"}, true) then
		return
	end

	function HUDBlackScreen:_set_job_data()
		if not managers.job:has_active_job() then
			return
		end
		local job_panel = self._blackscreen_panel:panel({
			visible = true,
			name = "job_panel",
			y = 0,
			valign = "grow",
			halign = "grow",
			layer = 1
		})
		local risk_panel = job_panel:panel({name = "risk_panel"})
		local last_risk_level
		local blackscreen_risk_textures = tweak_data.gui.blackscreen_risk_textures
		for i = 1, managers.job:current_difficulty_stars() do
			local difficulty_name = tweak_data.difficulties[i + 2]
			local texture = blackscreen_risk_textures[difficulty_name] or "guis/textures/pd2/risklevel_blackscreen"
			last_risk_level = risk_panel:bitmap({
				visible = false,
				texture = texture,
				color = tweak_data.screen_colors.risk
			})
			last_risk_level:move((i - 1) * last_risk_level:w(), 0)
		end
		if last_risk_level then
			self._has_skull_data = true
			risk_panel:set_size(last_risk_level:right(), last_risk_level:bottom())
			risk_panel:set_center(job_panel:w() / 2, job_panel:h() / 2)
			risk_panel:set_position(math.round(risk_panel:x()), math.round(risk_panel:y()))
		else
			risk_panel:set_size(64, 64)
			risk_panel:set_center_x(job_panel:w() / 2)
			risk_panel:set_bottom(job_panel:h() / 2)
			risk_panel:set_position(math.round(risk_panel:x()), math.round(risk_panel:y()))
		end
		local risk_text_panel = job_panel:panel({name = "risk_text_panel"})
		local risk_text = risk_text_panel:text({
			visible = false,
			align = "center",
			text = managers.localization:to_upper_text(tweak_data.difficulty_name_id),
			font = tweak_data.menu.pd2_large_font,
			font_size = tweak_data.menu.pd2_small_large_size,
			color = tweak_data.screen_colors.risk
		})
		local _, _, w, h = risk_text:text_rect()
		risk_text:set_size(w, h)
		risk_text_panel:set_h(h)
		risk_text_panel:set_bottom(risk_panel:top())
		risk_text_panel:set_center_x(risk_panel:center_x())
		risk_text:set_position(0, 0)
	end

	function HUDBlackScreen:_animate_fade_in(mid_text)
		local job_panel = self._blackscreen_panel:child("job_panel")
		mid_text:set_alpha(1)
		if job_panel then
			job_panel:set_alpha(1)
			local panels = {}
			local panels_skulls = {}
			job_panel:animate(function(t)
				for i = 1, managers.job:current_difficulty_stars() do
					panels[i] = job_panel:child("risk_text_panel"):text({
						text = managers.localization:to_upper_text(tweak_data.difficulty_name_ids[tweak_data.difficulties[i + 2]]),
						align = "center",
						font = tweak_data.menu.pd2_large_font,
						font_size = tweak_data.menu.pd2_small_large_size,
						color = tweak_data.screen_colors.risk
					})
					local _, _, _, h = panels[i]:text_rect()
					panels[i]:set_h(h)
					panels[i]:set_y(-h)
					if self._has_skull_data then
						panels_skulls[i] = job_panel:child("risk_panel"):bitmap({
							visible = true,
							layer = 1,
							texture = tweak_data.gui.blackscreen_risk_textures[tweak_data.difficulties[i + 2]] or "guis/textures/pd2/risklevel_blackscreen",
							color = tweak_data.screen_colors.risk
						})
					end
					panels_skulls[i]:set_x(i == 1 and (job_panel:child("risk_panel"):w() / 2) - 32 or panels_skulls[i - 1]:x())
					if i == 1 then
						local ow, oh = panels_skulls[i]:size()
						over(0.1, function(o)
							panels_skulls[i]:set_size(math.lerp(ow * 0.75, ow, o), math.lerp(oh * 0.75, oh, o))
							panels_skulls[i]:set_position((job_panel:child("risk_panel"):w() / 2) - 32, 0)
						end)
					end
					job_panel:child("risk_panel"):animate(function(o)
						local ox = panels_skulls[i]:x()
						local ax = {}
						for a = i - 1, 1, -1 do
							ax[a] = panels_skulls[a]:x()
						end
						over(0.3, function(p)
							if panels_skulls[i] and i ~= 1 then
								panels_skulls[i]:set_x(math.lerp(panels_skulls[i]:x(), ox + (panels_skulls[i]:w() / 2), p))
								for a = i - 1, 1, -1 do
									panels_skulls[a]:set_x(math.lerp(panels_skulls[a]:x(), ax[a] - (panels_skulls[a]:w() / 2), p))
								end
							end
						end)
					end)
					wait(0.1)
					job_panel:child("risk_text_panel"):animate(function(o)
						over(0.3, function(p)
							panels[i]:set_y(math.lerp(panels[i]:y(), 0, p))
							if panels[i - 1] then
								panels[i - 1]:set_y(math.lerp(panels[i - 1]:y(), h, p))
							end
						end)
					end)
					wait(0.3)
				end
				if managers.job:current_difficulty_stars() + 2 == #tweak_data.difficulties then
					local glow = job_panel:child("risk_panel"):bitmap({
						alpha = 0,
						layer = 0,
						texture = "guis/textures/pd2/crimenet_marker_glow",
						color = Color.red
					})
					glow:set_x(panels_skulls[#panels_skulls]:x())
					over(0.5, function(o)
						glow:set_alpha(math.lerp(0, 1, o))
					end)
				end
			end)
		end
		self._blackscreen_panel:set_alpha(1)
	end
elseif string.lower(RequiredScript) == "lib/network/base/hostnetworksession" then
	if ShaveHUD:getSetting({"CrewLoadout", "IDENTIFY_VR"}, true) then
		Hooks:PostHook(HostNetworkSession, "on_peer_sync_complete", "host_informvr" , function(self, peer, peer_id)
			if _G.IS_VR then
				managers.chat:send_message( 1, managers.network:session():local_peer(), "I am using VR!")
			end
		end)
	end
elseif string.lower(RequiredScript) == "lib/network/base/clientnetworksession" then
	if ShaveHUD:getSetting({"CrewLoadout", "IDENTIFY_VR"}, true) then
		Hooks:PostHook(ClientNetworkSession,"on_peer_synched","client_informvr",function(self, peer_id, ...)
			if _G.IS_VR then 
				managers.chat:send_message( 1, managers.network:session():local_peer(), "I am using VR!" )
			end
		end)
	end
elseif string.lower(RequiredScript) == "lib/network/base/basenetworksession" then
	if not ShaveHUD:getSetting({"Misc", "KICK_FRIEND"}, true) then
		return
	end

	local Original_on_peer_kicked = BaseNetworkSession.on_peer_kicked
	function BaseNetworkSession:on_peer_kicked(peer, peer_id, message_id)
		if Network:is_server() then
			if message_id == 0 then
				if Steam:logged_on() then
					for _, user in ipairs(Steam:friends() or {}) do
						if user:id() == peer:user_id() then
							return Original_on_peer_kicked(self, peer, peer_id, 1)
						end
					end
				end
			end
		end
		return Original_on_peer_kicked(self, peer, peer_id, message_id)
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/lootdroptweakdata" then
	if not ShaveHUD:getSetting({"Misc", "REDUNDANT_CARD_REMOVAL"}, true) then
		return
	end

	local old_data = LootDropTweakData.init
	function LootDropTweakData:init(tweak_data)
		old_data(self, tweak_data)

		local min = 10
		local max = 100
		local range = {
			cash = {0, 0},
			weapon_mods = {50, 45},
			colors = {6, 11},
			textures = {7, 12},
			materials = {7, 12},
			masks = {10, 15},
			xp = {0, 0}
		}
		for i = min, max, 10 do
			local cash = math.lerp(range.cash[1], range.cash[2], i / max)
			local weapon_mods = math.lerp(range.weapon_mods[1], range.weapon_mods[2], i / max)
			local colors = math.lerp(range.colors[1], range.colors[2], i / max)
			local textures = math.lerp(range.textures[1], range.textures[2], i / max)
			local materials = math.lerp(range.materials[1], range.materials[2], i / max)
			local masks = math.lerp(range.masks[1], range.masks[2], i / max)
			local xp = math.lerp(range.xp[1], range.xp[2], i / max)
			self.WEIGHTED_TYPE_CHANCE[i] = {
				cash = cash,
				weapon_mods = weapon_mods,
				colors = colors,
				textures = textures,
				materials = materials,
				masks = masks,
				xp = xp
			}
		end
	end
elseif string.lower(RequiredScript) == "lib/units/enemies/cop/copdamage" then
	if not ShaveHUD:getSetting({"Misc", "BULLET_DECAPITATIONS"}, true) then
		return
	end

	if not _G.BulletDecapitations then
		BulletDecapitations = {}
	 end
	 
	if not BulletDecapitations.tweak_data then
		BulletDecapitations.tweak_data = {}
	 end
	 
	-- [[ BD Settings ]]
	 
	-- Change which weapons can decapitate enemies and stuff...
	-- Set to either: 'true' or 'nil' (false).
	BulletDecapitations.tweak_data.allowed_weapons = {
		["assault_rifle"] = true, -- Assault Rifle
		["pistol"] = true, -- Pistol
		["smg"] = true, -- SMG
		["shotgun"] = true, -- Shotgun
		["saw"] = true, -- OVE9000 Saw
		["lmg"] = true, -- LMG
		["snp"] = true, -- Sniper Rifle
		["akimbo"] = true, -- Akimbo Pistols
		["minigun"] = true -- Minigun
	 }
	 
	BulletDecapitations.tweak_data.enable_bullet_cops = true -- Enable decapitations for all allowed weapons, disable if you want want just want tasers or cloakers
	
	BulletDecapitations.tweak_data.twitch = true -- Enable body twitching on decapitations. Value 'true' by default.
	 
	BulletDecapitations.tweak_data.blood_time = 20 -- Determines how long a decapitated body will bleed.
	BulletDecapitations.tweak_data.twitch_rate = 1 -- The interval at which a body twitches.
	 
	-- "all" - Cloakers can be cut from head to torso. | "head" - Cloakers can be dismembered in the head only. | "body" - Cloakers can be dismembered in the body only. | "none" - Cloakers do not use the 'true' dismemberment system.
	BulletDecapitations.tweak_data.cloaker_decapitations = "all"
	 
	BulletDecapitations.tweak_data.taser_decapitations = true -- Enables the special decapitation for tasers when headshotted.
	 
	-- [[ End of BD Settings ]]
	 
	BulletDecapitations.cop_decapitation = {
		t = {},
		interval = {},
		attack_data = {},
		vfx = {},
		ragdoll = {},
		parts = {}
	 }
	 
	Hooks:PostHook( CopDamage , "damage_bullet" , "BD_CopDamagePostDamageBullet" , function( self, attack_data )
		if not attack_data.attacker_unit then
			attack_data.attacker_unit = managers.player:player_unit()
		end
		
		if attack_data.attacker_unit:inventory() and BulletDecapitations.tweak_data.allowed_weapons[tweak_data.weapon[attack_data.attacker_unit:inventory():equipped_unit():base():get_name_id()].category] ~= true then
			return
		end
	
		if self._dead then
			if self._unit:base()._tweak_table == "spooc" then
				local body = attack_data.body_name or attack_data.col_ray.body:name()
				if (body:key() == Idstring("head"):key() or body:key() == Idstring("hit_Head"):key() or body:key() == Idstring("rag_Head"):key()) and (BulletDecapitations.tweak_data.cloaker_decapitations == "all" or BulletDecapitations.tweak_data.cloaker_decapitations == "head") or body:key() == Idstring("hit_Head"):key() or body:key() == Idstring("rag_Head"):key() and (BulletDecapitations.tweak_data.cloaker_decapitations == "all" or BulletDecapitations.tweak_data.cloaker_decapitations == "head") then
					self._unit:sound():play("split_gen_head")
					self._unit:damage():run_sequence_simple("dismember_head")
				else
					if (BulletDecapitations.tweak_data.cloaker_decapitations == "all" or BulletDecapitations.tweak_data.cloaker_decapitations == "body") then
						self._unit:sound():play("split_gen_body")
						self._unit:damage():run_sequence_simple("dismember_body_top")
					end
				end
			end
			if self._unit:base()._tweak_table == "taser" then
				local body = attack_data.body_name or attack_data.col_ray.body:name()
				if (body:key() == Idstring("head"):key() or body:key() == Idstring("hit_Head"):key() or body:key() == Idstring("rag_Head"):key()) and BulletDecapitations.tweak_data.taser_decapitations then
					self._unit:sound():play("split_gen_head")
					self._unit:damage():run_sequence_simple("kill_tazer_headshot")
					return
				end
			end
			if BulletDecapitations.tweak_data.enable_bullet_cops then
				local body = attack_data.body_name or attack_data.col_ray.body:name()
				if body:key() then
					if not BulletDecapitations.cop_decapitation.parts[self._unit] then
						BulletDecapitations.cop_decapitation.parts[self._unit] = {}
					end
				
					self._unit:movement():enable_update()
					self._unit:movement()._frozen = nil
					if self._unit:movement()._active_actions[1] and self._unit:movement()._active_actions[1]:type() == "hurt" then
						self._unit:movement()._active_actions[1]:force_ragdoll(true)
					end
					
					local bone_head = self._unit:get_object(Idstring("Head"))
					local bone_body = self._unit:get_object(Idstring("Spine1"))
					
					if body:key() == Idstring("head"):key() or body:key() == Idstring("hit_Head"):key() or body:key() == Idstring("rag_Head"):key() then
						--self._unit:body(self._unit:get_object(Idstring("Head"))):set_enabled( false )
						
						BulletDecapitations.cop_decapitation.vfx[self._unit] = World:effect_manager():spawn({
							effect = Idstring("effects/payday2/particles/impacts/blood/blood_tendrils"),
							position = self._unit:get_object(Idstring("Neck")):position(),
							rotation = self._unit:get_object(Idstring("Neck")):rotation()
						})
						
						BulletDecapitations.cop_decapitation.parts[self._unit].Head = "Head"
					
						self:_spawn_head_gadget({
							position = bone_head:position(),
							rotation = bone_head:rotation(),
							dir = -self._unit:movement():m_head_rot():y()
						})
					elseif body:key() == Idstring("hit_LeftArm"):key() or body:key() == Idstring("hit_LeftForeArm"):key() or body:key() == Idstring("rag_LeftArm"):key() or body:key() == Idstring("rag_LeftForeArm"):key() then
						--self._unit:body(self._unit:get_object(Idstring("LeftArm"))):set_enabled( false )
						--self._unit:body(self._unit:get_object(Idstring("LeftForeArm"))):set_enabled( false )
						--self._unit:body(self._unit:get_object(Idstring("LeftHand"))):set_enabled( false )
						
						BulletDecapitations.cop_decapitation.parts[self._unit].LeftArm = "LeftArm"
					elseif body:key() == Idstring("hit_RightArm"):key() or body:key() == Idstring("hit_RightForeArm"):key() or body:key() == Idstring("rag_RightArm"):key() or body:key() == Idstring("rag_RightForeArm"):key() then
						--self._unit:body(self._unit:get_object(Idstring("RightArm"))):set_enabled( false )
						--self._unit:body(self._unit:get_object(Idstring("RightForeArm"))):set_enabled( false )
						--self._unit:body(self._unit:get_object(Idstring("RightHand"))):set_enabled( false )
						
						BulletDecapitations.cop_decapitation.parts[self._unit].RightArm = "RightArm"
					elseif body:key() == Idstring("hit_LeftUpLeg"):key() or body:key() == Idstring("hit_LeftLeg"):key() or body:key() == Idstring("rag_LeftUpLeg"):key() or body:key() == Idstring("rag_LeftLeg"):key() then
						--self._unit:body(self._unit:get_object(Idstring("LeftLeg"))):set_enabled( false )
						--self._unit:body(self._unit:get_object(Idstring("LeftFoot"))):set_enabled( false )
						
						BulletDecapitations.cop_decapitation.parts[self._unit].LeftLeg = "LeftLeg"
					elseif body:key() == Idstring("hit_RightUpLeg"):key() or body:key() == Idstring("hit_RightLeg"):key() or body:key() == Idstring("rag_RightUpLeg"):key() or body:key() == Idstring("rag_RightLeg"):key() then
						--self._unit:body(self._unit:get_object(Idstring("RightLeg"))):set_enabled( false )
						--self._unit:body(self._unit:get_object(Idstring("RightFoot"))):set_enabled( false )
						
						BulletDecapitations.cop_decapitation.parts[self._unit].RightLeg = "RightLeg"
					end
					
					BulletDecapitations.cop_decapitation.attack_data[self._unit] = attack_data
					BulletDecapitations.cop_decapitation.ragdoll[self._unit] = self._unit
					
					BulletDecapitations.cop_decapitation.t[self._unit] = Application:time() + BulletDecapitations.tweak_data.blood_time
					BulletDecapitations.cop_decapitation.interval[self._unit] = Application:time() + BulletDecapitations.tweak_data.twitch_rate
				end
			end
		end
	end )

	Hooks:PostHook( PlayerManager, "update", "BD_CopDecapitationUpdate", function(self, t, dt)
		if not CopDamage then return end
		if BulletDecapitations.cop_decapitation then
			for unit, val in pairs(BulletDecapitations.cop_decapitation.ragdoll) do
				if alive(unit) then
				else
					BulletDecapitations.cop_decapitation.ragdoll[unit] = nil
					BulletDecapitations.cop_decapitation.parts[unit] = nil
				end
			end
			for unit, val in pairs(BulletDecapitations.cop_decapitation.t) do
				if alive(unit) then
					for part , _ in pairs(BulletDecapitations.cop_decapitation.parts[unit]) do
						if part == "Head" then
							BulletDecapitations.cop_decapitation.vfx[unit] = World:effect_manager():spawn({
								effect = Idstring("effects/payday2/particles/impacts/blood/blood_tendrils"),
								position = unit:get_object(Idstring("Neck")):position(),
								rotation = unit:get_object(Idstring("Neck")):rotation()
							})
							if Application:time() < val then
								if Application:time() >= BulletDecapitations.cop_decapitation.interval[unit] then
									BulletDecapitations.cop_decapitation.interval[unit] = Application:time() + BulletDecapitations.tweak_data.twitch_rate
									
									local splatter_from = unit:get_object(Idstring("Neck")):position()
									local splatter_to = splatter_from + unit:get_object(Idstring("Neck")):rotation():y() * 100
									local splatter_ray = unit:raycast("ray", splatter_from, splatter_to, "slot_mask", managers.slot:get_mask("world_geometry"))
									if splatter_ray then
										World:project_decal(Idstring("blood_spatter"), splatter_ray.position, splatter_ray.ray, splatter_ray.unit, nil, splatter_ray.normal)
									end
									
									if unit:movement()._active_actions[1] and unit:movement()._active_actions[1]:type() == "hurt" then
										unit:movement()._active_actions[1]:force_ragdoll(true)
									end
									local scale = BulletDecapitations.tweak_data.twitch and 0.075 or 0
									local height = 1
									local twist_dir = math.random(2) == 1 and 1 or -1
									local rot_acc = (math.UP * (0.5 * twist_dir)) * -0.5
									local rot_time = 1 + math.rand(2)
									local nr_u_bodies = unit:num_bodies()
									local i_u_body = 0
									while nr_u_bodies > i_u_body do
										local u_body = unit:body(i_u_body)
										if u_body:enabled() and u_body:dynamic() then
											local body_mass = u_body:mass()
											World:play_physic_effect(Idstring("physic_effects/body_explosion"), u_body, math.UP * 600 * scale, 4 * body_mass / math.random(2), rot_acc, rot_time)
										end
										i_u_body = i_u_body + 1
									end
								end
							else
								BulletDecapitations.cop_decapitation.t[unit] = nil
								BulletDecapitations.cop_decapitation.interval[unit] = nil
								BulletDecapitations.cop_decapitation.attack_data[unit] = nil
							end
						end
					end
				else
					BulletDecapitations.cop_decapitation.t[unit] = nil
					BulletDecapitations.cop_decapitation.interval[unit] = nil
					BulletDecapitations.cop_decapitation.attack_data[unit] = nil
				end
			end
		end
	end )
elseif string.lower(RequiredScript) == "lib/units/enemies/cop/copmovement" then
	if not ShaveHUD:getSetting({"Misc", "BULLET_DECAPITATIONS"}, true) then
		return
	end

	Hooks:PreHook( CopMovement , "update" , "BulletDecapitationsPreCopMovementUpdate" , function( self , unit , t , dt )

		if not BulletDecapitations then return end
		
		for decap_unit, _ in pairs( BulletDecapitations.cop_decapitation.ragdoll ) do
			if decap_unit == unit then
				local bone_body = self._unit:get_object(Idstring("LeftUpLeg"))
				local bone_body2 = self._unit:get_object(Idstring("RightUpLeg"))
				local bone_body3 = self._unit:get_object(Idstring("LeftShoulder"))
				local bone_body4 = self._unit:get_object(Idstring("RightShoulder"))
				local bone_body5 = self._unit:get_object(Idstring("Spine1"))
				
				self._need_upd = false
				self._force_head_upd = nil
				
				self:upd_ground_ray()
				
				--[[self._unit:movement():enable_update()
				self._unit:movement()._frozen = nil
				if self._unit:movement()._active_actions[1] then
					self._unit:movement()._active_actions[1]:force_ragdoll()
				end]]
				
				for part , _ in pairs( BulletDecapitations.cop_decapitation.parts[unit] ) do
					if part == "Head" then
						self._unit:get_object(Idstring("Head")):m_position(bone_body5:position())
						self._unit:get_object(Idstring("Head")):set_position(bone_body5:position())
						self._unit:get_object(Idstring("Head")):set_rotation(bone_body5:rotation())
					elseif part == "LeftArm" then
						self._unit:get_object(Idstring("LeftArm")):m_position(bone_body3:position())
						self._unit:get_object(Idstring("LeftArm")):set_position(bone_body3:position())
						self._unit:get_object(Idstring("LeftArm")):set_rotation(bone_body3:rotation())
						self._unit:get_object(Idstring("LeftForeArm")):m_position(self._unit:get_object(Idstring("LeftArm")):position())
						self._unit:get_object(Idstring("LeftForeArm")):set_position(self._unit:get_object(Idstring("LeftArm")):position())
						self._unit:get_object(Idstring("LeftForeArm")):set_rotation(self._unit:get_object(Idstring("Spine1")):rotation())
						self._unit:get_object(Idstring("LeftHand")):m_position(self._unit:get_object(Idstring("Spine1")):position())
						self._unit:get_object(Idstring("LeftHand")):set_position(self._unit:get_object(Idstring("Spine1")):position())
						self._unit:get_object(Idstring("LeftHand")):set_rotation(self._unit:get_object(Idstring("Spine1")):rotation())
					end
					if part == "RightArm" then
						self._unit:get_object(Idstring("RightArm")):m_position(bone_body4:position())
						self._unit:get_object(Idstring("RightArm")):set_position(bone_body4:position())
						self._unit:get_object(Idstring("RightArm")):set_rotation(bone_body4:rotation())
						self._unit:get_object(Idstring("RightForeArm")):m_position(self._unit:get_object(Idstring("RightArm")):position())
						self._unit:get_object(Idstring("RightForeArm")):set_position(self._unit:get_object(Idstring("RightArm")):position())
						self._unit:get_object(Idstring("RightForeArm")):set_rotation(self._unit:get_object(Idstring("Spine1")):rotation())
						self._unit:get_object(Idstring("RightHand")):m_position(self._unit:get_object(Idstring("Spine1")):position())
						self._unit:get_object(Idstring("RightHand")):set_position(self._unit:get_object(Idstring("Spine1")):position())
						self._unit:get_object(Idstring("RightHand")):set_rotation(self._unit:get_object(Idstring("Spine1")):rotation())
					end
					if part == "LeftLeg" then
						self._unit:get_object(Idstring("LeftLeg")):m_position(bone_body:position())
						self._unit:get_object(Idstring("LeftLeg")):set_position(bone_body:position())
						self._unit:get_object(Idstring("LeftLeg")):set_rotation(bone_body:rotation())
						self._unit:get_object(Idstring("LeftFoot")):m_position(self._unit:get_object(Idstring("Hips")):position())
						self._unit:get_object(Idstring("LeftFoot")):set_position(self._unit:get_object(Idstring("Hips")):position())
						self._unit:get_object(Idstring("LeftFoot")):set_rotation(self._unit:get_object(Idstring("Hips")):rotation())
					end
					if part == "RightLeg" then
						self._unit:get_object(Idstring("RightLeg")):m_position(bone_body2:position())
						self._unit:get_object(Idstring("RightLeg")):set_position(bone_body2:position())
						self._unit:get_object(Idstring("RightLeg")):set_rotation(bone_body2:rotation())
						self._unit:get_object(Idstring("RightFoot")):m_position(self._unit:get_object(Idstring("Hips")):position())
						self._unit:get_object(Idstring("RightFoot")):set_position(self._unit:get_object(Idstring("Hips")):position())
						self._unit:get_object(Idstring("RightFoot")):set_rotation(self._unit:get_object(Idstring("Hips")):rotation())
					end
				end
			end
		end
	end )
elseif string.lower(RequiredScript) == "lib/tweak_data/blackmarket/maskstweakdata" then
	if not ShaveHUD:getSetting({"INVENTORY", "RETURNABLE_MASK_COMPONENTS"}, true) then
		return
	end
	
    local original_init_masks = BlackMarketTweakData._init_masks
    function BlackMarketTweakData:_init_masks(tweak_data)
        original_init_masks(self, tweak_data)
        for _, mask in pairs(self.masks) do
            mask.value = 0
        end
    end
elseif string.lower(RequiredScript) == "lib/tweak_data/blackmarket/materialstweakdata" then
	if not ShaveHUD:getSetting({"INVENTORY", "RETURNABLE_MASK_COMPONENTS"}, true) then
		return
	end
	
    local original_init_materials = BlackMarketTweakData._init_materials
    function BlackMarketTweakData:_init_materials(tweak_data)
        original_init_materials(self, tweak_data)
        for _, material in pairs(self.materials) do
            material.value = 0
        end
    end
elseif string.lower(RequiredScript) == "lib/tweak_data/blackmarket/texturestweakdata" then
	if not ShaveHUD:getSetting({"INVENTORY", "RETURNABLE_MASK_COMPONENTS"}, true) then
		return
	end
	
    local original_init_textures = BlackMarketTweakData._init_textures
    function BlackMarketTweakData:_init_textures(tweak_data)
        original_init_textures(self, tweak_data)
        for _, texture in pairs(self.textures) do
            texture.value = 0
        end
    end
elseif string.lower(RequiredScript) == "lib/tweak_data/blackmarket/colorstweakdata" then
	if not ShaveHUD:getSetting({"INVENTORY", "RETURNABLE_MASK_COMPONENTS"}, true) then
		return
	end
	
    local original_init_colors = BlackMarketTweakData._init_colors
    function BlackMarketTweakData:_init_colors(tweak_data)
        original_init_colors(self, tweak_data)
        for _, color in pairs(self.colors) do
            color.value = 0
        end
    end
elseif string.lower(RequiredScript) == "lib/units/beings/player/states/playerstandard" then
	if not ShaveHUD:getSetting({"Misc", "LADDER_IMPROVEMENTS"}, true) then
		return
	end

    --too lazy to check which of these are actually needed, especially since i might need them again later if i change the mod
    local mvec3_dis_sq = mvector3.distance_sq
    local mvec3_set = mvector3.set
    local mvec3_set_z = mvector3.set_z
    local mvec3_sub = mvector3.subtract
    local mvec3_add = mvector3.add
    local mvec3_mul = mvector3.multiply
    local mvec3_norm = mvector3.normalize

    local temp_vec1 = Vector3()

    local tmp_ground_from_vec = Vector3()
    local tmp_ground_to_vec = Vector3()
    local up_offset_vec = math.UP * 30
    local down_offset_vec = math.UP * -40

    local win32 = SystemInfo:platform() == Idstring("WIN32")

    local mvec_pos_new = Vector3()
    local mvec_achieved_walk_vel = Vector3()
    local mvec_move_dir_normalized = Vector3()


    local orig_check_jump = PlayerStandard._check_action_jump
    function PlayerStandard:_check_action_jump(t, input)
        if input.btn_jump_press then 
            --don't need to check for action forbidden or cooldown, since this only applies to ladders
            if self._state_data.ducking then 
                --nothing
            elseif self._state_data.on_ladder then
                self:_interupt_action_ladder(t)
                return --this is the only thing i've really changed: no jumping on ladders >:(
            end
        end
        return orig_check_jump(self,t,input)
    end

    function PlayerStandard:_check_action_ladder(t, input)
            local downed = self._controller:get_any_input() --input.downed
            local hold_jump = downed and self._controller:get_input_bool("jump")
            local release_jump = released and self._controller:get_input_released("jump")
            local hold_duck = downed and self._controller:get_input_bool("duck")
            
        if self._state_data.on_ladder then
            local ladder_unit = self._unit:movement():ladder_unit()
            
            if not hold_jump and ladder_unit:ladder():check_end_climbing(self._unit:movement():m_pos(), self._normal_move_dir, self._gnd_ray) then
                self:_end_action_ladder(t,input) --doesn't really need any arguments but just in case some other modder wants to do something with that
                return
            elseif hold_jump then 
                self:_end_action_ladder(t,input)
                return
            end

            if hold_duck and self._unit:mover() then
                self._unit:mover():set_gravity(Vector3(0, 0, -982))
                return
            elseif input.btn_duck_release and self._unit:mover() then
                self._unit:mover():set_gravity(Vector3(0,0,0))
                self._unit:mover():set_velocity(Vector3())
            end

        elseif hold_jump then 
            return --if hold jump, don't try to detect ladders + start climbing
        end

        local u_pos = self._unit:movement():m_pos()
        local ladder_unit

        for i = 1, math.min(Ladder.LADDERS_PER_FRAME, #Ladder.active_ladders), 1 do
            ladder_unit = Ladder.next_ladder()

            if alive(ladder_unit) then

                local can_access = ladder_unit:ladder():can_access(u_pos, self._move_dir or self._ext_camera:forward())
                --if not moving (self._move_dir) then check for valid ladder positions using camera direction
                --this way, player will automatically grab any ladder that they are facing
                --TACTICOOL REALISM WINS AGAIN WOOOO
                if can_access then
                    self:_start_action_ladder(t, ladder_unit)
                    break
                end
            end
        end
    end
elseif string.lower(RequiredScript) == "lib/units/weapons/akimboweaponbase" then
	if not ShaveHUD:getSetting({"EQUIPMENT", "ENABLE_AKIMBO_MODE"}, true) then
		return
	end

    function AkimboWeaponBase:toggle_akimbo_fire()
		self._manual_fire_second_gun = not self._manual_fire_second_gun
		local on = self._manual_fire_second_gun
		managers.hud:show_hint({
			text = on and "x1 fire" or "x2 fire",
			time = 0.5
		})
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/vehicletweakdata" then
	if not ShaveHUD:getSetting({"Misc", "VEHICLE_FOV"}, true) then
		return
	end

	local old_init = VehicleTweakData.init
	local new_fov = ShaveHUD:getSetting({"Misc", "VEHICLE_FOV_VALUE"}, 90)

	function VehicleTweakData:init(tweak_data)
		old_init(self, tweak_data)

		self.falcogini.fov = new_fov
		self.muscle.fov = new_fov
		self.forklift.fov = new_fov
		self.forklift_2.fov = new_fov
		self.box_truck_1.fov = new_fov
		self.mower_1.fov = new_fov
		self.boat_rib_1.fov = new_fov
		self.blackhawk_1.fov = new_fov
		self.bike_1.fov = new_fov
		self.bike_2.fov = new_fov
	end
elseif string.lower(RequiredScript) == "lib/units/enemies/cop/copinventory" then
	if not ShaveHUD:getSetting({"Misc", "SHIELD_DESPAWN_TIMER"}, true) then
		return
	end
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
elseif string.lower(RequiredScript) == "lib/units/weapons/newraycastweaponbase" then
	if not ShaveHUD:getSetting({"Misc", "AKIMBO_ANIMATIONS"}, true) then
		return
	end
	Hooks:PostHook(NewRaycastWeaponBase, "clbk_assembly_complete", "akimboanim_hideobject", function(self)
		local hidden_data = tweak_data.weapon[self._name_id].hidden_parts
	
		if hidden_data then
			for part_type, part_data in pairs(hidden_data) do
				local part_list = managers.weapon_factory:get_parts_from_weapon_by_type_or_perk(part_type, self._factory_id, self._blueprint)
	
				for _, part_name in ipairs(part_list) do
					local part = self._parts[part_name]
					local objects = type(part_data) == "table" and (part_data[part_name] or part_data[1] and part_data) or true
	
					if objects then
						if type(objects) == "table" then
							for _, object_name in ipairs(objects) do
								local object = part.unit:get_object(Idstring(object_name))
	
								if alive(object) then
									object:set_visibility(false)
	
									if self._hidden_objects then
										self._hidden_objects[part_name] = self._hidden_objects[part_name] or {}
	
										table.insert(self._hidden_objects[part_name], object_name)
									end
								end
							end
						else
							part.unit:set_visible(false)
							self:_set_part_temporary_visibility(part_name, false)
	
							if self._hidden_objects then
								self._hidden_objects[part_name] = true
							end
						end
					end
				end
			end
		end
	end)
end