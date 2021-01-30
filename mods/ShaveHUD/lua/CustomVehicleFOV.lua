if not ShaveHUD:getSetting({"Misc", "VEHICLE_FOV"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/tweak_data/vehicletweakdata" then
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
end