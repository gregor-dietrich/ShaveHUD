if string.lower(RequiredScript) == "lib/managers/menumanager" then
	if ShaveHUD:getSetting({"Misc", "HIDDEN_DLC"}, true) then
		function MenuCallbackHandler:get_latest_dlc_locked()
			return false
		end
	end

	if ShaveHUD:getSetting({"Misc", "NO_FADE"}, true) then
		MenuComponentManager.play_transition = function() end
	end

	if ShaveHUD:getSetting({"Misc", "INSTANT_CUSTODY"}, true) then
		local this = {
			id = "shavehud_item_insta_custody_mod_id",
			desc = "shavehud_item_insta_custody_mod_desc",
			option_yes = "shavehud_dialog_insta_custody_mod_yes",
			option_no = "shavehud_dialog_insta_custody_mod_no",
			chat = "shavehud_chat_insta_custody_mod_msg",
			isPublic = function()
				if LuaNetworking:IsClient() then
					local p = tonumber(managers.network.matchmake.lobby_handler:get_lobby_data("permission"))
	
					return tweak_data.permissions[p] == "public"
				end
	
				return Global.game_settings.permission == "public"
			end,
			setPlayerIntoCustody = function(this)
				local self = managers.player
				local player = self:player_unit()
				local equipped_grenade = managers.blackmarket:equipped_grenade()
	
				if
					equipped_grenade and tweak_data.blackmarket.projectiles[equipped_grenade] and
						tweak_data.blackmarket.projectiles[equipped_grenade].ability
				then
					self:reset_ability_hud()
				end
	
				MenuCallbackHandler:debug_goto_custody()
				managers.mission:call_global_event("player_in_custody")
	
				if
					self._super_syndrome_count and self._super_syndrome_count > 0 and
						not self._action_mgr:is_running("stockholm_syndrome_trade")
				then
					local peer_id = managers.network:session():local_peer():id()
	
					self._action_mgr:add_action("stockholm_syndrome_trade", StockholmSyndromeTradeAction:new(player:position(), peer_id))
				end
	
				self._listener_holder:call(self._custody_state, player)
				managers.hud:remove_interact()
	
				Hooks:Call("Update_InstantCustody")
				if this.isPublic() and LuaNetworking:GetNumberOfPeers() > 0 then
					managers.chat:send_message(ChatManager.GAME, Steam:username(), managers.localization:text(this.chat))
				end
			end
		}
	
		Hooks:Add(
			"LocalizationManagerPostInit",
			"Localization_InstantCustody",
			function(self)
				self:add_localized_strings(
					{
						[this.id] = "Go into custody",
						[this.desc] = "Do you want to go into custody?",
						[this.chat] = '"Instant Custody" mod was used.',
						[this.option_yes] = "Yes",
						[this.option_no] = "No"
					}
				)
			end
		)
	
		Hooks:Add(
			"MenuManagerBuildCustomMenus",
			"Menu_InstantCustody",
			function(_, nodes)
				MenuCallbackHandler[this.id] = function()
					QuickMenu:new(
						managers.localization:text(this.id),
						managers.localization:text(this.desc),
						{
							{
								text = managers.localization:text(this.option_yes),
								callback = callback(this, this, "setPlayerIntoCustody")
							},
							{
								text = managers.localization:text(this.option_no),
								is_cancel_button = true
							}
						},
						true
					)
				end
	
				Hooks:Add(
					"GameSetupUpdate",
					"Update_InstantCustody",
					function()
						local menu = nodes.pause
	
						if menu then
							local item = menu:item(this.id)
	
							if Utils:IsInHeist() then
								if not item then
									item =
										menu:create_item(
										{
											type = "CoreMenuItem.Item"
										},
										{
											name = this.id,
											text_id = this.id,
											callback = this.id
										}
									)
	
									menu:insert_item(item, Global.game_settings.single_player and 3 or 2)
								end
	
								item:set_enabled(not Utils:IsInCustody())
							elseif item then
								menu:delete_item(this.id)
								menu = managers.menu:active_menu()
	
								if menu and menu.logic then
									menu.logic:refresh_node()
								end
							end
						end
					end
				)
			end
		)
	end

	Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenus_SIIL", function( menu_manager, nodes )
		if nodes.steam_inventory then
			nodes.steam_inventory:parameters().sync_state = "blackmarket"
		end
	
		MenuHelper:AddMenuItem( nodes.lobby, "steam_inventory", "menu_steam_inventory", "menu_steam_inventory_help", "inventory", "after" )
		MenuHelper:AddMenuItem( nodes.crime_spree_lobby, "steam_inventory", "menu_steam_inventory", "menu_steam_inventory_help", "inventory", "after" )
	end)

	Hooks:Add("MenuManagerBuildCustomMenus", "BuildCreateEmptyLobbyMenu", function(menu_manager, nodes)
		local mainmenu = nodes.main
		if mainmenu == nil then
			-- Not actually a critical error since this occurs when hosting / joining a game session
			-- log("[CreateEmptyLobby] Fatal Error: Failed to locate main menu, aborting")
			return
		end
		if mainmenu._items == nil then
			log("[CreateEmptyLobby] Fatal Error: Main menu node is empty, aborting")
			return
		end

		-- From Menu:AddButton() (mods/base/req/menus.lua)
		local data = {
			type = "CoreMenuItem.Item",
		}
		local params = {
			name = "create_empty_lobby_btn",
			text_id = "shavehud_create_empty_lobby_title",
			help_id = "shavehud_create_empty_lobby_desc",
			callback = "create_empty_lobby"
		}
		local new_item = mainmenu:create_item(data, params)
		-- mainmenu:add_item(new_item)
		-- From MenuNode:add_item() (core/lib/managers/menu/coremenunode)
		new_item.dirty_callback = callback(mainmenu, mainmenu, "item_dirty")
		if mainmenu.callback_handler then
			new_item:set_callback_handler(mainmenu.callback_handler)
		end

		-- Determine where the item should be inserted
		local position = 2
		for index, item in pairs(mainmenu._items) do
			if item:name() == "crimenet_offline" then
				position = index
				break
			end
		end
		table.insert(mainmenu._items, position, new_item)
		--mainmenu:set_default_item_name("create_empty_lobby_btn")
	end)

	function MenuCallbackHandler:create_empty_lobby()
		-- Default the lobby to friends-only to prevent random people from hogging up slots while the contract is decided
		-- upon / other settings are adjusted
		Global.game_settings.permission = "friends_only"
		Global.game_settings.auto_kick = false

		-- From Setup:load_start_menu()
		managers.job:deactivate_current_job()
		managers.gage_assignment:deactivate_assignments()
		Global.load_level = false
	--	Global.load_start_menu = true
	--	Global.load_start_menu_lobby = false
		Global.level_data.level = nil
		Global.level_data.mission = nil
		Global.level_data.world_setting = nil
		Global.level_data.level_class_name = nil
		Global.level_data.level_id = nil

		self:create_lobby()
	end

	function MenuCallbackHandler:get_latest_dlc_locked(...) return false end		--Hide DLC ad in the main menu

	local modify_controls_original = MenuOptionInitiator.modify_controls
	function MenuOptionInitiator:modify_controls(...)
		local new_node = modify_controls_original(self, ...)

		-- Give sensitivity sliders a step size of 1%.
		local item
		for i, name in ipairs({"camera_sensitivity", "camera_sensitivity_horizontal", "camera_sensitivity_vertical", "camera_zoom_sensitivity", "camera_zoom_sensitivity_horizontal", "camera_zoom_sensitivity_vertical"}) do
			item = new_node:item(name)
			if item then
				item:set_step((tweak_data.player.camera.MAX_SENSITIVITY - tweak_data.player.camera.MIN_SENSITIVITY) * 0.01)
			end
		end

		return new_node
	end

	function MenuCallbackHandler:save_lobby_settings(setting, value)
		--Save lobby settings
		if setting then
			if value == nil then
				value = Global.game_settings[setting]
			end
			ShaveHUD:setSetting({"LOBBY_SETTINGS", setting}, value)
		else
			local lobby_settings = ShaveHUD:getSetting({"LOBBY_SETTINGS"}, {})
			for id, value in pairs(lobby_settings) do
				if Global.game_settings[id] ~= nil then
					lobby_settings[id] = Global.game_settings[id]
				end
			end
			ShaveHUD:setSetting({"LOBBY_SETTINGS"}, lobby_settings)
		end
		ShaveHUD:Save()
	end

	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_lobby_job_plan" , "MenuCallbackHandlerPostSaveJobPlan_ShaveHUD" , function( self, ... )
		self:save_lobby_settings("job_plan")
	end)
	Hooks:PostHook( MenuCallbackHandler , "choice_kicking_option" , "MenuCallbackHandlerPostSaveKickOption_ShaveHUD" , function( self, ... )
		self:save_lobby_settings("kick_option")
	end)
	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_lobby_permission" , "MenuCallbackHandlerPostSavePermission_ShaveHUD" , function( self, ... )
		self:save_lobby_settings("permission")
	end)
	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_lobby_reputation_permission" , "MenuCallbackHandlerPostSaveReputationPermission_ShaveHUD" , function( self, ... )
		self:save_lobby_settings("reputation_permission")
	end)
	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_drop_in" , "MenuCallbackHandlerPostSaveDropInOption_ShaveHUD" , function( self, ... )
		self:save_lobby_settings("drop_in_option")
	end)
	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_team_ai" , "MenuCallbackHandlerPostSaveTeamAIOption_ShaveHUD" , function( self, ... )
		self:save_lobby_settings("team_ai")
		self:save_lobby_settings("team_ai_option")
	end)
	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_auto_kick" , "MenuCallbackHandlerPostSaveAutoKick_ShaveHUD" , function( self, ... )
		self:save_lobby_settings("auto_kick")
	end)
	Hooks:PostHook( MenuCallbackHandler , "change_contract_difficulty" , "MenuCallbackHandlerPostSaveDifficulty_ShaveHUD" , function( self, item, ... )
		self:save_lobby_settings("difficulty", tweak_data:index_to_difficulty(item:value()))
	end)

	Hooks:PostHook( MenuCallbackHandler , "choice_crimenet_one_down" , "MenuCallbackHandlerPostSaveOneDownMod_ShaveHUD" , function( self, item, ... )
		self:save_lobby_settings("one_down", item:value() == "on")
	end)

	Hooks:PostHook( MenuCallbackHandler , "update_matchmake_attributes" , "MenuCallbackHandlerPostUpdateMatchmakeAttributes_ShaveHUD" , function( self, item, ... )
		self:save_lobby_settings()
	end)

	local SHAVEHUD_LOBBY_SETTINGS_LOADED = false
	local MenuCrimeNetContractInitiator_modify_node_orig = MenuCrimeNetContractInitiator.modify_node
	function MenuCrimeNetContractInitiator:modify_node(original_node, data, ...)
		if not SHAVEHUD_LOBBY_SETTINGS_LOADED then
			local lobby_settings = ShaveHUD:getSetting({"LOBBY_SETTINGS"}, {})
			for id, value in pairs(lobby_settings) do
				if Global.game_settings[id] ~= nil then
					Global.game_settings[id] = value
				end
			end
			SHAVEHUD_LOBBY_SETTINGS_LOADED = true
		end

		if data.customize_contract then
			data.difficulty = ShaveHUD:getSetting({"LOBBY_SETTINGS", "difficulty"}, "normal")
			data.difficulty_id = tweak_data:difficulty_to_index(data.difficulty)
			data.one_down = ShaveHUD:getSetting({"LOBBY_SETTINGS", "one_down"}, false)
		end

		local results = { MenuCrimeNetContractInitiator_modify_node_orig(self, original_node, data, ...) }
		local node = table.remove(results, 1)
		
		if data.customize_contract then
			local diff_item = node:item("difficulty")
			if diff_item then
				diff_item:set_value(data.difficulty_id)
			end

			local od_item = node:item("toggle_one_down")
			if od_item then
				od_item:set_value(data.one_down and "on" or "off")
			end
		end
		
		return node, unpack(results or {})
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/newheistsgui" then
	if not ShaveHUD:getSetting({"Misc", "HIDDEN_UPDATES"}, true) then
		return
	end

	function NewHeistsGui:set_enabled(enabled)
		self._content_panel:set_visible(false)
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/blackmarketgui" then	
	-- Correct Armor Sorting
	if ShaveHUD:getSetting({"INVENTORY", "CORRECT_ARMOR_SORTING"}, true) then
		function BlackMarketGui:populate_armors(data)
			local new_data = {}
			local sort_data = {}
			for id, d in pairs(Global.blackmarket_manager.armors) do
				table.insert(sort_data, id)
			end
			local armor_level_data = {}
			for level, data in pairs(tweak_data.upgrades.level_tree) do
				if data.upgrades then
					for _, upgrade in ipairs(data.upgrades) do
						local def = tweak_data.upgrades.definitions[upgrade]
						if def.armor_id then
							armor_level_data[def.armor_id] = level
						end
					end
				end
			end
			table.sort(sort_data, function(x, y)
				local x_level = tonumber(string.sub(x, 7))
				local y_level = tonumber(string.sub(y, 7))
				return x_level < y_level
			end)
			local guis_catalog = "guis/"
			local index = 0
			for i, armor_id in ipairs(sort_data) do
				local name_id = tweak_data.blackmarket.armors[armor_id] and tweak_data.blackmarket.armors[armor_id].name_id or ""
				local bm_data = Global.blackmarket_manager.armors[armor_id]
				guis_catalog = "guis/"
				local bundle_folder = tweak_data.blackmarket.armors[armor_id] and tweak_data.blackmarket.armors[armor_id].texture_bundle_folder
				if bundle_folder then
					guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
				end
				index = index + 1
				new_data = {}
				new_data.name = armor_id
				new_data.name_localized = managers.localization:text(name_id)
				new_data.category = "armors"
				new_data.slot = index
				new_data.unlocked = bm_data.unlocked
				new_data.level = armor_level_data[armor_id] or 0
				new_data.skill_based = new_data.level == 0
				new_data.equipped = bm_data.equipped
				new_data.skill_name = new_data.level == 0 and "bm_menu_skill_locked_" .. new_data.name
				new_data.bitmap_texture = guis_catalog .. "textures/pd2/blackmarket/icons/armors/" .. new_data.name
				new_data.comparision_data = {}
				new_data.lock_texture = self:get_lock_icon(new_data)
				if i ~= 1 and managers.blackmarket:got_new_drop("normal", "armors", armor_id) then
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
						"armors",
						armor_id
					}
				end
				if new_data.unlocked and not new_data.equipped then
					table.insert(new_data, "a_equip")
				end
				if i ~= 1 then
					if (game_state_machine and game_state_machine:current_state_name()) ~= "ingame_waiting_for_players" then
						table.insert(new_data, "a_mod")
					end
				end
				data[index] = new_data
			end
			local max_armors = data.override_slots[1] * data.override_slots[2]
			for i = 1, max_armors do
				if not data[i] then
					new_data = {}
					new_data.name = "empty"
					new_data.name_localized = ""
					new_data.category = "armors"
					new_data.slot = i
					new_data.unlocked = true
					new_data.equipped = false
					data[i] = new_data
				end
			end
		end
	end
	--Always enable mod mini icons, put ghost icon behind silent weapon names
	local populate_weapon_category_new_original = BlackMarketGui.populate_weapon_category_new
	function BlackMarketGui:populate_weapon_category_new(data, ...)
		local value = populate_weapon_category_new_original(self, data, ...)
		local show_icons = not ShaveHUD:getSetting({"INVENTORY", "SHOW_WEAPON_MINI_ICONS"}, true)
		for id, w_data in ipairs(data) do
			if tweak_data.weapon[w_data.name] then	--Filter out locked or empty slots
				local categories = tweak_data.weapon[w_data.name].categories
				local is_saw = table.contains(categories, "saw")
				local has_silencer = table.contains(categories, "bow") or table.contains(categories, "crossbow")
				local has_explosive = false
				for id, i_data in pairs(w_data.mini_icons) do	--Needs to handle silent motor saw
					if i_data.alpha == 1 then		--Icon enabled
						if i_data.texture == "guis/textures/pd2/blackmarket/inv_mod_silencer" then
							has_silencer = true
						elseif i_data.texture == "guis/textures/pd2/blackmarket/inv_mod_ammo_explosive" then
							has_explosive = true
						end
					end
				end
				local silent = has_silencer and not has_explosive
				w_data.name_localized = tostring(w_data.name_localized) .. (not is_saw and (" " .. (silent and utf8.char(57363) or "")) or "")
				w_data.hide_unselected_mini_icons = show_icons
			end
		end
		return value
	end

	-- Remove free Buckshot ammo, if you own Gage Shotty DLC
	local populate_mods_original = BlackMarketGui.populate_mods
	function BlackMarketGui:populate_mods(data, ...)
		if managers.dlc:has_dlc("gage_pack_shotgun") then
			for index, mod_t in ipairs(data.on_create_data or {}) do
				if mod_t[1] == "wpn_fps_upg_a_custom_free"  then
					table.remove(data.on_create_data, index)
					break
				end
			end
		end

		return populate_mods_original(self, data, ...)
	end

	
	local function getEquipmentAmount(name_id)
		local data = tweak_data.equipments[name_id]
		if data and data.quantity then
			if type(data.quantity) == "table" then
				local amounts = data.quantity
				local amount_str = ""
				for i = 1, #amounts do
					local equipment_name = name_id
					if data.upgrade_name then
						equipment_name = data.upgrade_name[i]
					end
					amount_str = amount_str .. (i > 1 and "/x" or "x") .. tostring((amounts[i] or 0) + managers.player:equiptment_upgrade_value(equipment_name, "quantity"))
				end
				return " (" .. amount_str .. ")"
			else
				return " (x" .. tostring(data.quantity) .. ")"
			end
		end
		return ""
	end

	local populate_deployables_original = BlackMarketGui.populate_deployables
	function BlackMarketGui:populate_deployables(data, ...)
		populate_deployables_original(self, data, ...)
		if ShaveHUD:getSetting({"INVENTORY", "INVENTORY_COUNT"}, true) then
			for i, equipment in ipairs(data) do
				equipment.name_localized = equipment.name_localized .. (equipment.unlocked and getEquipmentAmount(equipment.name) or "")
			end
		end
	end

	local populate_grenades_original = BlackMarketGui.populate_grenades
	function BlackMarketGui:populate_grenades(data, ...)
		populate_grenades_original(self, data, ...)
		if ShaveHUD:getSetting({"INVENTORY", "INVENTORY_COUNT"}, true) then
			local t_data = tweak_data.blackmarket.projectiles
			for i, throwable in ipairs(data) do
				local has_amount = throwable.unlocked and t_data[throwable.name] or false
				throwable.name_localized = throwable.name_localized .. (has_amount and " (x" .. t_data[throwable.name].max_amount .. ")" or "")
			end
		end
	end

	-- Show all Names in Inventory Boxxes
	local orig_blackmarket_gui_slot_item_init = BlackMarketGuiSlotItem.init
	function BlackMarketGuiSlotItem:init(main_panel, data, ...)
		if ShaveHUD:getSetting({"INVENTORY", "SHOW_WEAPON_NAMES"}, true) then
			data.custom_name_text = data.custom_name_text or not data.empty_slot and data.name_localized
		end
		return orig_blackmarket_gui_slot_item_init(self, main_panel, data, ...)
	end

	local orig_blackmarket_gui_slot_item_select = BlackMarketGuiItem.select
	function BlackMarketGuiItem:select(instant, ...)
		self._is_selected = true
		self:set_highlight(true, instant)

		return orig_blackmarket_gui_slot_item_select(self, instant, ...)
	end

	local orig_blackmarket_gui_slot_item_deselect = BlackMarketGuiItem.deselect
	function BlackMarketGuiItem:deselect(instant, ...)
		self._is_selected = false
		self:set_highlight(false, instant)

		return orig_blackmarket_gui_slot_item_deselect(self, instant, ...)
	end

	local orig_blackmarket_gui_slot_item_set_highlight = BlackMarketGuiSlotItem.set_highlight
	function BlackMarketGuiSlotItem:set_highlight(highlight, ...)
		if highlight or self._is_selected or self._data.equipped then
			local name_text = self._panel:child("custom_name_text")
			if name_text then
				name_text:set_alpha(1)
			end
			if self._mini_panel then
				self._mini_panel:set_alpha(1)
			end
		else
			local name_text = self._panel:child("custom_name_text")
			if name_text then
				name_text:set_alpha(0.5)
			end
			if self._mini_panel then
				self._mini_panel:set_alpha(0.4)
			end
		end

		return orig_blackmarket_gui_slot_item_set_highlight(self, highlight, ...)
	end

	local orig_blackmarket_gui_set_selected_tab = BlackMarketGui.set_selected_tab
	function BlackMarketGui:set_selected_tab(...)
		local value = orig_blackmarket_gui_set_selected_tab(self, ...)

		local current_tab = self._tabs[self._selected]
		local selected_slot = current_tab and current_tab._slots[current_tab._slot_selected]
		local highlighted_slot 	= current_tab and current_tab._slots[current_tab._slot_highlighted]

		if selected_slot then
			selected_slot:select(true, true)
			if highlighted_slot and selected_slot ~= highlighted_slot then
				selected_slot:set_highlight(false, true)
				highlighted_slot:set_highlight(true, false)
			end
		end

		return value
	end

	--Replace Tab Names with custom ones...
	BlackMarketGui._SUB_TABLE = {
		["<SKULL>"] = utf8.char(57364),	--Skull icon
		["<GHOST>"] = utf8.char(57363),	--Ghost icon
	}

	local BlackMarketGui__setup_original = BlackMarketGui._setup
	function BlackMarketGui:_setup(is_start_page, component_data)
		self._renameable_tabs = false
		component_data = component_data or self:_start_page_data()
		local inv_name_tweak = ShaveHUD:getSetting({"INVENTORY", "CUSTOM_TAB_NAMES"}, {})
		if inv_name_tweak then
			for i, tab_data in ipairs(component_data) do
				if not tab_data.prev_node_data then
					local category_tab_names = inv_name_tweak[tab_data.category]
					local custom_tab_name = category_tab_names and category_tab_names[i] or ""
					for key, subst in pairs(BlackMarketGui._SUB_TABLE) do
						custom_tab_name = custom_tab_name:upper():gsub(key, subst)
					end
					if string.len(custom_tab_name or "") > 0 then
						tab_data.name_localized = custom_tab_name or tab_data.name_localized
					end
					self._renameable_tabs = self._renameable_tabs or category_tab_names and true or false
				end
			end
		end

		BlackMarketGui__setup_original(self, is_start_page, component_data)

		if self._renameable_tabs and self._tabs[1] then
			local first_tab_name = self._tabs[1]._tab_panel and self._tabs[1]._tab_panel:child("tab_text")
			self._renameable_tabs = first_tab_name:visible()
		end

		if self._renameable_tabs and not component_data.is_loadout  and alive(self._panel) then
			-- create rename tab info text
			local legends_panel = self._panel:panel({
				name = "LegendsPanel",
				w = self._panel:w() * 0.75,
				h = tweak_data.menu.pd2_medium_font_size
			})
			legends_panel:set_righttop(self._panel:w(), 0)
			legends_panel:text({
				name = "LegendText",
				text = managers.localization:text("shavehud_inv_tab_rename_hint"),
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				color = tweak_data.screen_colors.text,
				alpha = 0.8,
				blend_mode = "add",
				align = "right",
				vertical = "top"
			})
		end
	end

	-- Input Dialog on double click selected tab
	local BlackMarketGui_mouse_clicked_original = BlackMarketGui.mouse_clicked
	function BlackMarketGui:mouse_clicked(...)
		BlackMarketGui_mouse_clicked_original(self, ...)

		if not self._enabled or alive(self._context_panel) then
			return
		end

		self._mouse_click = self._mouse_click or {}
		self._mouse_click[self._mouse_click_index].selected_tab = self._selected
	end

	local BlackMarketGui_mouse_double_click_original = BlackMarketGui.mouse_double_click
	function BlackMarketGui:mouse_double_click(o, button, x, y)
		if self._enabled and not self._data.is_loadout and self._renameable_tabs then
			if self._mouse_click and self._mouse_click[0] and self._mouse_click[1] then
				if self._tabs and self._mouse_click[0].selected_tab == self._mouse_click[1].selected_tab then
					local current_tab = self._tabs[self._selected]
					if current_tab and button == Idstring("0") then
						if self._tab_scroll_panel:inside(x, y) and current_tab:inside(x, y) ~= 1 then
							self:rename_tab_clbk(current_tab, self._selected)
							return
						end
					end
				end
			end
		end

		BlackMarketGui_mouse_double_click_original(self, o, button, x, y)
	end

	function BlackMarketGui:rename_tab_clbk(tab, tab_id)
		local current_tab = tab or self._tabs[self._selected]
		local tab_data = self._data[self._selected]
		local inv_name_tweak = ShaveHUD:getSetting({"INVENTORY", "CUSTOM_TAB_NAMES"}, nil)
		if current_tab and tab_data and inv_name_tweak and not self:in_setup()then
			local prev_name = inv_name_tweak[tab_data.category] and inv_name_tweak[tab_data.category][tab_id or self._selected] or current_tab._tab_text_string
			local menu_options = {
				[1] = {
					text = managers.localization:text("shavehud_dialog_save"),
					callback = function(cb_data, button_id, button, text)
						if self._data and text and text ~= "" then
							if tab_data and inv_name_tweak then
								inv_name_tweak[tab_data.category] = inv_name_tweak[tab_data.category] or {}
								inv_name_tweak[tab_data.category][tab_id or self._selected] = text
								ShaveHUD:Save()

								for key, subst in pairs(BlackMarketGui._SUB_TABLE) do
									text = text:upper():gsub(key, subst)
								end

								current_tab._tab_text_string = text
								local name = current_tab._tab_panel:child("tab_text")
								if alive(name) then
									name:set_text(text)
								end
								self:rearrange_tab_width(true)
								self:_round_everything()
							end
						end
					end,
				},
				[2] = {
					text = managers.localization:text("dialog_cancel"),
					is_cancel_button = true,
				}
			}
			QuickInputMenu:new(managers.localization:text("shavehud_dialog_rename_inv_tab"), managers.localization:text("shavehud_dialog_rename_inv_tab_desc"), prev_name, menu_options, true, {w = 420, to_upper = true, max_len = 15})

			return
		end
	end

	function BlackMarketGui:rearrange_tab_width(start_with_selected)
		local current = start_with_selected and self._selected or 1
		local start = current + 1
		local stop = #self._tabs

		local current_tab = self._tabs[current]
		if current_tab then
			local current_panel = current_tab._tab_panel
			local current_text = current_panel and current_panel:child("tab_text")
			local current_selection = current_panel and current_panel:child("tab_select_rect")
			if alive(current_panel) and alive(current_text) and alive(current_selection) then
				local _, _, w, _ = current_text:text_rect()
				current_panel:set_w(w + 15)
				current_selection:set_w(w + 15)
				current_text:set_w(w + 15)
				current_text:set_center_x(current_panel:w() / 2)
			end
		end

		local offset = alive(self._tabs[current]._tab_panel) and self._tabs[current]._tab_panel:right() or 0
		for i = start, stop do
			local tab = self._tabs[i]
			local tab_panel = tab._tab_panel
			if alive(tab._tab_panel) then
				offset = tab:set_tab_position(offset)
			end

		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/menucomponentmanager" then
	if not ShaveHUD:getSetting({"Misc", "MOD_LIST_LITE"}, true) then
		return
	end
	
	local BLTUIButton_init = BLTUIButton.init
	local BLTModItem_init = BLTModItem.init
	local BLTDownloadControl_init = BLTDownloadControl.init
	local BLTModsGui_setup = BLTModsGui._setup

	local box_height = 128
	local icon_size = 32
	local padding = 10

	function BLTMod:HasModImage()
		-- suppress image loading
		return false
	end

	function BLTUIButton:init(panel, parameters, ...)

		local found

		-- identify download manager button
		if parameters and parameters.text and parameters.text == managers.localization:text("blt_download_manager_help") then
			found = true
			-- fix height param
			parameters.h = box_height
			-- delete image param
			parameters.image = nil
		end

		-- let the button be generated
		local result = BLTUIButton_init(self, panel, parameters, ...)

		if found then
			-- fix text positioning
			local title = self._panel:child("title")
			local desc = self._panel:child("desc")
			if title and desc then

				-- center y
				local full_height = title:h() + desc:h() + 5
				title:set_top((self._panel:h() - full_height) * 0.5)
				desc:set_top(title:bottom() + 5)

			end
		end

		return result
	end

	function BLTModItem:init(panel, index, ...)

		-- let the item be generated
		local result = BLTModItem_init(self, panel, index, ...)

		-- fix box positioning
		local w = (panel:w() - (self.layout.x + 1) * padding) / self.layout.x
		local column, row = self:_get_col_row(index)
		self._panel:set_x((w + padding) * (column - 1))
		self._panel:set_y((box_height + padding) * (row - 1))

		-- fix box height
		self._panel:set_height(box_height)

		-- scan for child panels and remove them. these are:
		-- 1. the "no image" box and
		-- 2. the 4 white corners - their alignments are set to "grow", so they got stretched by the box resizing
		-- also check if there are icons
		local icons = 0
		for _, child in pairs(self._panel:children()) do
			if alive(child) then
				if child.type_name == "Panel" then
					self._panel:remove(child)
				elseif child.type_name == "Bitmap" and child.texture ~= "guis/textures/test_blur_df" then -- ignore the background
					icons = icons + 1
				end
			end
		end

		-- recreate the white corners with correct size
		BoxGuiObject:new(self._panel, {sides = {1, 1, 1, 1}})

		-- remove description panel
		local mod_desc = self._panel:child("mod_desc")
		if mod_desc then
			self._panel:remove(mod_desc)
		end

		-- fix text positions / sizes
		local mod_name = self._panel:child("mod_name")
		if mod_name then

			-- fix width (prevent overlapping with icons)
			if icons > 1 then
				mod_name:set_w(self._panel:w() - padding * 4 - icon_size * 2)
			end

			-- fix height
			mod_name:set_h(self._panel:h() - padding * 2)

			-- center text
			mod_name:set_vertical("center")

			-- center
			mod_name:set_center_x(self._panel:w() * 0.5)
			mod_name:set_center_y(self._panel:h() * 0.5)

		end

		return result
	end

	function BLTDownloadControl:init(...)

		-- let the control be generated
		local result = BLTDownloadControl_init(self, ...)

		-- scan for the "no image" panel and remove it
		for _, child in pairs(self._info_panel:children()) do
			if alive(child) and child.type_name == "Panel" then
				self._info_panel:remove(child)
			end
		end

		-- fix download info position & size
		local title = self._info_panel:child("title")
		local state = self._info_panel:child("state") or self._panel:child("state") -- temporary blt bug fix for this: https://github.com/JamesWilko/Payday-2-BLT-Lua/commit/fa575be5bc13a8caa57a86a557d85819ab082800
		local download_progress = self._info_panel:child("download_progress")
		for _, obj in pairs({title, state, download_progress}) do
			if alive(obj) then
				obj:set_x(padding * 2)
				obj:set_w(self._info_panel:w() - padding * 3)
			end
		end

		return result
	end

	function BLTModsGui:_setup(...)

		-- Get mod list
		local mods = BLT.Mods:Mods()

		-- Take BLT base mod out of the list
		local blt_mod
		for key, mod in pairs(mods) do
			if mod:GetId() == "base" then
				blt_mod = table.remove(mods, key)
				break
			end
		end

		-- Sort mod list
		table.sort(mods, function(a, b)
			return a:GetName():lower() < b:GetName():lower()
		end)

		-- Recreate mod list
		local sorted_mods = {}
		table.insert(sorted_mods, blt_mod)
		for _, mod in pairs(mods) do
			table.insert(sorted_mods, mod)
		end

		-- Replace mod list
		BLT.Mods.mods = sorted_mods

		return BLTModsGui_setup(self, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/menuscenemanager" then
	if ShaveHUD:getSetting({"Misc", "BADASS_CAMERA"}, true) then
		local blacklistedtemplates = {
			blackmarket_crafting = true,
			blackmarket_armor = true
		}
		
		local set_scene_template_actual = MenuSceneManager.set_scene_template
		function MenuSceneManager:set_scene_template(template, data, custom_name, skip_transition, ...)
			if not skip_transition and (self._current_scene_template == template or self._current_scene_template == custom_name) then
				return
			end
		
			local should_animate = true
			if blacklistedtemplates[template] or blacklistedtemplates[self._current_scene_template] then
				-- Don't zoom through the entire universe. Thanks, but no thanks
				should_animate = false
			end
		
			set_scene_template_actual(self, template, data, custom_name, skip_transition, ...)
		
			if should_animate then
				self._transition_time = 0
			end
		end
	end
	if ShaveHUD:getSetting({"CrewLoadout", "SKIN_HIDER"}, true) then
		function MenuSceneManager:_get_lobby_character_prio_item(rank, outfit)
			local infamous = rank and rank > 0
			local primary_rarity, secondary_rarity
			if outfit.primary.cosmetics and outfit.primary.cosmetics.id and outfit.primary.cosmetics.id ~= "nil" then
				local rarity = tweak_data.blackmarket.weapon_skins[outfit.primary.cosmetics.id] and tweak_data.blackmarket.weapon_skins[outfit.primary.cosmetics.id].rarity
				primary_rarity = tweak_data.economy.rarities[rarity].index
			end
			if outfit.secondary.cosmetics and outfit.secondary.cosmetics.id and outfit.secondary.cosmetics.id ~= "nil" then
				local rarity = tweak_data.blackmarket.weapon_skins[outfit.secondary.cosmetics.id] and tweak_data.blackmarket.weapon_skins[outfit.secondary.cosmetics.id].rarity
				secondary_rarity = tweak_data.economy.rarities[rarity].index
			end
			if primary_rarity and secondary_rarity then
				return infamous and "rank" or primary_rarity >= secondary_rarity and "primary" or "secondary"
			elseif primary_rarity then
				return infamous and "rank" or "primary"
			elseif secondary_rarity then
				return infamous and "rank" or "secondary"
			end
			--if not primary_rarity and not secondary_rarity then
			--	return "primary"
			--end
			return infamous and "rank" or "primary"
		end
	end
	if ShaveHUD:getSetting({"INVENTORY", "NO_WEAPON_ROTATION"}, true) then
		Hooks:PostHook( MenuSceneManager, "set_scene_template", "iamtryingtolookatmygungoddammit", function(self, ...)
			managers.menu_scene._disable_rotate = true -- >:(
		end)
	end
	if ShaveHUD:getSetting({"INVENTORY", "MASK_IN_OUTFIT_SCREEN"}, true) then
		Hooks:PostHook(MenuSceneManager, "_set_up_templates", "unhide_mask_umu", function(self)
			self._scene_templates.blackmarket_armor.hide_mask = false
		end)
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/skilltreeguinew" then
	local orig_newskilltreeskillitem_refresh = NewSkillTreeSkillItem.refresh
	function NewSkillTreeSkillItem:refresh(...)
		local value = orig_newskilltreeskillitem_refresh(self, ...)

		--Always show Skill names
		if alive(self._skill_panel) and ShaveHUD:getSetting({"INVENTORY", "SHOW_SKILL_NAMES"}, true) then
			local skill_name = self._skill_panel:child("SkillName")
			if skill_name then
				local unlocked = self._skill_id and self._tree and managers.skilltree and managers.skilltree:skill_unlocked(self._tree, self._skill_id) or false
				local step = (self._skilltree:next_skill_step(self._skill_id) or 0)
				local skilled = unlocked and step > 0
				skill_name:set_visible(true)
				skill_name:set_alpha(self._selected and 1 or skilled and 0.6 or 0.4)
			end
		end

		return value
	end

	--Fix mouse pointer for locked skills
	local orig_newskilltreeskillitem_is_active = NewSkillTreeSkillItem.is_active
	function NewSkillTreeSkillItem:is_active(...)
		local unlocked = self._skill_id and self._tree and managers.skilltree and managers.skilltree:skill_unlocked(self._tree, self._skill_id) or false
		return orig_newskilltreeskillitem_is_active(self, ...) or not unlocked
	end

	--Resize and move total points label
	local orig_newskilltreetieritem_init = NewSkillTreeTierItem.init
	local orig_newskilltreetieritem_refresh_points = NewSkillTreeTierItem.refresh_points
	local orig_newskilltreetieritem_refresh_tier_text = NewSkillTreeTierItem._refresh_tier_text
	function NewSkillTreeTierItem:init(...)
		local val = orig_newskilltreetieritem_init(self, ...)
		if ShaveHUD:getSetting({"INVENTORY", "SHOW_SKILL_NAMES"}, true) then
			if self._tier_points_total and self._tier_points_total_zero and self._tier_points_total_curr then
				local font_size = tweak_data.menu.pd2_small_font_size * 0.75
				self._tier_points_total:set_font_size(font_size)
				local _, _, w, h = self._tier_points_total:text_rect()
				self._tier_points_total:set_size(w, h)
				self._tier_points_total_zero:set_font_size(font_size)
				self._tier_points_total_curr:set_font_size(font_size)
				self._tier_points_total:set_alpha(0.9)
				self._tier_points_total_curr:set_alpha(0.9)
				self._tier_points_total_zero:set_alpha(0.6)
			end
		end
		return val
	end
	function NewSkillTreeTierItem:refresh_points(selected, ...)
		orig_newskilltreetieritem_refresh_points(self, selected, ...)
		if ShaveHUD:getSetting({"INVENTORY", "SHOW_SKILL_NAMES"}, true) then
			if alive(self._tier_points_total) and alive(self._tier_points_total_zero) and alive(self._tier_points_total_curr) then
				self._tier_points_total:set_y(self._text_space or 10)
				self._tier_points_total_zero:set_y(self._text_space or 10)
				self._tier_points_total_curr:set_y(self._text_space or 10)
			end
			if alive(self._tier_points_0) and alive(self._tier_points) then
				self._tier_points:set_visible(not self._tier_points_needed:visible())
				self._tier_points_0:set_visible(not self._tier_points_needed:visible())
			end
		end
	end
	function NewSkillTreeTierItem:_refresh_tier_text(selected, ...)
		orig_newskilltreetieritem_refresh_tier_text(self, selected, ...)
		if ShaveHUD:getSetting({"INVENTORY", "SHOW_SKILL_NAMES"}, true) then
			if selected and alive(self._tier_points_needed) and alive(self._tier_points_needed_curr) and alive(self._tier_points_needed_zero) then
				self._tier_points_needed_zero:set_left(self._tier_points_0:left())
				self._tier_points_needed_curr:set_left(self._tier_points_needed_zero:right())
				self._tier_points_needed:set_left(self._tier_points_needed_curr:right() + self._text_space)
			end
			if alive(self._tier_points_0) and alive(self._tier_points) then
				self._tier_points:set_visible(not self._tier_points_needed:visible())
				self._tier_points_0:set_visible(not self._tier_points_needed:visible())
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/tweakdata" then
	if tweak_data then
		-- Give Sound sliders a step size of 1%.
		tweak_data.menu = tweak_data.menu or {}
		tweak_data.menu.MUSIC_CHANGE = 1
		tweak_data.menu.SFX_CHANGE = 1
		tweak_data.menu.VOICE_CHANGE = 0.01

		if Network:is_server() and ShaveHUD:getSetting({"SkipIt", "INSTANT_RESTART"}, false) then
			tweak_data.vote = tweak_data.vote or {}
			tweak_data.voting.restart_delay = 0
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/guitweakdata" then
	local GuiTweakData_init_orig = GuiTweakData.init
	function GuiTweakData:init(...)
		GuiTweakData_init_orig(self, ...)
		self.rename_max_letters = ShaveHUD:getTweakEntry("MAX_WEAPON_NAME_LENGTH", "number", 30)
		self.rename_skill_set_max_letters = ShaveHUD:getTweakEntry("MAX_SKILLSET_NAME_LENGTH", "number", 25)

		if false then
			table.insert(self.crime_net.special_contracts, {
				id = "random_contract",
				name_id = "menu_cn_random_contract",
				desc_id = "menu_cn_random_contract_desc",
				menu_node = nil,
				x = 550,
				y = 640,
				icon = "guis/textures/pd2/crimenet_challenge"
			})
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/crimenetmanager" then
	local check_job_pressed = CrimeNetGui.check_job_pressed
	function CrimeNetGui:check_job_pressed(...)
		if self._jobs["random_contract"] and self._jobs["random_contract"].mouse_over == 1 then
			local job_id = tweak_data.narrative._jobs_index[math.random(#tweak_data.narrative._jobs_index)]
			local job_tweak = tweak_data.narrative:job_data(job_id)
			local data = {
				job_id = job_id,
				difficulty = "normal",
				difficulty_id = 2,
				professional = job_tweak.professional or false,
				competitive = job_tweak.competitive or false,
				customize_contract = true,
				contract_visuals = job_tweak.contract_visuals,
				server = false,
				special_node = Global.game_settings.single_player and "crimenet_contract_singleplayer" or "crimenet_contract_host",
			}
			for k, v in pairs(data) do
				self._jobs["random_contract"][k] = v
			end
		end

		return check_job_pressed(self, ...)
	end

	local _get_job_location_orig = CrimeNetGui._get_job_location
	function CrimeNetGui:_get_job_location(data, ...)
		-- Assign job pos per difficulty?
		return _get_job_location_orig(self, data, ...)
	end
elseif string.lower(RequiredScript) == "core/lib/managers/controller/corecontrollerwrapperpc" then
	core:module("CoreControllerWrapperPC")
	core:import("CoreControllerWrapper")

	-- Ergh, I have to put this here as dofile() does not work properly for this file
	local function table_pack(...)
		return {n = select("#", ...), ...}
	end

	local virtual_connect_confirm_actual = ControllerWrapperPC.virtual_connect_confirm
	function ControllerWrapperPC:virtual_connect_confirm(...)
		virtual_connect_confirm_actual(self, ...)

		local args = table_pack(...)
		args[3] = "num enter"
		self:virtual_connect2(unpack(args))
	end
elseif string.lower(RequiredScript) == "core/lib/managers/menu/items/coremenuitemslider" then
	core:module("CoreMenuItemSlider")
	--core:import("CoreMenuItem")
	local init_actual = ItemSlider.init
	local highlight_row_item_actual = ItemSlider.highlight_row_item
	local set_value_original = ItemSlider.set_value
	local set_enabled_original = ItemSlider.set_enabled
	local reload_original = ItemSlider.reload
	function ItemSlider:init(...)
		init_actual(self, ...)
		self._show_slider_text = true
	end

	function ItemSlider:highlight_row_item(node, row_item, mouse_over, ...)
		local val = highlight_row_item_actual(self, node, row_item, mose_over, ...)
		row_item.gui_slider_gfx:set_gradient_points({
			0, self:slider_highlighted_color():with_alpha(0.6),
			1, self:slider_highlighted_color():with_alpha(0.6)
		})
		return val
	end

	function ItemSlider:set_value(value, ...)
		local times = math.round((value - self._min) / self._step)
		value = self._min + self._step * times

		set_value_original(self, value, ...)
	end

	function ItemSlider:set_enabled(...)
		set_enabled_original(self, ...)
		if self._enabled then
			self:set_slider_color(_G.tweak_data.screen_colors.button_stage_3)
			self:set_slider_highlighted_color(_G.tweak_data.screen_colors.button_stage_2)
		else
			self:set_slider_color(Color(0.4, 0.4, 0.4, 0.4))
			self:set_slider_highlighted_color(Color(0.2, 0.4, 0.4, 0.4))
		end
	end

	function ItemSlider:reload(row_item, ...)
		local val = reload_original(self, row_item, ...)

		if row_item and row_item.color then
			row_item.gui_text:set_color(row_item.color)
			row_item.gui_slider_text:set_color(row_item.color)
		end

		return val
	end
elseif string.lower(RequiredScript) == "lib/states/ingamewaitingforplayers" then
	local SKIP_BLACKSCREEN = ShaveHUD:getSetting({"SkipIt", "SKIP_BLACKSCREEN"}, true)
	local update_original = IngameWaitingForPlayersState.update
	function IngameWaitingForPlayersState:update(...)
		update_original(self, ...)

		if self._skip_promt_shown and SKIP_BLACKSCREEN then
			self:_skip()
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/stageendscreengui" then
	local init_original = StageEndScreenGui.init
	local update_original = StageEndScreenGui.update
	local special_btn_pressed_original = StageEndScreenGui.special_btn_pressed
	local special_btn_released_original = StageEndScreenGui.special_btn_released

	function StageEndScreenGui:init(...)
		init_original(self, ...)

		if self._enabled and ShaveHUD:getSetting({"SkipIt", "STAT_SCREEN_SPEEDUP"}, true) and managers.hud then
			managers.hud:set_speed_up_endscreen_hud(5)
		end
	end

	local SKIP_STAT_SCREEN_DELAY = ShaveHUD:getSetting({"SkipIt", "STAT_SCREEN_DELAY"}, 0)
	function StageEndScreenGui:update(t, ...)
		update_original(self, t, ...)
		if not self._button_not_clickable then
			self._auto_continue_t = self._auto_continue_t or (t + SKIP_STAT_SCREEN_DELAY)
			local gsm = game_state_machine:current_state()
			if gsm and gsm._continue_cb and not (gsm._continue_blocked and gsm:_continue_blocked()) and t >= self._auto_continue_t then
				managers.menu_component:post_event("menu_enter")
				gsm._continue_cb()
			end
		end
	end

	function StageEndScreenGui:special_btn_pressed(...)
		if not ShaveHUD:getSetting({"SkipIt", "STAT_SCREEN_SPEEDUP"}, true) then
			special_btn_pressed_original(self, ...)
		end
	end

	function StageEndScreenGui:special_btn_released(...)
		if not ShaveHUD:getSetting({"SkipIt", "STAT_SCREEN_SPEEDUP"}, true) then
			special_btn_released_original(self, ...)
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/lootdropscreengui" then
	local SKIP_LOOT_SCREEN_DELAY = ShaveHUD:getSetting({"SkipIt", "LOOT_SCREEN_DELAY"}, 3)
	local AUTO_PICK_CARD = ShaveHUD:getSetting({"SkipIt", "AUTOPICK_CARD"}, true)
	local AUTO_PICK_SPECIFIC_CARD = ShaveHUD:getSetting({"SkipIt", "AUTOPICK_CARD_SPECIFIC"}, 1)
	local update_original = LootDropScreenGui.update
	function LootDropScreenGui:update(t, ...)
		update_original(self, t, ...)

		if not self._card_chosen and AUTO_PICK_CARD then
			local autopicked_card = AUTO_PICK_SPECIFIC_CARD
			if autopicked_card == 4 then
				autopicked_card = math.random(3)
			end
			self:_set_selected_and_sync(autopicked_card)
			self:confirm_pressed()
		end

		if not self._button_not_clickable and SKIP_LOOT_SCREEN_DELAY > 0 then
			self._auto_continue_t = self._auto_continue_t or (t + SKIP_LOOT_SCREEN_DELAY)
			local gsm = game_state_machine:current_state()
			if gsm and not (gsm._continue_blocked and gsm:_continue_blocked()) and t >= self._auto_continue_t then
				self:continue_to_lobby()
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/contractboxgui" then
	local create_character_text_original = ContractBoxGui.create_character_text

	function ContractBoxGui:create_character_text(peer_id, ...)
		create_character_text_original(self, peer_id, ...)

		if managers.network:session() then
			if managers.network:session():local_peer():id() ~= peer_id then
				local peer_label = self._peers[peer_id]
				if alive(peer_label) then
					local peer = managers.network:session():peer(peer_id)
					local latency = peer and Network:qos(peer:rpc()).ping or 0
					local x, y = peer_label:center_x(), peer_label:top()
					local LPI_offset = LobbyPlayerInfo and (LobbyPlayerInfo.settings.show_play_time_mode or 0) > 1 and LobbyPlayerInfo:GetFontSizeForPlayTime() or 0

					self._peer_latency = self._peer_latency or {}
					self._peer_latency[peer_id] = self._peer_latency[peer_id] or self._panel:text({
						name = tostring(peer_id) .. "_latency",
						text = "",
						align = "center",
						vertical = "center",
						font = tweak_data.menu.pd2_medium_font,
						font_size = tweak_data.menu.pd2_medium_font_size * 0.8,
						layer = 0,
						color = tweak_data.chat_colors[peer_id] or Color.white,
						alpha = 0.8,
						blend_mode = "add"
					})
					self._peer_latency[peer_id]:set_text( latency > 0 and string.format("%.0fms", latency) or "---ms" )
					self._peer_latency[peer_id]:set_visible(self._enabled)
					local _, _, w, h = self._peer_latency[peer_id]:text_rect()
					self._peer_latency[peer_id]:set_size(w, h)
					self._peer_latency[peer_id]:set_center_x(x)
					self._peer_latency[peer_id]:set_bottom(y - LPI_offset)
				end
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/renderers/menunodeskillswitchgui" then
	local _create_menu_item=MenuNodeSkillSwitchGui._create_menu_item
	function MenuNodeSkillSwitchGui:_create_menu_item(row_item, ...)
		_create_menu_item(self, row_item, ...)
		if row_item.type~="divider" and row_item.name~="back" then
			local gd=Global.skilltree_manager.skill_switches[row_item.name]
			row_item.status_gui:set_text( managers.localization:to_upper_text( ("menu_st_spec_%d"):format( managers.skilltree:digest_value(gd.specialization, false, 1) or 1 ) ) )
			if row_item.skill_points_gui:text() == managers.localization:to_upper_text("menu_st_points_all_spent_skill_switch") then
				local pts, pt, pp, st, sp=0, 1, 0, 2, 0
				for i=1, #gd.trees do
					pts=Application:digest_value(gd.trees[i].points_spent, false)
					if pts>pp then
						sp, st, pp, pt=pp, pt, pts, i
					elseif pts>sp then
						sp, st=pts, i
					end
				end
				row_item.skill_points_gui:set_text(	managers.localization:to_upper_text( tweak_data.skilltree.trees[pt].name_id	) .." / "..	managers.localization:to_upper_text( tweak_data.skilltree.trees[st].name_id	) )
			end
		elseif row_item.type == "divider" and row_item.name == "divider_title" then
			if alive(row_item.status_gui) then
				row_item.status_gui:set_text(managers.localization:to_upper_text("menu_specialization", {}) .. ":")
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/chatmanager" then
	dofile(ModPath .. "lua/utils/NumpadEnter.lua")
	local key_release_actual = ChatGui.key_release
	function ChatGui:key_release(...)
		key_release_actual(self, unpack(NumpadEnterConfirm_RemapNumpadEnter(...)))
	end
	local key_press_actual = ChatGui.key_press
	function ChatGui:key_press(...)
		key_press_actual(self, unpack(NumpadEnterConfirm_RemapNumpadEnter(...)))
	end

	if not ShaveHUD:getSetting({"HUDChat", "SPAM_FILTER"}, true) then return end
	ChatManager._SUB_TABLE = {
		[utf8.char(57364)] = "<SKULL>",	--Skull icon
		[utf8.char(57363)] = "<GHOST>",	--Ghost icon
		[utf8.char(139)] = "<LC>",		--broken bar
		[utf8.char(155)] = "<RC>",
		[utf8.char(1035)] = "<DRC>",
		[utf8.char(1014)] = "<DIV>",	--PocoHuds bar
		[utf8.char(57344)] = "<A>",		--Controller A
		[utf8.char(57345)] = "<B>",		--Controller B
		[utf8.char(57346)] = "<X>",		--Controller X
		[utf8.char(57347)] = "<Y>",		--Controller Y
		[utf8.char(57348)] = "<BACK>",	--Controller BACK
		[utf8.char(57349)] = "<START>",	--Controller START
		[utf8.char(1031)] = "<DOT>",
		[utf8.char(1015)] = "<CHAPTER>",
		[utf8.char(1012)] = "<BIGDOT>",
		[utf8.char(215)] = "<TIMES>",	--Mult
		[utf8.char(247)] = "<DIVIDED>",	--Divided
		[utf8.char(1024)] = "<DEG>",	--Degree
		[utf8.char(1030)] = "<PM>",		--PM Sign
		[utf8.char(1033)] = "<NO>"		--Number

	}

	ChatManager._BLOCK_PATTERNS = {
		".-%[NGBT%w+%].+",
		--NGBTO info blocker Should work since its mass spam.
		"[%d:]+%d:%d%d.-<DIV>.+",
		--Blocks anything, that starts with numbers and ':' and then has a divider (Might block other mods, not only Poco...)
		"Replenished: .+",
	}

	local _receive_message_original = ChatManager._receive_message

	function ChatManager:_receive_message(channel_id, name, message, ...)
		local message2 = message or ""
		for key, subst in pairs(ChatManager._SUB_TABLE) do
			message2 = message2:gsub(key, subst)
		end
		for _, pattern in ipairs(ChatManager._BLOCK_PATTERNS) do
			if message2:match("^" .. pattern .. "$") then
				return ShaveHUD.DEBUG_MODE and _receive_message_original(self, channel_id, name, "Pattern found: " .. pattern, ...)
			end
		end
		return _receive_message_original(self, channel_id, name, message, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/menumanagerdialogs" then
	local function expect_yes(self, params) params.yes_func() end
	MenuManager.show_confirm_buy_premium_contract = expect_yes
	MenuManager.show_confirm_blackmarket_buy_mask_slot = expect_yes
	MenuManager.show_confirm_blackmarket_buy_weapon_slot = expect_yes
	MenuManager.show_confirm_mission_asset_buy = expect_yes
	MenuManager.show_confirm_pay_casino_fee = expect_yes

	local show_person_joining_original = MenuManager.show_person_joining
	local update_person_joining_original = MenuManager.update_person_joining
	local close_person_joining_original = MenuManager.close_person_joining
	function MenuManager:show_person_joining( id, nick, ... )
		self.peer_join_start_t = self.peer_join_start_t or {}
		self.peer_join_start_t[id] = os.clock()
		local peer = managers.network:session():peer(id)
		if peer then
			if peer:rank() > 0 then
				managers.hud:post_event("infamous_player_join_stinger")
			end
			nick = "(" .. (peer:rank() > 0 and managers.experience:rank_string(peer:rank()) .. "-" or "") .. peer:level() .. ") " .. nick
		end
		return show_person_joining_original(self, id, nick, ...)
	end

	function MenuManager:update_person_joining( id, progress_percentage, ... )
		if self.peer_join_start_t and self.peer_join_start_t[id] then
			local t = os.clock() - self.peer_join_start_t[id]
			local result = update_person_joining_original(self, id, progress_percentage, ...)
			local time_left = (t / progress_percentage) * (100 - progress_percentage)
			local dialog = managers.system_menu:get_dialog("user_dropin" .. id)
			if dialog and time_left then
				dialog:set_text(managers.localization:text("dialog_wait") .. string.format(" %d%% (%0.2fs)", progress_percentage, time_left))
			end
		end
	end

	function MenuManager:close_person_joining(id, ...)
		if self.peer_join_start_t then
			self.peer_join_start_t[id] = nil
		end
		--[[
				if managers.chat and managers.system_menu:is_active_by_id("user_dropin" .. id) then
					local peer = managers.network:session() and managers.network:session():peer(id)
					local text = ""
					if peer then
						local name = peer:name()
						local level = (peer:rank() > 0 and managers.experience:rank_string(peer:rank()) .. "-" or "") .. (peer:level() or "")
						local outfit_skills = (peer:blackmarket_outfit() or {}).skills
						local perk = "[Unknown Perkdeck]"
						local skill_str = "[No Skilldata available]"

						if outfit_skills then
							if outfit_skills.specializations then
								local deck_index, deck_level = unpack(outfit_skills.specializations or {})
								local data = tweak_data.skilltree.specializations[tonumber(deck_index)]
								local name_id = data and data.name_id
								if name_id then
									perk = string.format("%s%s", managers.localization:text(name_id), tonumber(deck_level) < 9 and string.format(" (%d/9)", deck_level) or "")
								end
							end

							local skill_data = outfit_skills.skills
							if skill_data then
								local tree_names = {}
								for i, tree in ipairs(tweak_data.skilltree.skill_pages_order) do
									local tree = tweak_data.skilltree.skilltree[tree]
									if tree then
										table.insert(tree_names, tree.name_id and utf8.sub(managers.localization:text(tree.name_id), 1, 1) or "?")
									end
								end

								local subtree_amt = math.floor(#skill_data / #tree_names)
								skill_str = ""

								for tree = 1, #tree_names, 1 do
									local tree_has_points = false
									local tree_sum = 0

									for sub_tree = 1, subtree_amt, 1 do
										local skills = skill_data[(tree-1) * subtree_amt + sub_tree] or 0
										tree_sum = tree_sum + skills
									end
									skill_str = string.format("%s%s:%02d ", skill_str, tree_names[tree] or "?", tree_sum)
								end
							end

							text = string.format("%s, %s", skill_str, perk)
						else
							text = "[invalid outfit]"
						end

						managers.chat:feed_system_message(ChatManager.GAME, string.format("(%s) %s: %s", level, name, text))
					end
				end
		]]
		close_person_joining_original(self, id, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/localizationmanager" then
	if not ShaveHUD:getSetting({"INVENTORY", "CLEAR_DESCRIPTIONS"}, true) then
		return
	end

	local some_strings = {
		-- Throwables
		bm_ability_chico_injector_desc = "Duration: 6s\nCooldown: 30s\nCooldown Reduction: 1s on kill\n\nHealth Gain per damage (>=50% health): 75%\nHealth Gain per damage (<50% health): 100%\n\n",
		bm_concussion_desc = "Damage: 0 + Stun\nExplosion Radius: 15m\nThrow Delay: 0.1s\nThrow Rate: 1.5s\nUnequip Delay: 0.9s\n\nStun Duration: 3s + 5s Accuracy Debuff (-50%)\n\n",
		bm_dynamite_desc = "Max Damage: 1,600\nExplosion Radius: 5m\nThrow Delay: 0.1s\nThrow Rate: 1.5s\nUnequip Delay: 1.3s\n\n",
		bm_grenade_dada_com_desc = "Max Damage: 1,600\nExplosion Radius: 10m\nThrow Delay: 0.1s\nThrow Rate: 1.5s\nUnequip Delay: 1.3s\n\n",
		bm_grenade_damage_control_desc = "Cooldown: 10s\nCooldown Reduction (>= 35% health): 1s on kill\nCooldown Reduction (< 35% health): 2s on kill\n\n",
		bm_grenade_fir_com_desc = "Damage: 30 (Explosion) + 750 (DoT, if proc)\nExplosion Radius: 5m\nThrow Delay: 0.1s\nThrow Rate: 1.5s\nUnequip Delay: 1.3s\n\nFire Proc Chance: 35%\nFire Damage/Tick: 250 every 0.5s (after 1.0s delay)\nFire DoT Duration: 1.1s\nStun Duration: 4.3s\n\n",
		bm_grenade_frag_desc = "Max Damage: 1,600\nExplosion Radius: 5m\nThrow Delay: 0.1s\nThrow Rate: 1.5s\nUnequip Delay: 1.1s\n\n",
		bm_grenade_frag_com_desc = "Max Damage: 1,600\nExplosion Radius: 5m\nThrow Delay: 0.1s\nThrow Rate: 1.5s\nUnequip Delay: 1.1s\n\n",
		bm_grenade_molotov_desc = "Damage: 30 (Explosion) + 1,500 (DoT, if proc)\n+ 10 every 0.5s for 15s (AoE)\nExplosion Radius: 5m\nThrow Delay: 0.1s\nThrow Rate: 1.5s\nUnequip Delay: 1.3s\n\nFire Proc Chance: 35%\nFire Damage/Tick: 150 every 0.5s (after 1.0s delay)\nFire DoT Duration: 5s\nStun Duration: 4.3s\n\n",
		bm_grenade_pocket_ecm_jammer_desc = "Effect Duration: 6s\nCooldown: 100s per charge\nCooldown Reduction: 6s on kill\n\nDuring Feedback:\nHealth Gain on kill: 20\nHealth Gain on teammate kill: 10\n\nSecond charge cannot be activated while the first is still active. Chaining your own charges might glitch the second's duration to 0.25s.\n\n",
		bm_grenade_smoke_screen_grenade_desc = "Damage: 0\nSmoke Radius: 15m\n\nSmoke Duration: 10s\nCooldown: 60s (on activation)\nCooldown Reduction: 1s on kill\n\nDodge: +15% (Self) / +10% (Team)\nBullet Evasion: 50% (Self+Team)\nAccuracy: -50% (Enemies)\nAdditionally, doubles temporary Dodge when hit (from \"Twitch\" perk) to 40% total.\n\n",
		bm_grenade_tag_team_desc = "Tag Range: 18m\n\nTag Duration: 12s\nDuration Extension: 1.3s on kill\nCooldown: 60s (on activation)\nCooldown Reduction: 2s on kill\nHealth Gain (self): 15 on kill\nHealth Gain (tagged): 7.5 on kill\n\n",
		bm_wpn_prj_ace_desc = "Damage: 40\nProjectile Speed: 15m/s\nThrow Delay: 0.15s\nThrow Rate: 0.3s\nUnequip Delay: 1.1s\n\n",
		bm_wpn_prj_four_desc = "Damage: 100 (Hit) + 2,750 (DoT, 100% proc)\nProjectile Speed: 15m/s\nThrow Delay: 0.15s\nThrow Rate: 0.5s\nUnequip Delay: 1.1s\n\nPoison Damage/Tick: 250 every 0.5s (after 0.5s delay)\nPoison DoT Duration: 5.5s\nStun Duration: 5.5s\n\n",
		bm_wpn_prj_jav_desc = "Damage: 3,250\nProjectile Speed: 15m/s\nThrow Delay: 0.4s\nThrow Rate: 1.0s\nUnequip Delay: 1.1s\n\n",
		bm_wpn_prj_hur_desc = "Damage: 1,100\nProjectile Speed: 10m/s\nThrow Delay: 0.15s\nThrow Rate: 0.5s\nUnequip Delay: 1.1s\n\n",
		bm_wpn_prj_target_desc = "Damage: 1,100\nProjectile Speed: 10m/s\nThrow Delay: 0.1s\nThrow Rate: 0.5s\nUnequip Delay: 1.1s\n\n",
		-- Weapon Gadgets
		bm_wp_upg_fl_crimson_desc = "Togglable laser sight.\n\n",
		bm_wp_upg_fl_x400v_desc = "Togglable laser sight and flashlight.\n\n",
		bm_wp_upg_fl_pis_tlr1_desc = "Togglable flashlight.\n\n",
		bm_wp_upg_fl_pis_laser_desc = "Togglable laser sight.\n\n",
		bm_wp_upg_fl_pis_m3x_desc = "Togglable flashlight.\n\n",
		bm_wp_pis_g_laser_desc = "Togglable laser sight.\n\n",
		bm_wp_pis_ppk_g_laser_desc = "Togglable laser sight.",
		bm_wp_upg_fl_ass_smg_sho_surefire_desc = "Togglable flashlight.\n\n",
		bm_wp_upg_fl_ass_smg_sho_peqbox_desc = "Togglable laser sight.\n\n",
		bm_wp_upg_fl_ass_laser_desc = "Togglable laser sight.\n\n",
		bm_wp_upg_fl_ass_peq15_desc = "Togglable laser sight and flashlight.\n\n",
		bm_wp_upg_fl_ass_utg_desc = "Togglable laser sight and flashlight.\n\n",
		bm_wpn_fps_upg_o_45iron_desc = "Togglable iron sights.\n\n",
		bm_wpn_fps_upg_o_45rds_desc = "Togglable red dot sight.\n\n",
		bm_wpn_fps_upg_o_45rds_v2_desc = "Togglable red dot sight.\n\n",
		bm_wpn_fps_upg_o_xpsg33_magnifier_desc = "Togglable sight magnifier.\n\n",
		bm_wpn_fps_upg_o_sig_desc = "Togglable sight magnifier.\n\n",
		bm_wpn_fps_upg_o_45steel_desc = "Togglable iron sight.\n\n",
		bm_wp_mp5_fg_flash_desc = "Togglable flashlight.\n\n",
		bm_wp_schakal_vg_surefire_desc = "Togglable laser sight and flashlight.\n\n",
		-- Perk Decks
		menu_deck1_3_desc = "NOTE: The damage reduction requires the Underdog skill to function.\n\n",
		menu_deck8_7_desc = "NOTE: Missing a melee strike resets the damage buff. The buff can be activated by hitting team AI and civilians as well. Effect does not restart, nor become active if an enemy is countered using Counterstrike.\n\n",
		menu_deck8_1_desc = "NOTE: Perk adds an additional 6 seconds to OVERDOG's duration of the extra damage on melee strike, for a total of 7 seconds before expiring.\n\n",
		menu_deck9_1_desc = "NOTE: Missing a melee strike resets the damage buff. The buff can be activated by hitting team AI and civilians as well. Effect does not restart, nor become active if an enemy is countered using Counterstrike.\n\n",
		menu_deck13_5_desc = "NOTE: Perk will actually increase dodge by 15% (not 10%).\n\n",
		menu_deck15_9_desc= "NOTE: Perk will actually grant 30 armor on dealing damage (not 10).\n\n",
		menu_deck17_1_desc = "NOTE: Every kill reduces the cooldown by 1 second.\n\n",
		menu_deck17_9_desc = "NOTE: Actually activates every 50 points of health gained (not 5).\n\n",
		menu_deck18_9_desc = "NOTE: Perk does not double the effects of Smoker.\n\n",
		menu_deck20_1_desc = "NOTE: The effect actually has a duration of 12 seconds with a cooldown of 60 seconds. The cooldown begins immediately upon usage, rather than after the effect ends. The cooldown reduction on kill is always active, not only when the Dispenser is in use.\n\n",
		menu_deck21_1_desc = "NOTE: Charges run on separate cooldowns. When both charges are used, the second charge will not run its cooldown or have it reduced by kills until the first charge's cooldown finishes.\n\n",
		menu_deck21_5_desc = "NOTE: Perk increases dodge by 15%.\n\n",
		menu_deck21_9_desc = "NOTE: Perk increases dodge by 15%.\n\n"
	}
	local old_text = LocalizationManager.text
	function LocalizationManager:text(string_id, ...)
		local new_string = some_strings[string_id] or ""
		return new_string .. old_text(self,string_id,...)
	end

    local testAllStrings = false
	local text_orig = LocalizationManager.text
    function LocalizationManager:text(string_id, ...)
		return string_id == "bm_wp_mosin_ns_bayonet_desc" and "Increases Weapon Butt base damage to 40 and base knockdown to 70."
			-- Arrows
			or string_id == "bm_wp_bow_long_explosion_desc" and "Explosive arrow that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
			or string_id == "bm_wp_bow_long_poison_desc" and "Poison arrows deal 250 damage every 0.5s (after 0.5s delay) for 5.5s, with a 50% chance to stun enemies for the duration."
			or string_id == "bm_wp_upg_a_bow_poison_desc" and "Poison arrows deal 250 damage every 0.5s (after 0.5s delay) for 5.5s, with a 50% chance to stun enemies for the duration."
			or string_id == "bm_wpn_fps_upg_a_bow_explosion_desc" and "Explosive arrow that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
			or string_id == "bm_wp_elastic_m_explosive_desc" and "Explosive arrow that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
			or string_id == "bm_wp_elastic_m_poison_desc" and "Poison arrows deal 250 damage every 0.5s (after 0.5s delay) for 5.5s, with a 50% chance to stun enemies for the duration."
			or string_id == "bm_wp_ecp_m_arrows_explosive_desc" and "Explosive arrow that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
			or string_id == "bm_wp_ecp_m_arrows_poison_desc" and "Poison arrows deal 250 damage every 0.5s (after 0.5s delay) for 5.5s, with a 50% chance to stun enemies for the duration."
			-- Bolts
			or string_id == "bm_wp_upg_a_frankish_explosion_desc" and "Explosive bolt that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
			or string_id == "bm_wp_upg_a_frankish_poison_desc" and "Poison bolts deal 250 damage every 0.5s (after 0.5s delay) for 5.5s, with a 50% chance to stun enemies for the duration."
			or string_id == "bm_wp_upg_a_arblast_explosion_desc" and "Explosive bolt that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
			or string_id == "bm_wp_upg_a_arblast_poison_desc" and "Poison bolts deal 250 damage every 0.5s (after 0.5s delay) for 5.5s, with a 50% chance to stun enemies for the duration."
			or string_id == "bm_wp_upg_a_crossbow_explosion_desc" and "Explosive bolt that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
			or string_id == "bm_wp_upg_a_crossbow_poison_desc" and "Poison bolts deal 250 damage every 0.5s (after 0.5s delay) for 5.5s, with a 50% chance to stun enemies for the duration."
			-- Melee Weapons
			or string_id == "bm_melee_taser_info" and "Interrupts and stuns the target for 3.2, 3.4, 3.7 or 3.9 seconds (25% chance each). Bulldozers are only stunned for 0.01 seconds. Does not work on unique enemies (\"bosses\")."
			or string_id == "bm_melee_zeus_info" and "Interrupts and stuns the target for 3.2, 3.4, 3.7 or 3.9 seconds (25% chance each). Bulldozers are only stunned for 0.01 seconds. Does not work on unique enemies (\"bosses\")."
			or string_id == "bm_melee_fear_info" and "The syringe is filled with poison, dealing 250 damage once (after 0.5s delay), with a 70% chance to stun enemies for 0.5s."
			or string_id == "bm_melee_cqc_info" and "The Kunai is coated in poison, dealing 250 damage once (after 0.5s delay), with a 70% chance to stun enemies for 0.5s."
			-- Shotgun Ammo
			or string_id == "bm_wp_upg_a_custom_desc" and "Increased damage. Range: 20-50m"
			or string_id == "bm_wp_upg_a_custom2_desc" and "Increased damage. Range: 20-50m"
			or string_id == "bm_wp_upg_a_explosive_desc" and "Long range explosive slug. Penetrates shields and deals extra damage to armor plating and Captain Winters. Cannot headshot. Range: 40-115m"
			or string_id == "bm_wp_upg_a_piercing_desc" and "Long range flechettes. Penetrates armor. Range: 40-91m"
			or string_id == "bm_wp_upg_a_slug_desc" and "Long range slug. Penetrates enemies, armor, shields, and walls. Range: 40-74.5m"
			or string_id == "bm_wp_upg_a_slug2_desc" and "Long range slug. Penetrates enemies, armor, shields, and walls. Range: 40-74.5m"
			or string_id == "bm_wp_upg_a_dragons_breath_desc" and "Pellets ignite enemies less than 30 m away, dealing 100 damage every 0.5s for 2.1s (after 1.0s delay). Pierces shields and armor. Cannot headshot or be silenced. Range: 40-74.5m"
			-- Launcher Ammo
			or string_id == "bm_wp_upg_a_grenade_launcher_incendiary_desc" and "Incendiary rounds leave patches of fire for 6s (3s if Arbiter) that deal 30 damage every 0.5s. Damage has a 35% chance to ignite enemies, dealing 150 damage every 0.5s (after 1.0s delay) for 5s and stunning them for 4.3s."
			
		or testAllStrings == true and string_id
		or text_orig(self, string_id, ...)
	end
elseif string.lower(RequiredScript) == "lib/setups/menusetup" then
	if not ShaveHUD:getSetting({"SkipIt", "SKIP_INTROS"}, true) then
		return
	end
	------------
	-- Purpose: Hooks MenuSetup:init_game() to force the game to skip the intro videos and go straight to the attract screen (as
	--          though -skip_intro had been specified on the command line)
	------------

	local init_game_actual = MenuSetup.init_game
	function MenuSetup:init_game(...)
		local result = init_game_actual(self, ...)

		game_state_machine:set_boot_intro_done(true)
		-- WARNING: Do not go straight to "menu_main" as that bypasses loading of the savefile and is likely to cause data loss (not
		-- extensively tested)
		game_state_machine:change_state_by_name("menu_titlescreen")

		return result
	end
elseif string.lower(RequiredScript) == "lib/states/menutitlescreenstate" then
	if not ShaveHUD:getSetting({"SkipIt", "SKIP_INTROS"}, true) then
		return
	end
	------------
	-- Purpose: Hooks MenuTitlescreenState:get_start_pressed_controller_index() to trigger the game to proceed straight to the main
	--          menu with keyboard input instead of waiting on the attract screen, and also hooks
	--          MenuTitlescreenState:_load_savegames_done() to suppress the menu entry sound that is played when the main menu is
	--          entered (but only for automatic entries)
	------------

	local silenced = false

	local get_start_pressed_controller_index_actual = MenuTitlescreenState.get_start_pressed_controller_index
	function MenuTitlescreenState:get_start_pressed_controller_index(...)

		local num_connected = 0
		local keyboard_index = nil

		for index, controller in ipairs(self._controller_list) do
			if controller._was_connected then
				num_connected = num_connected + 1
			end
			if controller._default_controller_id == "keyboard" then
				keyboard_index = index
			end
		end

		if num_connected == 1 and keyboard_index ~= nil then
			silenced = true
			return keyboard_index
		else
			return get_start_pressed_controller_index_actual(self, ...)
		end
	end

	local _load_savegames_done_actual = MenuTitlescreenState._load_savegames_done
	function MenuTitlescreenState:_load_savegames_done(...)
		if silenced then
			-- Shush. Don't play that sound if this is an automatic entry
			self:gsm():change_state_by_name("menu_main")
		else
			_load_savegames_done_actual(self, ...)
		end
	end
end