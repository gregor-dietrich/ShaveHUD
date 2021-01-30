if not ShaveHUD:getSetting({"Misc", "LADDER_IMPROVEMENTS"}, true) then
	return
end

if string.lower(RequiredScript) == "lib/units/beings/player/states/playerstandard" then
    --too lazy to check which of these are actually needed, especially since i might need them again later if i change the mod
    local mvec3_dis_sq = mvector3.distance_sq
    local mvec3_set = mvector3.set
    local mvec3_set_z = mvector3.set_z
    local mvec3_sub = mvector3.subtract
    local mvec3_add = mvector3.add
    local mvec3_mul = mvector3.multiply
    local mvec3_norm = mvector3.normalize

    local temp_vec1 = Vector3()

    local tmp_ground_from_vec = Vector3()
    local tmp_ground_to_vec = Vector3()
    local up_offset_vec = math.UP * 30
    local down_offset_vec = math.UP * -40

    local win32 = SystemInfo:platform() == Idstring("WIN32")

    local mvec_pos_new = Vector3()
    local mvec_achieved_walk_vel = Vector3()
    local mvec_move_dir_normalized = Vector3()


    local orig_check_jump = PlayerStandard._check_action_jump
    function PlayerStandard:_check_action_jump(t, input)
        if input.btn_jump_press then 
            --don't need to check for action forbidden or cooldown, since this only applies to ladders
            if self._state_data.ducking then 
                --nothing
            elseif self._state_data.on_ladder then
                self:_interupt_action_ladder(t)
                return --this is the only thing i've really changed: no jumping on ladders >:(
            end
        end
        return orig_check_jump(self,t,input)
    end

    function PlayerStandard:_check_action_ladder(t, input)
            local downed = self._controller:get_any_input() --input.downed
            local hold_jump = downed and self._controller:get_input_bool("jump")
            local release_jump = released and self._controller:get_input_released("jump")
            local hold_duck = downed and self._controller:get_input_bool("duck")
            
        if self._state_data.on_ladder then
            local ladder_unit = self._unit:movement():ladder_unit()
            
            if not hold_jump and ladder_unit:ladder():check_end_climbing(self._unit:movement():m_pos(), self._normal_move_dir, self._gnd_ray) then
                self:_end_action_ladder(t,input) --doesn't really need any arguments but just in case some other modder wants to do something with that
                return
            elseif hold_jump then 
                self:_end_action_ladder(t,input)
                return
            end

            if hold_duck and self._unit:mover() then
                self._unit:mover():set_gravity(Vector3(0, 0, -982))
                return
            elseif input.btn_duck_release and self._unit:mover() then
                self._unit:mover():set_gravity(Vector3(0,0,0))
                self._unit:mover():set_velocity(Vector3())
            end

        elseif hold_jump then 
            return --if hold jump, don't try to detect ladders + start climbing
        end

        local u_pos = self._unit:movement():m_pos()
        local ladder_unit

        for i = 1, math.min(Ladder.LADDERS_PER_FRAME, #Ladder.active_ladders), 1 do
            ladder_unit = Ladder.next_ladder()

            if alive(ladder_unit) then

                local can_access = ladder_unit:ladder():can_access(u_pos, self._move_dir or self._ext_camera:forward())
                --if not moving (self._move_dir) then check for valid ladder positions using camera direction
                --this way, player will automatically grab any ladder that they are facing
                --TACTICOOL REALISM WINS AGAIN WOOOO
                if can_access then
                    self:_start_action_ladder(t, ladder_unit)
                    break
                end
            end
        end
    end
elseif string.lower(RequiredScript) == "lib/units/beings/player/playerdamage" then
    local orig_damage = PlayerDamage.damage_fall
    function PlayerDamage:damage_fall(...)
        if self._unit:movement():current_state()._state_data.on_ladder then
            return --no damage if you're using the slide-down-ladders feature
        end
        return orig_damage(self,...)
    end
end