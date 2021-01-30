if not ShaveHUD:getSetting({"Misc", "KICK_FRIEND"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/network/base/basenetworksession" then
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
end