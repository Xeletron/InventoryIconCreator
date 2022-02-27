InvIconWeapons = InvIconWeapons or class()
InvIconWeapons.OPTIONAL = "<optional>"
InvIconWeapons.DEFAULT = "<default>"

function InvIconWeapons:init(parent, holder)
    self._parent = parent
	self._menu = holder:Holder({
		name = "Weapons",
		auto_height = true,
        background_visible = false,
		full_bg_color = false
	})

    self._factory_id = self._menu:ComboBox({name = "FactoryId", text = "Factory ID", value = 1, items = self:_get_all_weapons(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_factory_weapon")})
	self._skin = self._menu:ComboBox({name = "Skin", text = "Weapon Skin", value = 1, items = {"none"}, bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_set_weapon_skin")})
	self._color = self._menu:ComboBox({name = "Color", text = "Custom Color", value = 1, items = self:_get_weapon_colors(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_set_weapon_color")})
	self._quality = self._menu:ComboBox({name = "Quality", text = "Wear", value = 1, items = self:_get_weapon_qualities(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_udpate_weapon_cosmetic")})
	self._color_variation = self._menu:ComboBox({name = "ColorVariation", text = "Paint Scheme", value = 1, items = self:_get_weapon_color_variations(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_udpate_weapon_cosmetic")})
	self._pattern_scale = self._menu:ComboBox({name = "PatternScale", text = "Pattern Scale", value = 1, items = self:_get_weapon_pattern_scales(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_udpate_weapon_cosmetic")})
	self._parts = self._menu:Group({
		name = "Mods", 
		text = "Weapon Mods", 
		size = 15, 
		inherit_values = {size = 12},
		offset = 2, 
		open = true,
		auto_height = true, 
		full_bg_color = false
	})
end

function InvIconWeapons:_get_all_weapons()
	local weapons = {""}

	for _, data in pairs(Global.blackmarket_manager.weapons) do
		if data.selection_index < 3 then
			table.insert(weapons, data.factory_id)
		end
	end

	table.sort(weapons)

	return weapons
end

function InvIconWeapons:_get_weapon_skins()
	local factory_id = self._factory_id:SelectedItem()
	local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(factory_id)
	local t = {
		"none"
	}
	self._skin_ids = {
        "none"
    }

	for name, item_data in pairs(tweak_data.blackmarket.weapon_skins) do
		local match_weapon_id = not item_data.is_a_color_skin and (item_data.weapon_id or item_data.weapon_ids[1])

		if match_weapon_id == weapon_id then
			table.insert(self._skin_ids, name)
			table.insert(t, managers.localization:text(item_data.name_id))
		end
	end

	return t
end

function InvIconWeapons:_get_weapon_colors()
	self._color_ids = {}
	local t = {}

	for name, item_data in pairs(tweak_data.blackmarket.weapon_skins) do
		if item_data.is_a_color_skin then
			table.insert(self._color_ids, name)
			table.insert(t, managers.localization:text(item_data.name_id))
		end
	end

	table.insert(self._color_ids, 1, "none")
	table.insert(t, 1, "none")

	return t
end

function InvIconWeapons:_get_weapon_qualities()
	local qualities = {}
	self._quality_ids = {}

	for id, data in pairs(tweak_data.economy.qualities) do
		table.insert(qualities, {
			id = id,
			index = data.index,
			name = data.name_id
		})
	end

	table.sort(qualities, function (x, y)
		return y.index < x.index
	end)

	local t = {}

	for index, data in ipairs(qualities) do
		local name = managers.localization:text(data.name)
		table.insert(self._quality_ids, data.id)
		table.insert(t, name)
	end

	return t
end

function InvIconWeapons:_get_weapon_color_variations()
	local t = {}
	local weapon_color_variation_template = tweak_data.blackmarket.weapon_color_templates.color_variation

	for index = 1, #weapon_color_variation_template do
		local text_id = tweak_data.blackmarket:get_weapon_color_index_string(index)
		table.insert(t, managers.localization:text(text_id))
	end

	return t
end

function InvIconWeapons:_get_weapon_pattern_scales()
	local t = {}

	for index, data in ipairs(tweak_data.blackmarket.weapon_color_pattern_scales) do
		table.insert(t, managers.localization:text(data.name_id))
	end

	return t
end

function InvIconWeapons:_get_blueprint_from_ui()
	local blueprint = {}

	for _, item in pairs(self._parts:Items()) do
		local type = item:Name()
		local index = item:Value()
		if index then
			local part_id = self._parts_ids[type][index]
			if part_id ~= self.OPTIONAL then
				table.insert(blueprint, part_id)
			end
		end
    end

	return blueprint
end

function InvIconWeapons:_make_current_weapon_cosmetics()
	local skin_id = self._skin:Value()
	local skin = self._skin_ids[skin_id]
	local color_id = self._color:Value()
	local color = self._color_ids[color_id]
	local quality_id = self._quality:Value()
	local quality = self._quality_ids[quality_id]
	local color_variation = self._color_variation:Value()
	local pattern_scale = self._pattern_scale:Value()

	if skin ~= "none" then
		return self:_make_weapon_cosmetics(skin, quality)
	elseif color ~= "none" then
		return self:_make_weapon_cosmetics(color, quality, color_variation, pattern_scale)
	end

	return nil
end

function InvIconWeapons:_make_weapon_cosmetics(id, quality, color_index, pattern_scale)
	local tweak = id ~= "none" and tweak_data.blackmarket.weapon_skins[id]

	if not tweak then
		return nil
	end

	local cosmetics = {
		id = id,
		quality = quality
	}

	if tweak.is_a_color_skin then
		cosmetics.color_index = tonumber(color_index)
		cosmetics.pattern_scale = tonumber(pattern_scale)
	end

	return cosmetics
end

function InvIconWeapons:_update_factory_weapon(item)
	self:_update_weapon_parts()
	self:_update_weapon_skins()

	if self._parent:auto_refresh() then
		self:preview_item()
	end
end

function InvIconWeapons:_update_weapon_parts()
	local factory_id = self._factory_id:SelectedItem()
	self._parts_ids = {}

	self._parts:ClearItems()
	if factory_id ~= "" then

		local tb = self._parts:GetToolbar()
		tb:ImageButton({
			name = "ApplyDefault",
			texture = "guis/textures/pd2/blackmarket/inv_mod_custom",
			help = "Apply the default mods of the selected weapon",
			size = tb:H() * 0.8,
			offset = {1, 3},
			img_scale = 0.8,
			on_callback = ClassClbk(self, "_set_weapon_parts", false)
		})
		tb:ImageButton({
			name = "ApplySkin",
			texture = "guis/dlcs/wcs/textures/pd2/blackmarket/inv_mod_weaponcolor",
			help = "Apply the default mods of the selected weapon skin",
			size = tb:H() * 0.8,
			offset = {1, 3},
			img_scale = 0.8,
			enabled = false,
			on_callback = ClassClbk(self, "_set_weapon_parts", true)
		})

		local blueprint = managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)
		local parts = managers.weapon_factory:get_parts_from_factory_id(factory_id)
		local optional_types = tweak_data.weapon.factory[factory_id].optional_types or {}

		for type, options in pairs(parts) do
			local new_options = {}
			local localized_options = {}
			local default_part_id = managers.weapon_factory:get_part_id_from_weapon_by_type(type, blueprint)
	
			for _, part_id in ipairs(options) do
				local part_data = tweak_data.weapon.factory.parts[part_id]
	
				if part_data.pcs or part_data.pc or part_data.unatainable then
					local name_id = tweak_data.weapon.factory.parts[part_id].name_id
					table.insert(new_options, part_id)
					table.insert(localized_options, managers.localization:exists(name_id) and managers.localization:text(name_id) or part_id)
				end
			end
	
			if default_part_id then
				table.insert(new_options, 1, default_part_id)
				table.insert(localized_options, 1, self.DEFAULT)
			elseif #new_options > 0 then
				table.insert(new_options, 1, self.OPTIONAL)
				table.insert(localized_options, 1, self.OPTIONAL)
			end
	
			if #new_options > 0 then
				local text = managers.localization:exists("bm_menu_" .. type) and managers.localization:text("bm_menu_" .. type) or type
				local cb = self._parts:ComboBox({name = type, text = text, value = 1, items = localized_options, control_slice = 0.7, on_callback = ClassClbk(self, "_update_weapon_part")})
				self._parts_ids[type] = new_options
			end
		end
	end
end

function InvIconWeapons:_update_weapon_part(item)
	if self._parent:auto_refresh() and alive(self._unit) then
		self:preview_item()
	end
end

function InvIconWeapons:_update_weapon_skins()
	local skins = self:_get_weapon_skins()
	self._skin:SetItems(skins)
	self._skin:SetSelectedItem("none")
end

function InvIconWeapons:_udpate_weapon_cosmetic(item)
	if self._parent:auto_refresh() and alive(self._unit) then
		local weapon_skin_or_cosmetics = self:_make_current_weapon_cosmetics()
		
		local cosmetics = {}
		if type(weapon_skin_or_cosmetics) == "string" then
			cosmetics.id = weapon_skin_or_cosmetics
			cosmetics.quality = "mint"
		else
			cosmetics = weapon_skin_or_cosmetics
		end

		self._unit:base():change_cosmetics(cosmetics, function ()
			self._unit:set_moving(true)
		end)
	end
end

function InvIconWeapons:_set_weapon_skin(item)
	local weapon_skin_id = item:Value()
	local weapon_skin = self._skin_ids[weapon_skin_id]

	if weapon_skin ~= "none" then
		local apply_skin = self._parts:GetItem("ApplySkin")
		apply_skin:SetEnabled(tweak_data.blackmarket.weapon_skins[weapon_skin].default_blueprint and true or false)
	end

	self._color:SetSelectedItem("none")
	self:_udpate_weapon_cosmetic()
end

function InvIconWeapons:_set_weapon_color(item)
    local apply_skin = self._parts:GetItem("ApplySkin")
    apply_skin:SetEnabled(false)

	self._skin:SetSelectedItem("none")
	self:_udpate_weapon_cosmetic()
end

function InvIconWeapons:_set_weapon_parts(skin_defaults)
	local factory_id = self._factory_id:SelectedItem()
	if factory_id ~= "" then
		local skin_id = self._skin:Value()
		local weapon_skin = self._skin_ids[skin_id]
		local blueprint = managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)
		local skin_blueprint = skin_id > 1 and tweak_data.blackmarket.weapon_skins[weapon_skin].default_blueprint
		local parts = managers.weapon_factory:get_parts_from_factory_id(factory_id)

		for type, options in pairs(parts) do
			local default_part_id = managers.weapon_factory:get_part_id_from_weapon_by_type(type, blueprint)
			local skin_part_id
			
			if skin_defaults and skin_blueprint then
				skin_part_id = managers.weapon_factory:get_part_id_from_weapon_by_type(type, skin_blueprint)
				if skin_part_id == default_part_id then skin_part_id = nil end
			end

			local item = self._parts:GetItem(type)
			if item then
				if default_part_id or skin_part_id then
					local name_id = skin_part_id and tweak_data.weapon.factory.parts[skin_part_id].name_id or ""
					local skin_name = managers.localization:exists(name_id) and managers.localization:text(name_id) or skin_part_id
					item:SetSelectedItem(skin_part_id and skin_name or self.DEFAULT)
				else
					item:SetSelectedItem(self.OPTIONAL)
				end
			end
		end
		self:_update_weapon_part()
	end
end

function InvIconWeapons:job_settings()
	return {
        distance = 1500,
        item_rot = Rotation(180, 0, 0),
        rot = Rotation(90, 0, 0),
        res = Vector3(3000, 1000, 0)
    }
end

function InvIconWeapons:_set_transparent_materials(func)
	if alive(self._unit) then
		for part_id, part in pairs(self._unit:base()._parts) do
			func(self, part.unit)
		end
    end
end

function InvIconWeapons:SetEnabled(enabled)
    self._menu:SetVisible(enabled)
end

function InvIconWeapons:_create_item(factory_id, blueprint, weapon_skin_or_cosmetics, assembled_clbk)
	local cosmetics = {}

	if type(weapon_skin_or_cosmetics) == "string" then
		cosmetics.id = weapon_skin_or_cosmetics
		cosmetics.quality = "mint"
	else
		cosmetics = weapon_skin_or_cosmetics
	end

	self._parent._current_texture_name = factory_id .. (cosmetics and "_" .. cosmetics.id or "")
	local unit_name = tweak_data.weapon.factory[factory_id].unit
	local unit_id = Idstring(unit_name)

	if alive(self._unit) and self._unit:name() ~= unit_id then
		managers.dyn_resource:unload(Idstring("unit"), self._unit:name(), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)
	end
	self._parent:destroy_items()

	managers.dyn_resource:load(Idstring("unit"), unit_id, DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

	local rot = Rotation(180, 0, 0)
	self._ignore_first_assemble_complete = false
	self._unit = World:spawn_unit(unit_id, Vector3(), rot)

	self._unit:base():set_factory_data(factory_id)
	self._unit:base():assemble_from_blueprint(factory_id, blueprint, nil, ClassClbk(self, "_assemble_completed", {
		cosmetics = cosmetics or {},
		clbk = assembled_clbk or function ()
		end
	}))
	self._unit:set_moving(true)
	self._unit:base():_set_parts_enabled(true)
	self._unit:base():_chk_charm_upd_state()
end

function InvIconWeapons:_create_item_from_job(job, clbk)
    if job.factory_id then
        self:_create_item(job.factory_id, job.blueprint, job.weapon_skin, clbk)
    end
    return true
end

function InvIconWeapons:destroy_item()
	if not alive(self._unit) then
		return
	end

	self._unit:set_slot(0)

	self._unit = nil
end

function InvIconWeapons:_assemble_completed(data)
	if self._ignore_first_assemble_complete then
		self._ignore_first_assemble_complete = false

		return
	end

	self._unit:base():change_cosmetics(data.cosmetics, function ()
		self._unit:set_moving(true)
		call_on_next_update(function ()
			data.clbk(self._unit)
		end)
	end)
end

function InvIconWeapons:preview_item()
	local factory_id = self._factory_id:SelectedItem()
	if factory_id == "" then
		self:destroy_item()
	else
		local weapon_skin_idx = self._skin:Value()
		local weapon_skin = self._skin_ids[weapon_skin_idx]
		weapon_skin = weapon_skin ~= "none" and weapon_skin
		local blueprint = self:_get_blueprint_from_ui()
		local cosmetics = self:_make_current_weapon_cosmetics()

		self:_create_item(factory_id, blueprint, cosmetics, function() 
            self._parent:_setup_camera() 
			self._parent:_update_item()
		end)
	end
end

function InvIconWeapons:start_item()
	local factory_id = self._factory_id:SelectedItem()
	if factory_id ~= "" then
        local weapon_skin_idx = self._skin:Value()
		local weapon_skin = self._skin_ids[weapon_skin_idx]
		weapon_skin = weapon_skin ~= "none" and weapon_skin
		local blueprint = self:_get_blueprint_from_ui()
		local cosmetics = self:_make_current_weapon_cosmetics()
		
        self._parent:start_jobs({
			{
				factory_id = factory_id,
				blueprint = blueprint,
				weapon_skin = cosmetics
			}
		})
	end
end

function InvIconWeapons:unit()
    return self._unit
end

