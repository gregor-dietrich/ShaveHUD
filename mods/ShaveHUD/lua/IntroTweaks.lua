if string.lower(RequiredScript) == "lib/managers/hud/hudmissionbriefing" then
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
end