InvIconCharacter = InvIconCharacter or class()
function InvIconCharacter:init(parent, holder)
    self._parent = parent
	self._menu = holder:Holder({
		name = "InvIconCharacter",
		auto_height = true,
        background_visible = false,
		full_bg_color = false,
		visible = false
	})

	self._character_id = self._menu:ComboBox({name = "CharacterId", text = "Character ID", value = 1, items = self:_get_all_characters(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_character")})
	self._anim_pose = self._menu:ComboBox({name = "AnimPose", text = "Pose", value = 1, items = self._parent:_get_all_anim_poses(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_anim_pose")})
	self._anim_pose:SetSelectedItem("generic_stance")
end

function InvIconCharacter:_get_all_characters()
	local t = {""}

	for _, character in ipairs(CriminalsManager.character_names()) do
		table.insert(t, CriminalsManager.convert_old_to_new_character_workname(character))
	end

	return t
end

function InvIconCharacter:_update_character(item)
	if self._parent:auto_refresh() then
		self:preview_item(true)
	end
end

function InvIconCharacter:_update_anim_pose(item)
	if alive(self._unit) and self._parent:auto_refresh() then
		local state = self._unit:play_redirect(Idstring("idle_menu"))
		self._unit:anim_state_machine():set_parameter(state, item:SelectedItem(), 1)
	end
end

function InvIconCharacter:job_settings()
	return {
		distance = 4500,
		fov = 5,
		rot = Rotation(90, 0, 0),
		res = Vector3(1500, 3000, 0),
		item_rot = Rotation(-90, 0, 0)
    }
end

function InvIconCharacter:_set_transparent_materials(func)
	if alive(self._unit) then
		func(self, self._unit)
    end
end

function InvIconCharacter:SetEnabled(enabled)
    self._menu:SetVisible(enabled)
end

function InvIconCharacter:_create_item(character_name, anim_pose)
	self._parent:destroy_items()

	self._parent._current_texture_name = character_name
	local rot = Rotation(-90, 0, 0)
	local character_id = managers.blackmarket:get_character_id_by_character_name(character_name)
	local unit_name = tweak_data.blackmarket.characters[character_id].menu_unit

	--managers.dyn_resource:load(Idstring("unit"), Idstring(unit_name), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

	self._unit = World:spawn_unit(Idstring(unit_name), Vector3(), rot)

	self._unit:base():set_character_name(CriminalsManager.convert_new_to_old_character_workname(character_name))
	self._unit:base():update_character_visuals()

	local state = self._unit:play_redirect(Idstring("idle_menu"))

	if anim_pose then
		self._unit:anim_state_machine():set_parameter(state, anim_pose, 1)
	end

	--needed otherwise it despawns on the next frame, fuck you ovk
	call_on_next_update(ClassClbk(managers.menu_scene, "_set_character_and_outfit_visibility", self._unit, true))	
end

function InvIconCharacter:_create_item_from_job(job, clbk)
    if job.character_id then
        self:_create_item(job.character_id, job.anim_pose)
    end
end

function InvIconCharacter:destroy_item()
	if not alive(self._unit) then
		return
	end

	self._unit:set_slot(0)

	self._unit = nil
end

function InvIconCharacter:preview_item()
	local character_id = self._character_id:SelectedItem()
	local anim_pose = self._anim_pose:SelectedItem()

	if character_id == "" then
		self:destroy_item()
	else
		self:_create_item(character_id, anim_pose)
		self._parent:_setup_camera()
		self._parent:_update_item()
	end
end

function InvIconCharacter:start_item()
	local character_id = self._character_id:SelectedItem()
	local anim_pose = self._anim_pose:SelectedItem()
	if character_id ~= "" then
		self._parent:start_jobs({
			{
				character_id = character_id,
				anim_pose = anim_pose
			}
		})
	end
end

function InvIconCharacter:unit()
    return self._unit
end

