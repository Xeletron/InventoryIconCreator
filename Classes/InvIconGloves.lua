InvIconGloves = InvIconGloves or class()
function InvIconGloves:init(parent, holder)
    self._parent = parent
	self._menu = holder:Holder({
		name = "InvIconGloves",
		auto_height = true,
        background_visible = false,
		full_bg_color = false,
		visible = false
	})

	self._gloves = self._menu:ComboBox({name = "GloveID", text = "Glove ID", value = 1, items = self:_get_all_gloves(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_gloves")})
end

function InvIconGloves:_get_all_gloves()
	local t = clone(tweak_data.blackmarket.glove_list)

	table.delete(t, "default")
	table.insert(t, 1, "")

	return t
end

function InvIconGloves:_get_all_characters()
	local t = {}

	for _, character in ipairs(CriminalsManager.character_names()) do
		table.insert(t, CriminalsManager.convert_old_to_new_character_workname(character))
	end

	return t
end

function InvIconGloves:_update_gloves(item)
	if self._parent:auto_refresh() then
		self:preview_item()
	end
end

function InvIconGloves:job_settings()
	return {
		distance = 2250,
		fov = 1.2,
		rot = Rotation(90, 0, 0),
		res = Vector3(1000, 1000, 0),
		offset = Vector3(0, 0, 0),
		item_rot = Rotation(90, 0, 0)
    }
end

function InvIconGloves:_set_transparent_materials(func)
	if alive(self._unit) then
		func(self, self._unit)
    end
end

function InvIconGloves:SetEnabled(enabled)
    self._menu:SetVisible(enabled)
end

function InvIconGloves:_create_item(glove_id, clbk)
	self._parent:destroy_items()
	
	if not alive(self._unit) then
		self:_create_character()
	end

	self._parent._current_texture_name = glove_id
	self._unit:base():set_glove_id(glove_id)
	self._unit:base():add_clbk_listener("done", ClassClbk(self, "_gloves_done", clbk or false))
	self._unit:set_visible(false)
end

function InvIconGloves:_create_character()
	local unit_name = tweak_data.blackmarket.characters.locked.menu_unit

	local rot = Rotation(90, 0, 0)
	self._unit = World:spawn_unit(Idstring(unit_name), Vector3(), rot)

	self._unit:base():set_character_name(CriminalsManager.convert_new_to_old_character_workname("dallas"))
	self._unit:base():update_character_visuals()

	local state = self._unit:play_redirect(Idstring("idle_menu"))
	self._unit:anim_state_machine():set_parameter(state, "generic_stance", 1)

	self._unit:set_moving(true)
end

function InvIconGloves:_create_item_from_job(job, clbk)
    if job.glove_id then
        self:_create_item(job.glove_id, clbk)
    end
	return true
end

function InvIconGloves:destroy_item()
	if not alive(self._unit) then
		return
	end

	self._unit:set_slot(0)

	self._unit = nil
end

function InvIconGloves:_gloves_done(clbk)
	call_on_next_update(function ()
		if alive(self._unit) and self._unit:spawn_manager() then
			managers.menu_scene:_set_character_and_outfit_visibility(self._unit, true)

			self._parent._center_points = {
				Vector3(0, 0, 168)
			}

			self._unit:spawn_manager():remove_unit("char_mesh")
			self._unit:spawn_manager():remove_unit("char_glove_adapter")
			self:_hire_chiropractor(clbk)
		end
	end)
end

function InvIconGloves:_hire_chiropractor(clbk)
	--I'm sorry for this, this is horrible

	local left_hand = self._unit:get_object(Idstring("LeftHand"))
	local left_arm = self._unit:get_object(Idstring("LeftArm"))
	local left_forearm = self._unit:get_object(Idstring("LeftForeArm"))

	local right_arm = self._unit:get_object(Idstring("RightArm"))
	local right_forearm = self._unit:get_object(Idstring("RightForeArm"))
	local right_hand = self._unit:get_object(Idstring("RightHand"))

	if alive(left_hand) and alive(right_hand) then
		left_arm:set_rotation(Rotation(45, 0, 30))
		right_arm:set_rotation(Rotation(-45, 0, 210))
		call_on_next_update(function ()
			left_forearm:set_rotation(Rotation(0, -90, -90))
			right_forearm:set_rotation(Rotation(0, 90, 90))
			call_on_next_update(function ()
				left_hand:set_rotation(Rotation(0, -90, -90))
				right_hand:set_rotation(Rotation(0, 90, 90))
				call_on_next_update(function ()
					if clbk then
						clbk(self._unit)
					else
						self._parent:_setup_camera()
						self._parent:_update_item()
					end
				end)
			end)
		end)
	end
end

function InvIconGloves:preview_item()
	local gloves = self._gloves:SelectedItem()
	if gloves == "" then
		self:destroy_item()
	else
		self:_create_item(gloves)
	end
end

function InvIconGloves:start_item()
	local glove_id = self._gloves:SelectedItem()
	if glove_id ~= "" then
		self._parent:start_jobs({
			{
				glove_id = glove_id
			}
		})
	end
end

function InvIconGloves:unit()
    return self._unit
end

