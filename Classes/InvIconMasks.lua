InvIconMasks = InvIconMasks or class()
function InvIconMasks:init(parent, holder)
    self._parent = parent
	self._menu = holder:Holder({
		name = "Masks",
		auto_height = true,
        background_visible = false,
		full_bg_color = false,
		visible = false
	})

	local colors = self:_get_mask_colors()
    self._mask_id = self._menu:ComboBox({name = "MaskId", text = "Mask ID", value = 1, items = self:_get_all_masks(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask")})
	self._color_a = self._menu:ComboBox({name = "ColorA", text = "First Color", items = colors, bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask_blueprint")})
	self._color_b = self._menu:ComboBox({name = "ColorB", text = "Second Color", items = colors, bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask_blueprint")})
	self._material = self._menu:ComboBox({name = "Material", text = "Material", items = self:_get_mask_materials(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask_blueprint")})
	self._pattern = self._menu:ComboBox({name = "Pattern", text = "Pattern", items = self:_get_mask_patterns(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask_blueprint")})

	local reset = self._menu:Group({
		name = "Reset",
		text = "Reset Options",
		size = 15,
		inherit_values = {size = 14},
		offset = 2,
		auto_height = true,
		full_bg_color = false,
		align_method = "centered_grid"
	})

	self._strap = self._menu:Toggle({name = "Strap", text = "Back Strap", help = "Show the backside straps on normal masks", value = false, on_callback = ClassClbk(self, "_update_mask_strap")})
	reset:Button({name = "ResetAll", text = "All", size_by_text = true, on_callback = ClassClbk(self, "_reset_mask_blueprint")})
	reset:Button({name = "ResetColor1", text = "First Color", size_by_text = true, on_callback = ClassClbk(self, "_reset_mask_color", true)})
	reset:Button({name = "ResetColor2", text = "Second Color", size_by_text = true, on_callback = ClassClbk(self, "_reset_mask_color", false)})
	reset:Button({name = "ResetMaterial", text = "Material", size_by_text = true, on_callback = ClassClbk(self, "_reset_mask_material")})
	reset:Button({name = "ResetPattern", text = "Pattern", size_by_text = true, on_callback = ClassClbk(self, "_reset_mask_pattern")})
	self:_reset_mask_blueprint()
end

function InvIconMasks:_get_all_masks()
	local t = {""}

	for mask_id, data in pairs(tweak_data.blackmarket.masks) do
		if mask_id ~= "character_locked" then
			table.insert(t, mask_id)
		end
	end

	table.sort(t)

	return t
end

function InvIconMasks:_get_mask_materials()
	self._material_ids = {}
	local t = {}

	for name, item_data in pairs(tweak_data.blackmarket.materials) do
		table.insert(self._material_ids, name)
		table.insert(t, managers.localization:text(item_data.name_id))
	end

	return t
end

function InvIconMasks:_get_mask_patterns()
	self._pattern_ids = {}
	local t = {}

	for name, item_data in pairs(tweak_data.blackmarket.textures) do
		table.insert(self._pattern_ids, name)
		table.insert(t, managers.localization:text(item_data.name_id))
	end

	return t
end

function InvIconMasks:_get_mask_colors()
	self._color_ids = {}
	local t = {}

	for name, item_data in pairs(tweak_data.blackmarket.mask_colors) do
		table.insert(self._color_ids, name)
		table.insert(t, managers.localization:text(item_data.name_id))
	end
	
	return t
end

function InvIconMasks:_get_mask_blueprint_from_ui()
	local blueprint = {}

	local color_a_id = self._color_a:Value()
	local color_b_id = self._color_b:Value()
	local pattern_id = self._pattern:Value()
	local material_id = self._material:Value()

	blueprint.color_a = {id = self._color_ids[color_a_id] or "nothing"}
	blueprint.color_b = {id = self._color_ids[color_b_id] or "nothing"}
	blueprint.pattern = {id = self._pattern_ids[pattern_id] or "no_color_no_material"}
	blueprint.material = {id = self._material_ids[material_id] or "plastic"}

	return blueprint
end

function InvIconMasks:_update_mask(item)
	if self._parent:auto_refresh() then
		self:preview_item(true)
	end
end

function InvIconMasks:_update_mask_blueprint()
	if self._parent:auto_refresh() and alive(self._unit) then
		local blueprint = self:_get_mask_blueprint_from_ui()
		self._unit:base():apply_blueprint(blueprint)
	end
end

function InvIconMasks:_update_mask_strap(item)
	if alive(self._mask_backside) then
		self._mask_backside:set_visible(item:Value())
	end
end

function InvIconMasks:_reset_mask_blueprint(item)
	self:_reset_mask_color(true, nil, true)
	self:_reset_mask_color(false, nil, true)
	self:_reset_mask_material(nil, true)
	self:_reset_mask_pattern(nil, true)

	if self._parent:auto_refresh() then
		self:_update_mask_blueprint(nil, true)
	end
end

function InvIconMasks:_reset_mask_color(first, item, skip_update)
	item = first and self._color_a or self._color_b
	item:SetSelectedItem(managers.localization:text("bm_clr_nothing"))

	if not skip_update and self._parent:auto_refresh() then
		self:_update_mask_blueprint()
	end
end

function InvIconMasks:_reset_mask_material(item, skip_update)
	self._material:SetSelectedItem(managers.localization:text("bm_mtl_plastic"))

	if not skip_update and self._parent:auto_refresh() then
		self:_update_mask_blueprint()
	end
end

function InvIconMasks:_reset_mask_pattern(item, skip_update)
	self._pattern:SetSelectedItem(managers.localization:text("bm_txt_no_color_no_material"))

	if not skip_update and self._parent:auto_refresh() then
		self:_update_mask_blueprint()
	end
end

function InvIconMasks:job_settings()
	return {
		distance = 1500,
		item_rot = Rotation(90, 90, 0),
		rot = Rotation(90, 0, 0),
		res = Vector3(1000, 1000, 0)
    }
end

function InvIconMasks:_set_transparent_materials(func)
	if alive(self._unit) then
		func(self, self._unit)
    end
end

function InvIconMasks:SetEnabled(enabled)
    self._menu:SetVisible(enabled)
end

function InvIconMasks:_create_item(mask_id, blueprint)
	self._parent:destroy_items()

	self._parent._current_texture_name = mask_id
	local rot = Rotation(90, 90, 0)
	local mask_unit_name = managers.blackmarket:mask_unit_name_by_mask_id(mask_id)
	local backstrap_unit_name = Idstring("units/payday2/masks/msk_fps_back_straps/msk_fps_back_straps")

	managers.dyn_resource:load(Idstring("unit"), Idstring(mask_unit_name), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)
	managers.dyn_resource:load(Idstring("unit"), backstrap_unit_name, DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

	self._unit = World:spawn_unit(Idstring(mask_unit_name), Vector3(), rot)

	if not tweak_data.blackmarket.masks[mask_id].type then
		-- Nothing
	end

	if blueprint then
		self._unit:base():apply_blueprint(blueprint)
	end

	if not tweak_data.blackmarket.masks[mask_id].type then
		self._mask_backside = World:spawn_unit(backstrap_unit_name, Vector3(), rot)
		self._unit:link(self._unit:orientation_object():name(), self._mask_backside, self._mask_backside:orientation_object():name())
		self._mask_backside:set_visible(self._strap:Value())
	end

	self._unit:set_moving(true)
end

function InvIconMasks:_create_item_from_job(job, clbk)
    if job.mask_id then
        self:_create_item(job.mask_id, job.blueprint)
    end
end

function InvIconMasks:destroy_item()
	if not alive(self._unit) then
		return
	end

	self._unit:set_slot(0)

	self._unit = nil

	if alive(self._mask_backside) then
		self._mask_backside:set_slot(0)
		self._mask_backside = nil
	end
end

function InvIconMasks:preview_item(with_blueprint)
	local mask_id = self._mask_id:SelectedItem()
	if mask_id == "" then
		self:destroy_item()
	else
		local blueprint = with_blueprint and self:_get_mask_blueprint_from_ui() or nil
		self:_create_item(mask_id, blueprint)
		self._parent:_setup_camera()
		self._parent:_update_item()
	end
end

function InvIconMasks:start_item(with_blueprint)
	local mask_id = self._mask_id:SelectedItem()
	if mask_id ~= "" then
		local blueprint = with_blueprint and self:_get_mask_blueprint_from_ui() or nil

		self._parent:start_jobs({
			{
				mask_id = mask_id,
				blueprint = blueprint
			}
		})
	end
end

function InvIconMasks:unit()
    return self._unit
end

