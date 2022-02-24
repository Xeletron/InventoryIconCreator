InvIconPlayerStyle = InvIconPlayerStyle or class()
function InvIconPlayerStyle:init(parent, holder)
    self._parent = parent
	self._menu = holder:Holder({
		name = "InvIconPlayerStyle",
		auto_height = true,
        background_visible = false,
		full_bg_color = false,
		visible = false
	})

	local player_styles = self:_get_all_player_style()

	self._player_style = self._menu:ComboBox({name = "PlayerStyle", text = "Outfit ID", value = 1, items = player_styles, bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_material_variations")})
	self._material = self._menu:ComboBox({name = "MaterialVariation", text = "Material Variation", value = 1, items = self._get_all_suit_variations(player_styles[1]), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_player_style")})
	self._character_id = self._menu:ComboBox({name = "CharacterId", text = "Character ID", value = 1, items = self:_get_all_characters(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_character")})
	self._gloves = self._menu:Toggle({name = "ShowGloves", text = "Show Gloves", value = true, on_callback = ClassClbk(self, "_update_gloves")})
end

function InvIconPlayerStyle:_get_all_player_style()
	local t = clone(tweak_data.blackmarket.player_style_list)

	return t
end

function InvIconPlayerStyle:_get_all_suit_variations(player_style)
	local t = clone(managers.blackmarket:get_all_suit_variations(player_style))

	return t
end

function InvIconPlayerStyle:_get_all_characters()
	local t = {}

	for _, character in ipairs(CriminalsManager.character_names()) do
		table.insert(t, CriminalsManager.convert_old_to_new_character_workname(character))
	end

	return t
end

function InvIconPlayerStyle:_update_character(item)
	if self._parent:auto_refresh() then
		self:preview_item(true)
	end
end

function InvIconPlayerStyle:_update_material_variations(item)
	local suit_variations = self:_get_all_suit_variations(item:SelectedItem())
	self._material:SetItems(suit_variations)
	self:_update_player_style()
end

function InvIconPlayerStyle:_update_player_style(item)
	if alive(self._unit) then
		local player_style = self._player_style:SelectedItem()
		local material_variation = self._material:SelectedItem()
		self._unit:base():set_player_style(player_style, material_variation)
		self._unit:base():add_clbk_listener("done", callback(self, self, "_player_style_done"))
	end
end

function InvIconPlayerStyle:_update_gloves(item)
	if alive(self._unit) and self._unit:spawn_manager() then
		local char_gloves = self._unit:spawn_manager():get_unit("char_gloves")
		local char_glove_adapter = self._unit:spawn_manager():get_unit("char_glove_adapter")
		local visible = self._gloves:Value()

		if alive(char_gloves) then
			char_gloves:set_visible(visible)
		end
		if alive(char_glove_adapter) then
			char_glove_adapter:set_visible(visible)
		end
	end
end

function InvIconPlayerStyle:job_settings()
	return {
		distance = 4500,
		fov = 5,
		rot = Rotation(90, 0, 0),
		res = Vector3(1500, 3000, 0),
		item_rot = Rotation(-90, 0, 0)
    }
end

function InvIconPlayerStyle:_set_transparent_materials(func)
	if alive(self._unit) then
		func(self, self._unit)
    end
end

function InvIconPlayerStyle:SetEnabled(enabled)
    self._menu:SetVisible(enabled)
end

function InvIconPlayerStyle:_create_item(player_style, material_variation, character_name)
	self._parent:destroy_items()
	self:_create_character(character_name)

	self._parent._current_texture_name = player_style

	self._unit:base():set_player_style(player_style, material_variation)
	self._unit:base():add_clbk_listener("done", callback(self, self, "_player_style_done"))
	self._unit:set_visible(false)
end

function InvIconPlayerStyle:_create_character(character_name)
	local rot = Rotation(-90, 0, 0)
	local character_id = managers.blackmarket:get_character_id_by_character_name(character_name)
	local unit_name = tweak_data.blackmarket.characters[character_id].menu_unit

	--managers.dyn_resource:load(Idstring("unit"), Idstring(unit_name), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

	self._unit = World:spawn_unit(Idstring(unit_name), Vector3(), rot)

	self._unit:base():set_character_name(CriminalsManager.convert_new_to_old_character_workname(character_name))
	self._unit:base():update_character_visuals()

	local state = self._unit:play_redirect(Idstring("idle_menu"))
	self._unit:anim_state_machine():set_parameter(state, "generic_stance", 1)

	--needed otherwise it despawns on the next frame, thanks ovk
	call_on_next_update(ClassClbk(managers.menu_scene, "_set_character_and_outfit_visibility", self._unit, true))	
	self._unit:set_moving(true)
end

function InvIconPlayerStyle:_create_item_from_job(job, clbk)
    if job.player_style then
        self:_create_item(job.player_style, job.material_variation, job.character_id)
    end
end

function InvIconPlayerStyle:destroy_item()
	if not alive(self._unit) then
		return
	end

	self._unit:set_slot(0)

	self._unit = nil
end

function InvIconPlayerStyle:_player_style_done()
	call_on_next_update(function() 
		if alive(self._unit) and self._unit:spawn_manager() then
			managers.menu_scene:_set_character_and_outfit_visibility(self._unit, true)
			self:_update_gloves()
			--self._unit:spawn_manager():remove_unit("char_gloves")
			--self._unit:spawn_manager():remove_unit("char_glove_adapter")
		end
	end)
end

function InvIconPlayerStyle:preview_item()
	local player_style = self._player_style:SelectedItem()
	local material_variation = self._material:SelectedItem()
	local character_id = self._character_id:SelectedItem()
	if player_style == "" then
		self:destroy_item()
	else
		self:_create_item(player_style, material_variation, character_id)
		self._parent:_setup_camera()
		self._parent:_update_item()
	end
end

function InvIconPlayerStyle:start_item()
	local player_style = self._player_style:SelectedItem()
	local material_variation = self._material:SelectedItem()
	local character_id = self._character_id:SelectedItem()
	if player_style ~= "" then
		self._parent:start_jobs({
			{
				player_style = player_style,
				material_variation = material_variation,
				character_id = character_id
			}
		})
	end
end

function InvIconPlayerStyle:unit()
    return self._unit
end

