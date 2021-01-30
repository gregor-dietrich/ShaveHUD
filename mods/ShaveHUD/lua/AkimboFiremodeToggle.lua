if not ShaveHUD:getSetting({"EQUIPMENT", "ENABLE_AKIMBO_MODE"}, true) then
  return
end

if string.lower(RequiredScript) == "lib/units/weapons/akimboweaponbase" then
    function AkimboWeaponBase:toggle_akimbo_fire()
      self._manual_fire_second_gun=not self._manual_fire_second_gun
      local on = self._manual_fire_second_gun
      managers.hud:show_hint({
      text=on and "x1 fire" or "x2 fire",
      time=0.5
    })
  end
end