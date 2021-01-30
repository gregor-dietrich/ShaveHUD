if not ShaveHUD:getSetting({"INVENTORY", "CLEAR_DESCRIPTIONS"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/managers/localizationmanager" then
    local text_original = LocalizationManager.text
    local testAllStrings = false
    function LocalizationManager:text(string_id, ...)
    return string_id == "bm_wp_upg_fl_crimson_desc" and "Toggleable laser sight."
    or string_id == "bm_wp_upg_fl_x400v_desc" and "Toggleable laser sight and flashlight."
    or string_id == "bm_wp_upg_fl_pis_tlr1_desc" and "Toggleable flashlight."
    or string_id == "bm_wp_upg_fl_pis_laser_desc" and "Toggleable laser sight."
    or string_id == "bm_wp_upg_fl_pis_m3x_desc" and "Toggleable flashlight."
    or string_id == "bm_wp_pis_g_laser_desc" and "Toggleable laser sight."
    or string_id == "bm_wp_pis_ppk_g_laser_desc" and "Toggleable laser sight."
    or string_id == "bm_wp_upg_a_custom_desc" and "Increased damage. Range: 20-50m"
    or string_id == "bm_wp_upg_a_custom2_desc" and "Increased damage. Range: 20-50m"
    or string_id == "bm_wp_upg_a_explosive_desc" and "Long range explosive slug. Penetrates shields and deals extra damage to armor plating and Captain Winters. Cannot headshot. Range: 40-115m"
    or string_id == "bm_wp_upg_a_piercing_desc" and "Long range flechettes. Penetrates armor. Range: 40-91m"
    or string_id == "bm_wp_upg_a_slug_desc" and "Long range slug. Penetrates enemies, armor, shields, and walls. Range: 40-74.5m"
    or string_id == "bm_wp_upg_a_slug2_desc" and "Long range slug. Penetrates enemies, armor, shields, and walls. Range: 40-74.5m"
    or string_id == "bm_wp_upg_a_dragons_breath_desc" and "Pellets ignite enemies, dealing 100 damage per 0.5 seconds for 3.1 seconds. Pierces shields and armor. Cannot headshot or be silenced. Range: 40-74.5m"
    or string_id == "bm_wp_upg_fl_ass_smg_sho_surefire_desc" and "Toggleable flashlight."
    or string_id == "bm_wp_upg_fl_ass_smg_sho_peqbox_desc" and "Toggleable laser sight."
    or string_id == "bm_wp_upg_fl_ass_laser_desc" and "Toggleable laser sight."
    or string_id == "bm_wp_upg_fl_ass_peq15_desc" and "Toggleable laser sight and flashlight."
    or string_id == "bm_wp_upg_fl_ass_utg_desc" and "Toggleable laser sight and flashlight."
    or string_id == "bm_wpn_fps_upg_o_45iron_desc" and "Toggleable iron sights."
    or string_id == "bm_wpn_fps_upg_o_45rds_desc" and "Toggleable red dot sight."
    or string_id == "bm_wpn_fps_upg_o_45rds_v2_desc" and "Toggleable red dot sight."
    or string_id == "bm_wpn_fps_upg_o_xpsg33_magnifier_desc" and "Toggleable sight magnifier."
    or string_id == "bm_wp_mp5_fg_flash_desc" and "Toggleable flashlight."
    or string_id == "bm_wp_schakal_vg_surefire_desc" and "Toggleable laser sight and flashlight."
    or string_id == "bm_wp_mosin_ns_bayonet_desc" and "Increases Weapon Butt base damage to 40."
    or string_id == "bm_wp_bow_long_explosion_desc" and "Explosive arrow that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
    or string_id == "bm_wp_bow_long_poison_desc" and "Poison arrows deal 250 damage per 0.5 seconds for 6 seconds. 50% chance to stun enemies for its duration."
    or string_id == "bm_wp_upg_a_bow_poison_desc" and "Poison arrows deal 250 damage per 0.5 seconds for 6 seconds. 50% chance to stun enemies for its duration."
    or string_id == "bm_wpn_fps_upg_a_bow_explosion_desc" and "Explosive arrow that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
    or string_id == "bm_wpn_prj_four_desc" and "Shurikens are coated in poison, dealing 250 damage per 0.5 seconds for 6 seconds, with a 100% chance to stun enemies for its duration."
    or string_id == "bm_melee_cqc_info" and "The Kunai is coated in poison, dealing 250 damage after 0.5 seconds, with a 70% chance to stun enemies for 1 second."
    or string_id == "bm_wp_upg_a_grenade_launcher_incendiary_desc" and "Incendiary rounds leave patches of fire for 6 seconds that deal 30 damage per 0.5 seconds. Damage has a 35% chance to cause panic and ignite enemies, dealing an extra 100 damage per 0.5 seconds for 3.1 seconds."
    or string_id == "bm_wp_upg_a_frankish_explosion_desc" and "Explosive bolt that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
    or string_id == "bm_wp_upg_a_frankish_poison_desc" and "Poison bolts deal 250 damage per 0.5 seconds for 6 seconds. 50% chance to stun enemies for its duration."
    or string_id == "bm_wp_upg_a_arblast_explosion_desc" and "Explosive bolt that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
    or string_id == "bm_wp_upg_a_arblast_poison_desc" and "Poison bolts deal 250 damage per 0.5 seconds for 6 seconds. 50% chance to stun enemies for its duration."
    or string_id == "bm_wp_upg_a_crossbow_explosion_desc" and "Explosive bolt that deals damage in an area, and goes through shields and armor. Deals extra damage to armor plating and Captain Winters. Cannot headshot or be retrieved."
    or string_id == "bm_wp_upg_a_crossbow_poison_desc" and "Poison bolts deal 250 damage per 0.5 seconds for 6 seconds. 50% chance to stun enemies for its duration."

    or testAllStrings == true and string_id
    or text_original(self, string_id, ...)
    end
end