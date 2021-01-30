if not ShaveHUD:getSetting({"INVENTORY", "INVENTORY_COUNT"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/managers/menu/blackmarketgui" then
	function BlackMarketGui:populate_deployables(data)
		local new_data = {}
		local sort_data = managers.blackmarket:get_sorted_deployables()
		local max_items = math.ceil(#sort_data / (data.override_slots[1] or 3)) * (data.override_slots[1] or 3)
		for i = 1, max_items do
			data[i] = nil
		end
		local guis_catalog = "guis/"
		local index = 0
		local second_deployable = managers.player:has_category_upgrade("player", "second_deployable")
		for i, deployable_data in ipairs(sort_data) do
			guis_catalog = "guis/"
			local bundle_folder = tweak_data.blackmarket.deployables[deployable_data[1]] and tweak_data.blackmarket.deployables[deployable_data[1]].texture_bundle_folder
			if bundle_folder then
				guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
			end
			new_data = {}
			new_data.name = deployable_data[1]

			local amount = 1
			if new_data.name == "first_aid_kit" then 
				amount = 4
				elseif new_data.name == "trip_mine" then
				amount = 3
			end
			amount = amount + (managers.player:equiptment_upgrade_value(new_data.name, "quantity") or 0)
				if new_data.name == "sentry_gun_silent" then
					amount = amount + (managers.player:equiptment_upgrade_value("sentry_gun", "quantity") or 0)
				end
				
			local amount2 = " Uses Total"	
				if new_data.name == "ammo_bag" then
					amount2 = "00% Ammo Total"
				elseif new_data.name == "bodybags_bag" then
					amount2 = " Body Bags Total"
				elseif new_data.name == "ecm_jammer" then
					amount2 = " Seconds Total"
				elseif new_data.name == "trip_mine" then
					amount2 = " Shaped Charges"
				elseif new_data.name == "sentry_gun" and amount == 1 then
					amount2 = " Redeployable Sentry Gun"
				elseif new_data.name == "sentry_gun" then
					amount2 = " Redeployable Sentry Guns"
				elseif new_data.name == "sentry_gun_silent" and amount == 1 then
					amount2 = " Redeployable Sentry Gun"
				elseif new_data.name == "sentry_gun_silent" then
					amount2 = " Redeployable Sentry Guns"
				elseif new_data.name == "armor_kit" then
					amount2 = " Use Total"
				else
					amount2 = " Uses Total"
			end		
			
			local amount3 = managers.player:has_category_upgrade("ecm_jammer", "duration_multiplier")
			if amount3 == 0 and managers.player:has_category_upgrade("ecm_jammer", "duration_multiplier_2") then
			amount3 = 1.25
			elseif amount3 == 0 then
				amount3 = 1
			elseif managers.player:has_category_upgrade("ecm_jammer", "duration_multiplier_2") then
				amount3 = 1.5
			else 
				amount3 = 1
			end
			
			local amount5 = ""
			local amount4 = ""
				if new_data.name == "trip_mine" then
				amount4 = " Trip Mines"
				amount5 = "x"
				end
				
			local amount1 = 1
			if new_data.name == "ammo_bag" then
				amount1 = amount * (4 + (managers.player:equiptment_upgrade_value(new_data.name, "ammo_increase") or 0))
			elseif new_data.name == "bodybags_bag" then
				amount1 = 3 + (3 * (managers.player:equiptment_upgrade_value(new_data.name, "quantity") or 0))
			elseif new_data.name == "doctor_bag" then
				amount1 = amount * (2 + (1 * (managers.player:equiptment_upgrade_value(new_data.name, "amount_increase") or 0)))
			elseif new_data.name == "ecm_jammer" then
				amount1 = amount * (20 * amount3)
			elseif new_data.name == "trip_mine" then
				amount1 = 3 + (managers.player:equiptment_upgrade_value("shape_charge", "quantity") or 0)
			else 
				amount1 = amount
			end
			
	--[[]]		
			local amount7 = ""
			if managers.player:has_category_upgrade(new_data.name, "can_open_sec_doors") then
				amount7 = " > Unlocks Security Doors\n"
			else
				amount7 = amount7
			end		
			if managers.player:has_category_upgrade(new_data.name, "affects_pagers") then
				amount7 = amount7 .. " > Delays Pagers\n"
			else 
				amount7 = amount7
			end
				
			if managers.player:equiptment_upgrade_value(new_data.name, "explosion_size_multiplier_1") == 1.3 then
				amount7 = " > Explosion Size: 3.9 Meter Radius\n"
			elseif new_data.name == "trip_mine" then
				amount7 = " > Explosion Size: 3 Meter Radius\n"
			else
				amount7 = amount7
			end
			if managers.player:equiptment_upgrade_value(new_data.name, "damage_multiplier") == 1.5 then
				amount7 = amount7 .. " > Explosion Damage: 1,500"
			elseif new_data.name == "trip_mine" then
				amount7 = amount7 .. " > Explosion Damage: 1,000\n"
			else
				amount7 = amount7
			end
			
	--managers.player:upgrade_level("trip_mine", "fire_trap")

			if managers.player:upgrade_level(new_data.name, "fire_trap") == 1 then
				amount7 = amount7 .. " > Fire Trap Duration: 10 seconds\n > Fire Trap Radius: 4.5 Meters\n"
			elseif managers.player:upgrade_level(new_data.name, "fire_trap") == 2 then
				amount7 = amount7 .. " > Fire Trap Duration: 20 seconds\n > Fire Trap Radius: 6.75 Meters\n"
			else
				amount7 = amount7
			end
	--		]]

			if managers.player:upgrade_level(new_data.name, "armor_multiplier") == 1 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "armor_multiplier") == 1 then
				amount7 = amount7 .. " > Sentry Gun Health: 1,000\n"
			elseif new_data.name == "sentry_gun" and managers.player:upgrade_level(new_data.name, "armor_multiplier") == 0 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "armor_multiplier") == 0 then
				amount7 = amount7 .. " > Sentry Gun Health: 400\n"
			else
				amount7 = amount7
			end		
			
			if managers.player:upgrade_level(new_data.name, "extra_ammo_multiplier") == 1 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "extra_ammo_multiplier") == 1 then
				amount7 = amount7 .. " > Sentry Gun Ammo: 150\n"
			elseif new_data.name == "sentry_gun" and managers.player:upgrade_level(new_data.name, "extra_ammo_multiplier") == 0 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "extra_ammo_multiplier") == 0 then
				amount7 = amount7 .. " > Sentry Gun Ammo: 100\n"
			else
				amount7 = amount7
			end		
			
			if managers.player:upgrade_level(new_data.name, "ap_bullets") == 1 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "ap_bullets") == 1 then
				amount7 = amount7 .. " > Sentry Gun Damage: 30 (AP Rounds: 75)\n"
			elseif new_data.name == "sentry_gun" and managers.player:upgrade_level(new_data.name, "ap_bullets") == 0 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "ap_bullets") == 0 then
				amount7 = amount7 .. " > Sentry Gun Damage: 30\n"
			else
				amount7 = amount7
			end	
			
			
				
			if managers.player:upgrade_level(new_data.name, "cost_reduction") == 1 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "cost_reduction") == 1 then
				amount7 = amount7 .. " > Sentry Gun Cost: 56%\n"
			elseif managers.player:upgrade_level(new_data.name, "cost_reduction") == 2 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "cost_reduction") == 2 then
				amount7 = amount7 .. " > Sentry Gun Cost: 48%\n"
			elseif new_data.name == "sentry_gun" and managers.player:upgrade_level(new_data.name, "cost_reduction") == 0 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "cost_reduction") == 0 then
				amount7 = amount7 .. " > Sentry Gun Cost: 64%\n"
			else
				amount7 = amount7
			end
				
			if managers.player:upgrade_level(new_data.name, "spread_multiplier") == 1 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "spread_multiplier") == 1 then
				amount7 = amount7 .. " > Sentry Gun Accuracy: 2.5 Degrees\n"
			elseif new_data.name == "sentry_gun" and managers.player:upgrade_level(new_data.name, "spread_multiplier") == 0 or new_data.name == "sentry_gun_silent" and managers.player:upgrade_level("sentry_gun", "spread_multiplier") == 0 then
				amount7 = amount7 .. " > Sentry Gun Accuracy: 5 Degrees\n"
			else
				amount7 = amount7
			end		
				
			if managers.player:has_category_upgrade(new_data.name, "shield") or new_data.name == "sentry_gun_silent" and managers.player:has_category_upgrade("sentry_gun", "shield") then
				amount7 = amount7 .. " > Protective Shield\n"
			else 
				amount7 = amount7
			end	
				
			if managers.player:has_category_upgrade(new_data.name, "ap_bullets") or new_data.name == "sentry_gun_silent" and managers.player:has_category_upgrade("sentry_gun", "ap_bullets") then
				amount7 = amount7 .. " > AP Rounds\n"
			else 
				amount7 = amount7
			end		
				
			if new_data.name == "ammo_bag" and managers.player:upgrade_level("player", "no_ammo_cost") == 1 then
				amount7 = amount7 .. " > Bulletstorm: 5 Seconds Max\n"
			elseif new_data.name == "ammo_bag" and managers.player:upgrade_level("player", "no_ammo_cost") == 2 then
				amount7 = amount7 .. " > Bulletstorm: 20 Seconds Max\n"
			elseif new_data.name == "ammo_bag" and managers.player:upgrade_level("player", "no_ammo_cost") == 0 then
				amount7 = amount7
			else
				amount7 = amount7
			end			
				
				
			if new_data.name == "doctor_bag" and managers.player:upgrade_level("first_aid_kit", "damage_reduction_upgrade") == 1 or managers.player:upgrade_level(new_data.name, "damage_reduction_upgrade") == 1 then
				amount7 = amount7 .. " > Quick Fix\n"
			else
				amount7 = amount7
			end		
				
			if managers.player:upgrade_level(new_data.name, "first_aid_kit_auto_recovery") == 1 then
				amount7 = amount7 .. " > Uppers\n"
			else
				amount7 = amount7
			end		
				
				
			amount6 = amount4 .. ") (" .. amount5 .. amount1 .. amount2 .. ")\n" .. amount7 .. " " 
			new_data.name_localized = managers.localization:text(tweak_data.blackmarket.deployables[new_data.name].name_id) .. "\n(x" .. tostring(amount) .. tostring(amount6)--amount4 ..") (" .. amount5 .. tostring(amount1) .. amount2 .. ")" .. "\n "
			
			new_data.category = "deployables"
			new_data.bitmap_texture = guis_catalog .. "textures/pd2/blackmarket/icons/deployables/" .. tostring(new_data.name)
			new_data.slot = i
			new_data.unlocked = table.contains(managers.player:availible_equipment(1), new_data.name)
			new_data.level = 0
			new_data.equipped = managers.blackmarket:equipped_deployable() == new_data.name
			local slot = 0
			local count = 1
			if second_deployable then
				count = 2
			end
			for i = 1, count do
				if managers.player:equipment_in_slot(i) == new_data.name then
					slot = i
					break
				end
			end
			new_data.slot = slot
			new_data.equipped = slot ~= 0
			if new_data.equipped and second_deployable and new_data.unlocked then
				if slot == 1 then
					new_data.equipped_text = "PRIMARY"
				end
				if slot == 2 then
					new_data.equipped_text = "SECONDARY"
				end
			end
			if not new_data.unlocked then
				new_data.equipped_text = ""
			end
			new_data.stream = false
			new_data.skill_based = new_data.level == 0
			new_data.skill_name = "bm_menu_skill_locked_" .. new_data.name
			new_data.lock_texture = self:get_lock_icon(new_data)
			if new_data.unlocked and not new_data.equipped and not second_deployable then
				table.insert(new_data, "lo_d_equip")
			end
			if new_data.unlocked and not new_data.equipped and second_deployable then
				table.insert(new_data, "lo_d_equip_primary")
			end
			if second_deployable and managers.blackmarket:equipped_deployable(1) and new_data.unlocked and not new_data.equipped then
				table.insert(new_data, "lo_d_equip_secondary")
			end
			if new_data.equipped then
				table.insert(new_data, "lo_d_unequip")
			end
			
			data[i] = new_data
			index = i
		end
		for i = 1, max_items do
			if not data[i] then
				new_data = {}
				new_data.name = "empty"
				new_data.name_localized = ""
				new_data.category = "deployables"
				new_data.slot = i
				new_data.unlocked = true
				new_data.equipped = false
				data[i] = new_data
			end
		end
	end

	function BlackMarketGui:populate_grenades(data)
		local new_data = {}
		local sort_data = managers.blackmarket:get_sorted_grenades()
		local max_items = math.ceil(#sort_data / (data.override_slots[1] or 3)) * (data.override_slots[1] or 3)
		for i = 1, max_items do
			data[i] = nil
		end
		local index = 0
		local guis_catalog, m_tweak_data, grenade_id
		for i, grenades_data in ipairs(sort_data) do
			grenade_id = grenades_data[1]
			m_tweak_data = tweak_data.blackmarket.projectiles[grenades_data[1]] or {}
			guis_catalog = "guis/"
			local bundle_folder = m_tweak_data.texture_bundle_folder
			if bundle_folder then
				guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
			end
			new_data = {}
			new_data.name = grenade_id
	--		log(new_data.name)
	--[[		
			local amount = 3
			if new_data.name == "wpn_prj_four" then 
				amount = 10
				elseif new_data.name == "wpn_prj_ace" then
				amount = 21
			end
	]]


			local amount = ""
			if new_data.name == "chico_injector" or tweak_data.projectiles[new_data.name] == nil or tweak_data.projectiles[new_data.name].range == 0 or tweak_data.projectiles[new_data.name].range == nil then
				amount = ""
			else
				amount = "\nRange: " ..tostring(tweak_data.projectiles[new_data.name].range)*.01 .. " Meters"
			end
			
			if new_data.name == "wpn_prj_four" then
				amount = amount .. "\n > Poisoned"
			elseif new_data.name == "molotov" then
				amount = amount .. "\n > Incendiary\n > Burn Duration: " .. tostring(tweak_data.projectiles[new_data.name].burn_duration)+5 .. " Seconds\n > DOT: Every " .. tostring(tweak_data.projectiles[new_data.name].burn_tick_period)*10 .. " Seconds"
			elseif new_data.name == "chico_injector" then
			amount = amount .. "\n > Health per Damage: 75%"
			else
				amount = amount
			end

			local name_mxdmg = ""
			if new_data.name == "chico_injector" then
				name_mxdmg = "\n Lasts: 6 seconds" .. "\n Cooldown: 30 seconds" .. "\n Each kill speeds up cooldown by 1 second"
			elseif tweak_data.projectiles[new_data.name] == nil then 
				name_mxdmg = ""
			else
				name_mxdmg = "\n Max Damage: " .. tostring(tweak_data.projectiles[new_data.name].damage)*10
			end

			new_data.name_localized = managers.localization:text(tweak_data.blackmarket.projectiles[new_data.name].name_id) .. " (x" .. tostring(tweak_data.blackmarket.projectiles[new_data.name].max_amount) .. ")" .. name_mxdmg .. amount .. "\n "
							
			new_data.category = "grenades"
			new_data.slot = i
			new_data.unlocked = grenades_data[2].unlocked
			new_data.equipped = grenades_data[2].equipped
			new_data.level = grenades_data[2].level
			new_data.stream = true
			new_data.global_value = tweak_data.lootdrop.global_values[m_tweak_data.dlc] and m_tweak_data.dlc or "normal"
			new_data.skill_based = grenades_data[2].skill_based
			new_data.skill_name = "bm_menu_skill_locked_" .. new_data.name
			new_data.equipped_text = not new_data.unlocked and new_data.equipped and " "
			if m_tweak_data and m_tweak_data.locks then
				local dlc = m_tweak_data.locks.dlc
				local achievement = m_tweak_data.locks.achievement
				local saved_job_value = m_tweak_data.locks.saved_job_value
				local level = m_tweak_data.locks.level
				new_data.dlc_based = true
				new_data.lock_texture = self:get_lock_icon(new_data, "guis/textures/pd2/lock_community")
				if achievement and managers.achievment:get_info(achievement) and not managers.achievment:get_info(achievement).awarded then
					new_data.dlc_locked = "menu_bm_achievement_locked_" .. tostring(achievement)
				elseif dlc and not managers.dlc:is_dlc_unlocked(dlc) then
					new_data.dlc_locked = tweak_data.lootdrop.global_values[dlc] and tweak_data.lootdrop.global_values[dlc].unlock_id or "bm_menu_dlc_locked"
				else
					new_data.dlc_locked = tweak_data.lootdrop.global_values[new_data.global_value].unlock_id or "bm_menu_dlc_locked"
				end
			else
				new_data.lock_texture = self:get_lock_icon(new_data)
				new_data.dlc_locked = tweak_data.lootdrop.global_values[new_data.global_value].unlock_id or "bm_menu_dlc_locked"
			end
			new_data.bitmap_texture = guis_catalog .. "textures/pd2/blackmarket/icons/grenades/" .. tostring(new_data.name)
			if managers.blackmarket:got_new_drop("normal", "grenades", grenade_id) then
				new_data.mini_icons = new_data.mini_icons or {}
				table.insert(new_data.mini_icons, {
					name = "new_drop",
					texture = "guis/textures/pd2/blackmarket/inv_newdrop",
					right = 0,
					top = 0,
					layer = 1,
					w = 16,
					h = 16,
					stream = false
				})
				new_data.new_drop_data = {
					"normal",
					"grenades",
					grenade_id
				}
			end
			local active = true
			if active then
				if new_data.unlocked and not new_data.equipped then
					table.insert(new_data, "lo_g_equip")
				end
				if new_data.unlocked and data.allow_preview and m_tweak_data.unit then
					table.insert(new_data, "lo_g_preview")
				end
			end
			data[i] = new_data
			index = i
		end
		for i = 1, max_items do
			if not data[i] then
				new_data = {}
				new_data.name = "empty"
				new_data.name_localized = ""
				new_data.category = "grenades"
				new_data.slot = i
				new_data.unlocked = true
				new_data.equipped = false
				data[i] = new_data
			end
		end
	end
end