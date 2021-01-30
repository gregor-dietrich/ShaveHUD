--do return end	-- Disabled cause: WiP
if ShaveHUD and not ShaveHUD.Sync then
	ShaveHUD.Sync = {
		msg_id = "ShaveHUD_Sync",
		peers = { false, false, false, false },
		events = {
			discover_shavehud 		= "Using_ShaveHUD?",
			confirm_shavehud 		= "Using_ShaveHUD!",
			peer_disconnect 		= "Leaving_Game",
			locked_assault_status 	= "locked_assault_status",
		},
	}

	local Net = _G.LuaNetworking

	function ShaveHUD.Sync.table_to_string(tbl)
		return Net:TableToString(tbl) or ""
	end

	function ShaveHUD.Sync.string_to_table(str)
		local tbl = Net:StringToTable(str) or ""

		for k, v in pairs(tbl) do
			tbl[k] = self.to_original_type(v)
		end

		return tbl
	end
	
	function ShaveHUD.Sync.to_original_type(s)
		local v = s
		if type(s) == "string" then
			if s == "nil" then
				v = nil
			elseif s == "true" or s == "false" then
				v = (s == "true")
			else
				v = tonumber(s) or s
			end
		end
		return v
	end

	function ShaveHUD.Sync:send_to_peer(peer_id, messageType, data)
		if peer_id and peer_id ~= Net:LocalPeerID() and messageType then
			local tags = {
				id = self.msg_id,
				event = messageType
			}

			if type(data) == "table" then
				data = self.table_to_string(data)
				tags["table"] = true
			end

			Net:SendToPeer(peer_id, self.table_to_string(tags), data or "")
		end
	end

	function ShaveHUD.Sync:send_to_host(messageType, data)
		self:send_to_peer(managers.network:session():server_peer():id(), messageType, data)
	end

	function ShaveHUD.Sync:send_to_all_peers( messageType, data)
		for peer_id, enabled in ipairs(self.peers) do
			self:send_to_peer(peer_id, messageType, data)
		end
	end

	function ShaveHUD.Sync:send_to_all_discovered_peers( messageType, data)
		for peer_id, enabled in ipairs(self.peers) do
			if enabled then
				self:send_to_peer(peer_id, messageType, data)
			end
		end
	end

	function ShaveHUD.Sync:send_to_all_undiscovered_peers( messageType, data)
		for peer_id, enabled in ipairs(self.peers) do
			if not enabled then
				self:send_to_peer(peer_id, messageType, data)
			end
		end
	end

	function ShaveHUD.Sync:receive_message(peer_id, event, data)
		if peer_id and event then
			local events = ShaveHUD.Sync.events

			if event == events.discover_shavehud then
				ShaveHUD.Sync:send_to_peer(peer_id, events.confirm_shavehud)
				ShaveHUD.Sync.peers[peer_id] = true
				managers.chat:feed_system_message(ChatManager.GAME, "Client " .. tostring(peer_id) .. " is using ShaveHUD ;)")	--TEST
			elseif event == events.confirm_shavehud then
				ShaveHUD.Sync.peers[peer_id] = true
				managers.chat:feed_system_message(ChatManager.GAME, "The Host is using ShaveHUD ;)")	--TEST
			elseif event == events.peer_disconnect then
				ShaveHUD.Sync.peers[peer_id] = false
			elseif event == events.locked_assault_status then
				managers.hud:_locked_assault(data)
			end
		end
	end

	-- Manage Networking and list of peers to sync to...
	Hooks:Add("NetworkReceivedData", "NetworkReceivedData_ShaveHUDSync", function(sender, messageType, data)
		sender = tonumber(sender)
		if sender then
			local tags = ShaveHUD.Sync.string_to_table(messageType)
			if ShaveHUD.Sync and tags.id and tags.id == ShaveHUD.Sync.msg_id and not string.is_nil_or_empty(tags.event) then
				if tags.table then
					data = ShaveHUD.Sync.string_to_table(data)
				else
					data = ShaveHUD.Sync.to_original_type(data)
				end

				ShaveHUD.Sync:receive_message(sender, tags.event, data)
			end
		end
	end)

	Hooks:Add("BaseNetworkSessionOnPeerRemoved", "BaseNetworkSessionOnPeerRemoved_ShaveHUDSync", function(self, peer, peer_id, reason)
		ShaveHUD.Sync:receive_message(peer_id, ShaveHUD.Sync.events.peer_disconnect, "")
	end)

	Hooks:Add("BaseNetworkSessionOnLoadComplete", "BaseNetworkSessionOnLoadComplete_ShaveHUDSync", function(local_peer, id)
		if ShaveHUD.Sync and Net:IsMultiplayer() and Network:is_client() then
			ShaveHUD.Sync:send_to_host(ShaveHUD.Sync.events.discover_shavehud)
		end
	end)


	-- Data Sync functions:

	function ShaveHUD.Sync:endless_assault_status(status)
		if Network:is_server() then
			self:send_to_all_discovered_peers(ShaveHUD.Sync.events.locked_assault_status, tostring(status))
		end
	end
end