if not ShaveHUD:getSetting({"INVENTORY", "RETURNABLE_MASK_COMPONENTS"}, true) then
	return
end

-- Make masks, materials, textures, and colors returnable by setting their value to 0.
-- There almost certainly is a better way to do this, but it would probably be 
-- both tougher to mod and breakage-prone, so I have not bothered
-- If you would like to attempt it yourself, the concerned functions seem to be:
--     BlackMarketGui:update_info_text()
--     BlackMarketGui:remove_mask_callback(data)
--     BlackMarketGui:sell_mask_callback
--     BlackMarketManager:on_sell_mask
-- If things change, grep source for get_mask_sell_value

if string.lower(RequiredScript) == "lib/tweak_data/blackmarket/maskstweakdata" then
    local original_init_masks = BlackMarketTweakData._init_masks
    function BlackMarketTweakData:_init_masks(tweak_data)
        original_init_masks(self, tweak_data)
        for _, mask in pairs(self.masks) do
            mask.value = 0
        end
    end
elseif string.lower(RequiredScript) == "lib/tweak_data/blackmarket/materialstweakdata" then
    local original_init_materials = BlackMarketTweakData._init_materials
    function BlackMarketTweakData:_init_materials(tweak_data)
        original_init_materials(self, tweak_data)
        for _, material in pairs(self.materials) do
            material.value = 0
        end
    end
elseif string.lower(RequiredScript) == "lib/tweak_data/blackmarket/texturestweakdata" then
    local original_init_textures = BlackMarketTweakData._init_textures
    function BlackMarketTweakData:_init_textures(tweak_data)
        original_init_textures(self, tweak_data)
        for _, texture in pairs(self.textures) do
            texture.value = 0
        end
    end
elseif string.lower(RequiredScript) == "lib/tweak_data/blackmarket/colorstweakdata" then
    local original_init_colors = BlackMarketTweakData._init_colors
    function BlackMarketTweakData:_init_colors(tweak_data)
        original_init_colors(self, tweak_data)
        for _, color in pairs(self.colors) do
            color.value = 0
        end
    end
end
