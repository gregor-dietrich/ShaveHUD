if not ShaveHUD:getSetting({"Misc", "REDUNDANT_CARD_REMOVAL"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/tweak_data/lootdroptweakdata" then
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
end