InvIconCreator.OPTIONAL = "<optional>"
InvIconCreator.DEFAULT = "<default>"
InvIconCreator.ANIM_POSES_PATH = "anims/units/menu_character/player_criminal/menu_criminal"
InvIconCreator.ANIM_POSES_FILE_EXTENSION = "animation_states"
InvIconCreator.ANIM_POSES_STATE_NAME = "std/stand/still/idle/menu"
local sky_rot_key = Idstring("sky_orientation/rotation"):key()

function InvIconCreator:Init()
	self.ExportPath = Path:CombineDir(self.ModPath, "export")
	if not FileIO:Exists(self.ExportPath) then
		FileIO:MakeDir(self.ExportPath)
	end
    Hooks:Add("MenuManagerPopulateCustomMenus", "InvIconCreatorSetupMenu", ClassClbk(self, "SetupMenu"))
end

function InvIconCreator:SetupMenu()
    local node = MenuHelperPlus:GetNode("menu_main", "options")
	if node then
		local menu_node = MenuHelperPlus:NewNode("menu_main", {
			name = "InventoryIconCreator"
		})
		menu_node.update = function(menu_node, t, dt) self:update(t, dt) end

		MenuCallbackHandler.InventoryIconCreator = ClassClbk(self, "set_enabled", true)
		MenuHelperPlus:AddButton({
			id = "InventoryIconCreator",
			title = "Inventory Icon Creator",
			localized = false,
			node = node,
			next_node = "InventoryIconCreator",
			callback = "InventoryIconCreator",
			position = 8
		})
	end
end

function InvIconCreator:BuildMenu()
	if self._main_menu then
		return
	end

	self._main_menu = MenuUI:new({
        name = "InventoryIcon",
        layer = 1000,
        visible = false
	})
	
--	self._menu = self._main_menu:Menu({
--        auto_foreground = true,
--		align_method = "grid",
--        background_color = Color('99333333'),
--        scrollbar = false,
--        w = 270
--	})
    local main_panel = self._main_menu:DivGroup({
        name = "MainPanel",
        text = "Inventory Icon Creator",
        scrollbar = false,
		auto_height = false,
		w = 260,
		h = self._main_menu.h,
        inherit_values = {
            size = 15,
			offset = 2,
        },
        private = {
            size = 20,
            background_color = Color('4272d9'),
            full_bg_color = Color('99333333'),
            foreground = Color.white
        }
    })
	local toolbar = main_panel:GetToolbar()
	toolbar:Button({name = "quit", text = "X", on_callback = ClassClbk(self, "hide"), text_align = "center", w = toolbar.h, size = 20})

	local h = main_panel:ItemsHeight(2) / 2

	local items = main_panel:Holder({
        name = "Items",
        scrollbar = false,
        auto_height = false,
		h = h,
		background_visible = false
    })

	self._tabs_panel = items:Holder({
        name = "ItemTabs",
        scrollbar = false,
        auto_height = true,
        align_method = "centered_grid",
		offset = {0, 2},
		background_visible = false
    })

	item_panels = items:Menu({
        name = "ItemPanels",
        scroll_width = 3,
        auto_height = false,
		stretch_to_bottom = true,
		offset = 0,
		full_bg_color = Color('99333333'),
		background_visible = false
    })

	self._item_tabs = {}
	self._ctrlrs = {
		weapon = {},
		mask = {},
		melee = {},
		throwable = {},
		character = {},
		player_style = {},
		gloves = {}
	}

	self:_create_weapons_page(item_panels, self._tabs_panel)
	self:_create_masks_page(item_panels, self._tabs_panel)
	self._tabs_panel:Button({name = "Melee", size_by_text = true})
	self._tabs_panel:Button({name = "Throwable", size_by_text = true})
	self._tabs_panel:Button({name = "Character", size_by_text = true})
	self._tabs_panel:Button({name = "Outfit", size_by_text = true})
	self._tabs_panel:Button({name = "Gloves", size_by_text = true})

	local footer = main_panel:Holder({
        name = "Footer",
        auto_height = true,
        align_method = "centered_grid",
		background_visible = false
    })
	
	footer:Button({name = "OpenExports",text = "Open Export Folder", size_by_text = true, on_callback = ClassClbk(self, "OpenExportsFolder")})
	footer:Button({name = "DestroyItems",text = "Delete items", size_by_text = true, on_callback = ClassClbk(self, "destroy_items")})
	footer:Button({name = "Refresh", size_by_text = true, on_callback = ClassClbk(self, "preview_one_item")})
	footer:Button({name = "ExportSelected", text = "Export", size_by_text = true, on_callback = ClassClbk(self, "start_one_item")})


	local settings_group = main_panel:DivGroup({
		name = "Settings",
        scroll_width = 3,
		auto_height = false,
		h = h - footer.h,
		size = 14,
		private = {
			full_bg_color = Color('99333333'),
			background_color = Color('4272d9'),
			foreground = Color.white
		}
	})

    self._backdrop_position = Vector3(-500, 0, 0)
	self._backdrop_rotation = Rotation(180, 0, -90)
	self._item_position = Vector3(0, 0, 0)
	self._item_rotation = Rotation(0, 0, 0)
	self._sky_rotation = 215

	self:_create_position_control("ItemPosition", self._item_position, settings_group, ClassClbk(self, "_update_item_position"))
	self:_create_rotation_control("ItemRotation", self._item_rotation, settings_group, ClassClbk(self, "_update_item_rotation"))
    self:_create_position_control("BackdropPosition", self._backdrop_position, settings_group, ClassClbk(self, "_update_backdrop_position"))
	self:_create_rotation_control("BackdropRotation", self._backdrop_rotation, settings_group, ClassClbk(self, "_update_backdrop_rotation"))

	self._custom_ctrlrs = {
		resolution = {}
	}
    local resoltion = settings_group:Holder({name = "CustomResoltionSize", text = false, auto_height = true, full_bg_color = false, offset = 2, inherit_values = {offset = 0}, background_visible = false, align_method = "centered_grid"})
	self._custom_ctrlrs.resolution.use = resoltion:Toggle({name = "custom_resolution", text = "Use custom resolution", help = "Export images with a custom resolution.", value = false, on_callback = ClassClbk(self, "_update_resolution_buttons")})
	self._custom_ctrlrs.resolution.width = resoltion:NumberBox({name = "custom_resolution_w", text = "Width", w = resoltion:ItemsWidth() / 2 - resoltion:OffsetX(), enabled = false, control_slice = 0.7, value = 64, min = 64, max = 8192, floats = 0})
	self._custom_ctrlrs.resolution.height = resoltion:NumberBox({name = "custom_resolution_h", text = "Height",w = resoltion:ItemsWidth() / 2 - resoltion:OffsetX(), enabled = false, control_slice = 0.7, value = 64, min = 64, max = 8192, floats = 0})
	settings_group:Slider({name = "SkyRotation", text = "Sky Rotation", value = 215, min = 0, max = 360, floats = 0, on_callback = ClassClbk(self, "_update_sky_rotation")})
end

function InvIconCreator:OpenExportsFolder(item)
	local open_path = string.gsub(self.ExportPath, "%./", "")
    open_path = string.gsub(self.ExportPath, "/", "\\")
    Application:shell_explore_to_folder(open_path)
end

function InvIconCreator:OpenItemTab(item, name)
    name = name or item:Name()
    self._current_tab = name
    for _, tab in pairs(self._tabs_panel:Items()) do
        tab:SetBorder({bottom = tab.name == item.name})
    end
    for tab_name, tab in pairs(self._item_tabs) do
        tab:SetVisible(name == tab_name)
    end
	self:destroy_items()
end

function InvIconCreator:preview_one_item()
	if self._current_tab == "Weapons" then
		self:preview_one_weapon()
	elseif self._current_tab == "Masks" then
		self:preview_one_mask(true)
	end
end

function InvIconCreator:start_one_item()
	if self._current_tab == "Weapons" then
		self:start_one_weapon()
	elseif self._current_tab == "Masks" then
		self:start_one_mask(true)
	end
end

function InvIconCreator:set_enabled(enabled)
    local opened = BeardLib.managers.dialog:DialogOpened(self)
    if enabled then
        if not opened then
			self:BuildMenu()
            BeardLib.managers.dialog:ShowDialog(self)
            self._main_menu:Enable()
        end
        self:opened()
        self._enabled = true
    elseif opened then
        BeardLib.managers.dialog:CloseDialog(self)
        self._main_menu:Disable()
        self:closed()
        self._enabled = false
    end
end

function InvIconCreator:should_close()
    return self._main_menu:ShouldClose()
end

function InvIconCreator:hide()
    self:set_enabled(false)
    managers.menu_scene:set_scene_template("standard")
    return true
end


function InvIconCreator:opened()
	managers.menu_scene:set_scene_template(nil, {
        use_character_grab = false,
        character_visible = false,
        lobby_characters_visible = false,
        character_pos = Vector3(-500, 0, -500),
        hide_menu_logo = true,
		lights = {}
    }, "icon_creator")
	

	self:setup_camera()
    self:_set_job_settings()
	self:_set_anim_poses()
    self._vp:set_active(true)
    self:toggle_menu_units(false)

    self:_create_backdrop()
end

function InvIconCreator:update(t, dt)
	if self._working_9_to_5 then
		if not self._update_time or self._update_time > 1 then
			if self._steps then
				self:_next_step()
			end

			self:check_next_job()
			self._update_time = 0
		end
		self._update_time = self._update_time + dt
	end
end

function InvIconCreator:_setup_camera(change_resolution)
	self:_set_job_settings()

	job_setting = nil

	if self._jobs[1].factory_id then
		job_setting = self._job_settings.weapon
	elseif self._jobs[1].mask_id then
		job_setting = self._job_settings.mask
	elseif self._jobs[1].melee_id then
		job_setting = self._job_settings.melee
	elseif self._jobs[1].throwable_id then
		job_setting = self._job_settings.throwable
	elseif self._jobs[1].glove_id then
		job_setting = self._job_settings.gloves
	elseif self._jobs[1].character_id then
		job_setting = self._job_settings.character
	end
	self._current_job_setting = job_setting

	--if not self._custom_ctrlrs.use_camera_setting:get_value() then
		local camera_position = Vector3(0, 0, 0)

		if self._center_points then
			for _, pos in ipairs(self._center_points) do
				mvector3.add(camera_position, pos)
			end

			mvector3.divide(camera_position, #self._center_points)

			self._center_points = nil
		else
			local oobb = (self._weapon_unit or self._mask_unit or self._melee_unit or self._throwable_unit or self._gloves_unit or self._character_unit):oobb()

			if oobb then
				camera_position = oobb:center()
			end
		end

		self._object_position = mvector3.copy(camera_position)

		mvector3.add(camera_position, job_setting.offset or Vector3(0, 0, 0))
		mvector3.set_x(camera_position, job_setting.distance)

		self._camera_position = camera_position
		self._camera_rotation = job_setting.rot
		self._camera_fov = job_setting.fov or 3

		self._camera_object:set_fov(self._camera_fov)
        self._camera_object:set_position(self._camera_position)
        self._camera_object:set_rotation(self._camera_rotation)
	--end

	if change_resolution then
		local w = job_setting.res.x
		local h = job_setting.res.y

		if self._custom_ctrlrs.resolution.use:Value() then
			w = tonumber(self._custom_ctrlrs.resolution.width:Value())
			h = tonumber(self._custom_ctrlrs.resolution.height:Value())
		end
		self._saved_resolution = RenderSettings.resolution
		self:_set_fixed_resolution(Vector3(w + 4, h + 4, 0))
	end
end

function InvIconCreator:closed()
	managers.environment_controller:set_dof_setting("standard")
	self:change_visualization("deferred_lighting")
	managers.environment_controller:set_base_chromatic_amount(self._old_data.base_chromatic_amount)
	managers.environment_controller:set_base_contrast(self._old_data.base_contrast)
	self:_destroy_backdrop()
	self:destroy_items()
    self._vp:set_active(false)
    self:toggle_menu_units(true)
    managers.menu:force_back()
end

function InvIconCreator:toggle_menu_units(visible)
	local menu_units = {
		Idstring("units/menu/menu_scene/menu_cylinder"),
        Idstring("units/menu/menu_scene/menu_cylinder_pattern"),
		Idstring("units/menu/menu_scene/menu_smokecylinder1"),
		Idstring("units/menu/menu_scene/menu_smokecylinder2"),
		Idstring("units/menu/menu_scene/menu_smokecylinder3"),
	}

	for _, unit in pairs(World:find_units_quick("all")) do 
        if table.contains(menu_units, unit:name()) then
            unit:set_visible(visible)
        end
	end

    local e_money = managers.menu_scene._bg_unit:effect_spawner(Idstring("e_money"))

	if e_money then
		e_money:set_enabled(visible)
	end
end

function InvIconCreator:setup_camera()
    if not self._vp then
        self._vp = managers.viewport:new_vp(0, 0, 1, 1, "InventoryIconCreator", 10)
        self._camera_object = World:create_camera()
        self._camera_object:set_near_range(3)
        self._camera_object:set_far_range(250000)
        self._camera_object:set_fov(1)
        self._camera_object:set_position(Vector3(4500, 0, 0))
        self._camera_object:set_rotation(Rotation(90, 0, 0))
        self._vp:set_camera(self._camera_object)
	end

	self._old_data = {
		base_chromatic_amount = managers.environment_controller:base_chromatic_amount(),
		base_contrast = managers.environment_controller:base_contrast(),
	}

	local environment = "core/environments/default"
	local color_grading = "color_off"
    if managers.viewport:default_environment() ~= environment then
		managers.viewport:preload_environment(environment)
		managers.viewport:set_default_environment(environment, nil, nil)
	end
	if managers.environment_controller:default_color_grading() ~= color_grading then
		managers.environment_controller:set_default_color_grading(color_grading, true)
		managers.environment_controller:refresh_render_settings()
	end
	managers.environment_controller:set_dof_setting("none")
	managers.environment_controller:set_base_chromatic_amount(0)
	managers.environment_controller:set_base_contrast(0)
	managers.menu_scene:_set_sky_rotation_angle(self._sky_rotation)
end

function InvIconCreator:_set_job_settings()
	self._job_settings = {
		weapon = {
			distance = 1500,
			item_rot = Rotation(180, 0, 0),
			rot = Rotation(90, 0, 0),
			res = Vector3(3000, 1000, 0)
		},
		mask = {
			distance = 1500,
			item_rot = Rotation(90, 90, 0),
			rot = Rotation(90, 0, 0),
			res = Vector3(1000, 1000, 0)
		},
		melee = {
			distance = 5500,
			rot = Rotation(90, 0, 0),
			res = Vector3(2500, 1000, 0)
		},
		throwable = {
			distance = 1500,
			rot = Rotation(90, 0, 0),
			res = Vector3(2500, 1000, 0)
		},
		character = {
			distance = 4500,
			fov = 5,
			rot = Rotation(90, 0, 0),
			res = Vector3(1500, 3000, 0)
		},
		gloves = {
			distance = 4500,
			fov = 0.6,
			rot = Rotation(90, 0, 0),
			res = Vector3(1000, 1000, 0),
			offset = Vector3(0, 0, 0)
		}
	}
end

function InvIconCreator:_set_anim_poses()
	self._anim_poses = {}

	if blt.asset_db.has_file(self.ANIM_POSES_PATH, self.ANIM_POSES_FILE_EXTENSION) then
		local node = Node.from_xml(blt.asset_db.read_file(self.ANIM_POSES_PATH, self.ANIM_POSES_FILE_EXTENSION))

		for node_child in node:children() do
			if node_child:name() == "state" and node_child:parameter("name") == self.ANIM_POSES_STATE_NAME then
				for state_data in node_child:children() do
					if state_data:name() == "param" then
						table.insert(self._anim_poses, state_data:parameter("name"))
					end
				end

				table.sort(self._anim_poses)

				return
			end
		end
	end
end

function InvIconCreator:_create_backdrop()
	self:_destroy_backdrop()

    local path = "units/test/jocke/oneplanetorulethemall"
    local ids_path = Idstring(path)
    if not BeardLib.Managers.File:Has("unit", path) then
        BeardLib.Managers.File:LoadFileFromDB("unit", path)
        BeardLib.Managers.File:LoadFileFromDB("object", path)
        BeardLib.Managers.File:LoadFileFromDB("model", path)
        BeardLib.Managers.File:LoadFileFromDB("material_config", "units/test/jocke/simple_temp")
    end

	self._backdrop = safe_spawn_unit(ids_path, self._backdrop_position, self._backdrop_rotation)
end

function InvIconCreator:_destroy_backdrop()
	if alive(self._backdrop) then
		World:delete_unit(self._backdrop)

		self._backdrop = nil
	end
end

function InvIconCreator:destroy_items()
	self:destroy_weapon()
	self:destroy_mask()
	--self:destroy_melee()
	--self:destroy_throwable()
	--self:destroy_character()
	--self:destroy_player_style()
	--self:destroy_gloves()
end

function InvIconCreator:destroy_weapon()
	if not alive(self._weapon_unit) then
		return
	end

	self._weapon_unit:set_slot(0)

	self._weapon_unit = nil
end

function InvIconCreator:destroy_mask()
	if not alive(self._mask_unit) then
		return
	end

	self._mask_unit:set_slot(0)

	self._mask_unit = nil
end

function InvIconCreator:_update_resolution_buttons(item)
    self._custom_ctrlrs.resolution.width:SetEnabled(item:Value())
    self._custom_ctrlrs.resolution.height:SetEnabled(item:Value())
end

function InvIconCreator:_create_position_control(name, default_value, panel, cb)
    local p = panel:DivGroup({name = name, text = string.pretty2(name), auto_height = true, full_bg_color = false, background_visible = false, on_callback = cb, value_type = "Vector3", align_method = "centered_grid"})
	o = {}
	default_value = default_value or Vector3()
    local toolbar = p:GetToolbar()
    toolbar:Button({name = "reset", text = "Reset", on_callback = function(item) item.parent.parent:SetValue(default_value) p:RunCallback() end, size_by_text = true})

    local controls = {"x", "y", "z"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:NumberBox({name = control:upper(), on_callback = function()
			p:RunCallback()
		end, value = default_value and default_value[control] or 0, w = (p:ItemsWidth() / 3) - p:OffsetX(), control_slice = 0.8, step = p.step})
	end

    function p:Value()
		return Vector3(items[1]:Value(), items[2]:Value(), items[3]:Value())
	end
	p.get_value = p.Value

	function p:SetValue(val, run_callback)
		items[1]:SetValue(val.x)
		items[2]:SetValue(val.y)
		items[3]:SetValue(val.z)
		if run_callback then
			self:RunCallback()
		end
	end

	function p:SetVector2()
		items[3]:SetVisible(false)
	end

	function p:SetStep(step)
		items[1].step = step
		items[2].step = step
		items[3].step = step
	end

	return p
end

function InvIconCreator:_create_rotation_control(name, default_value, panel, cb)
    local p = panel:DivGroup({name = name, text = string.pretty2(name), auto_height = true, full_bg_color = false, background_visible = false, on_callback = cb, value_type = "Rotation", align_method = "centered_grid"})
	o = {}
	default_value = default_value or Rotation()
    local toolbar = p:GetToolbar()
    toolbar:Button({name = "reset", text = "Reset", on_callback = function(item) item.parent.parent:SetValue(default_value) p:RunCallback() end, size_by_text = true})

    local controls = {"yaw", "pitch", "roll"}
	local items = {}
	for i, control in pairs(controls) do
		items[i] = p:NumberBox({name = control:sub(1, 1):upper(), on_callback = function()
			p:RunCallback()
		end, value = default_value and default_value[control](default_value) or 0, w = (p:ItemsWidth() / 3) - p:OffsetX(), control_slice = 0.8, step = p.step})
	end

	function p:Value()
		return Rotation(items[1]:Value(), items[2]:Value(), items[3]:Value())
	end
	p.get_value = p.Value

	function p:SetValue(val, run_callback)
		items[1]:SetValue(val:yaw())
		items[2]:SetValue(val:pitch())
		items[3]:SetValue(val:roll())
		if run_callback then
			self:RunCallback()
		end
	end

	function p:SetVector2()
		items[3]:SetVisible(false)
	end

	function p:SetStep(step)
		items[1].step = step
		items[2].step = step
		items[3].step = step
	end

	return p
end
function InvIconCreator:_update_backdrop_position(item)
    self._backdrop_position = item:Value()
    self._backdrop:set_position(self._backdrop_position)
end

function InvIconCreator:_update_backdrop_rotation(item)
    self._backdrop_rotation = item:Value()
    self._backdrop:set_rotation(self._backdrop_rotation)
end

function InvIconCreator:_update_item_position(item)
    self._item_position = item:Value()
	self:_update_item()
end

function InvIconCreator:_update_item_rotation(item)
    self._item_rotation = item:Value()
	self:_update_item()
end

function InvIconCreator:_update_item()
	local item = self._weapon_unit or self._mask_unit

	if alive(item) then
		local thisrot = self._item_rotation
		local itemrot = self._current_job_setting.item_rot
		local rot = Rotation(thisrot:yaw() + itemrot:yaw(), thisrot:pitch() + itemrot:pitch(), thisrot:roll() + itemrot:roll())
		item:set_position(self._item_position)
		item:set_rotation(rot)
		item:set_moving(2)
	end
end

function InvIconCreator:_update_sky_rotation(item)
	self._sky_rotation = item:Value()
	managers.menu_scene:_set_sky_rotation_angle(self._sky_rotation)
end

function InvIconCreator:_create_weapons_page(items, groups)
	groups:Button({name = "Weapons", border_bottom = true, size_by_text = true, offset = 2, on_callback = ClassClbk(self, "OpenItemTab")})
	local menu = items:Holder({
		name = "Weapons",
		auto_height = true,
        background_visible = false,
		full_bg_color = false,
		size = 15,
		offset = 2
	})
	self._item_tabs.Weapons = menu
	self._current_tab = "Weapons"

	self._ctrlrs.weapon.factory_id = menu:ComboBox({name = "FactoryId", text = "Factory ID", value = 1, items = self:_get_all_weapons(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_factory_weapon")})
	self._ctrlrs.weapon.weapon_skin = menu:ComboBox({name = "WeaponSkin", text = "Weapon Skin", value = 1, items = {"none"}, bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_set_weapon_skin")})
	self._ctrlrs.weapon.weapon_color = menu:ComboBox({name = "WeaponColor", text = "Custom Color", value = 1, items = self:_get_weapon_colors(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_set_weapon_color")})
	self._ctrlrs.weapon.weapon_quality = menu:ComboBox({name = "WeaponQuality", text = "Wear", value = 1, items = self:_get_weapon_qualities(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_set_weapon_quality")})
	self._ctrlrs.weapon.weapon_color_variation = menu:ComboBox({name = "WeaponColorVariation", text = "Paint Scheme", value = 1, items = self:_get_weapon_color_variations(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_set_weapon_color_variation")})
	self._ctrlrs.weapon.weapon_pattern_scale = menu:ComboBox({name = "WeaponPatternScale", text = "Pattern Scale", value = 1, items = self:_get_weapon_pattern_scales(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_set_weapon_pattern_scales")})

	self._ctrlrs.weapon.weapon_mods = menu:Group({
		name = "WeaponMods", 
		text = "Weapon Mods", 
		size = 15, 
		inherit_values = {size = 12},
		offset = 2, 
		open = true,
		auto_height = true, 
		full_bg_color = false
	})
	--menu:Button({name = "ExportSelected", text = "Export", size_by_text = true, on_callback = ClassClbk(self, "start_one_weapon")})
	--menu:Button({name = "Refresh", size_by_text = true, on_callback = ClassClbk(self, "preview_one_weapon")})
	
end

function InvIconCreator:_create_masks_page(items, groups)
	groups:Button({name = "Masks", size_by_text = true, offset = 2, on_callback = ClassClbk(self, "OpenItemTab")})
	local menu = items:Holder({
		name = "Masks",
		auto_height = true,
        background_visible = false,
		full_bg_color = false,
		visible = false,
		size = 15,
		offset = 2
	})
	self._item_tabs.Masks = menu

	self._ctrlrs.mask.mask_id = menu:ComboBox({name = "MaskId", text = "Mask ID", value = 1, items = self:_get_all_masks(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask")})
	self._ctrlrs.mask.color1 = menu:ComboBox({name = "Color1", text = "First Color", items = {}, bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask_blueprint")})
	self._ctrlrs.mask.color2 = menu:ComboBox({name = "Color2", text = "Second Color", items = {}, bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask_blueprint")})
	self:_get_all_mask_colors()
	self._ctrlrs.mask.material = menu:ComboBox({name = "Material", text = "Material", items = self:_get_mask_materials(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask_blueprint")})
	self._ctrlrs.mask.material:SetSelectedItem(managers.localization:text("bm_mtl_plastic"))
	self._ctrlrs.mask.pattern = menu:ComboBox({name = "Pattern", text = "Pattern", items = self:_get_mask_patterns(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_mask_blueprint")})
	self._ctrlrs.mask.pattern:SetSelectedItem(managers.localization:text("bm_txt_no_color_no_material"))
end

function InvIconCreator:_get_all_weapons()
	local weapons = {""}

	for _, data in pairs(Global.blackmarket_manager.weapons) do
		if data.selection_index < 3 then
			table.insert(weapons, data.factory_id)
		end
	end

	table.sort(weapons)

	return weapons
end

function InvIconCreator:_get_all_masks()
	local t = {""}

	for mask_id, data in pairs(tweak_data.blackmarket.masks) do
		if mask_id ~= "character_locked" then
			table.insert(t, mask_id)
		end
	end

	table.sort(t)

	return t
end

function InvIconCreator:_update_factory_weapon(item)
	self:_add_weapon_mods()
	self:_update_weapon_skins()

	self:preview_one_weapon()
end

function InvIconCreator:_update_mask(item)
	self:preview_one_mask(true)
end

function InvIconCreator:_add_weapon_mods()
	local factory_id = self._ctrlrs.weapon.factory_id:SelectedItem()
	local weapon_mods = self._ctrlrs.weapon.weapon_mods
	self._ctrlrs.weapon.weapon_mod_options = {}
	weapon_mods:ClearItems()
	if factory_id ~= "" then

		local tb = weapon_mods:GetToolbar()
		tb:ImageButton({
			name = "ApplyDefaultMods",
			texture = "guis/textures/pd2/blackmarket/inv_mod_custom",
			help = "Apply the default mods of the selected weapon",
			size = tb:H() * 0.8,
			offset = {1, 3},
			img_scale = 0.8,
			on_callback = ClassClbk(self, "_apply_weapon_parts", false)
		})
		tb:ImageButton({
			name = "ApplySkinMods",
			texture = "guis/dlcs/wcs/textures/pd2/blackmarket/inv_mod_weaponcolor",
			help = "Apply the default mods of the selected weapon skin",
			size = tb:H() * 0.8,
			offset = {1, 3},
			img_scale = 0.8,
			enabled = false,
			on_callback = ClassClbk(self, "_apply_weapon_parts", true)
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
				local cb = weapon_mods:ComboBox({name = type, text = text, value = 1, items = localized_options, control_slice = 0.7, on_callback = ClassClbk(self, "_update_weapon_part")})
				self._ctrlrs.weapon.weapon_mod_options[type] = new_options
			end
		end
	end
end

function InvIconCreator:_apply_weapon_parts(skin_defaults)
	local factory_id = self._ctrlrs.weapon.factory_id:SelectedItem()
	if factory_id ~= "" then
		local weapon_mods = self._ctrlrs.weapon.weapon_mods

		local weapon_skin_idx = self._ctrlrs.weapon.weapon_skin:Value()
		local weapon_skin = self._ctrlrs.weapon.weapon_skins[weapon_skin_idx]
		local blueprint = managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)
		local skin_blueprint = weapon_skin_idx > 1 and tweak_data.blackmarket.weapon_skins[weapon_skin].default_blueprint
		local parts = managers.weapon_factory:get_parts_from_factory_id(factory_id)

		for type, options in pairs(parts) do
			local default_part_id = managers.weapon_factory:get_part_id_from_weapon_by_type(type, blueprint)
			local skin_part_id
			
			if skin_defaults and skin_blueprint then
				skin_part_id = managers.weapon_factory:get_part_id_from_weapon_by_type(type, skin_blueprint)
				if skin_part_id == default_part_id then skin_part_id = nil end
			end

			local item = weapon_mods:GetItem(type)
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

function InvIconCreator:_update_weapon_part(item)
	if alive(self._weapon_unit) then
		self:preview_one_weapon()
	end
end

function InvIconCreator:_update_weapon_skins(menu)
	local weapon_skin = self._ctrlrs.weapon.weapon_skin
	
	local skins = self:_get_weapon_skins()
	weapon_skin:SetItems(skins)
	weapon_skin:SetSelectedItem("none")
end


function InvIconCreator:_get_weapon_skins()
	local factory_id = self._ctrlrs.weapon.factory_id:SelectedItem()
	local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(factory_id)
	local t = {
		"none"
	}
	self._ctrlrs.weapon.weapon_skins = {"none"}

	for name, item_data in pairs(tweak_data.blackmarket.weapon_skins) do
		local match_weapon_id = not item_data.is_a_color_skin and (item_data.weapon_id or item_data.weapon_ids[1])

		if match_weapon_id == weapon_id then
			local name_id = managers.localization:text(item_data.name_id)
			table.insert(self._ctrlrs.weapon.weapon_skins, name)
			table.insert(t, name_id)
		end
	end

	return t
end

function InvIconCreator:_set_weapon_skin(item)
	local weapon_color = self._ctrlrs.weapon.weapon_color
	local weapon_skin_idx = item:Value()
	local weapon_skin = self._ctrlrs.weapon.weapon_skins[weapon_skin_idx]

	if weapon_skin ~= "none" then
		local weapon_mods = self._ctrlrs.weapon.weapon_mods
		local apply_skin = weapon_mods:GetItem("ApplySkinMods")
		apply_skin:SetEnabled(tweak_data.blackmarket.weapon_skins[weapon_skin].default_blueprint and true or false)
	end

	weapon_color:SetSelectedItem("none")
	self:_udpate_weapon_cosmetic()
end

function InvIconCreator:_set_weapon_color(item)
	local weapon_skin = self._ctrlrs.weapon.weapon_skin

	weapon_skin:SetSelectedItem("none")
	self:_udpate_weapon_cosmetic()
end

function InvIconCreator:_set_weapon_color_variation()
	self:_udpate_weapon_cosmetic()
end

function InvIconCreator:_set_weapon_quality()
	self:_udpate_weapon_cosmetic()
end

function InvIconCreator:_set_weapon_pattern_scales()
	self:_udpate_weapon_cosmetic()
end

function InvIconCreator:_udpate_weapon_cosmetic()
	if alive(self._weapon_unit) then
		local weapon_skin_or_cosmetics = self:_make_current_weapon_cosmetics()
		
		local cosmetics = {}
		if type(weapon_skin_or_cosmetics) == "string" then
			cosmetics.id = weapon_skin_or_cosmetics
			cosmetics.quality = "mint"
		else
			cosmetics = weapon_skin_or_cosmetics
		end

		self._weapon_unit:base():change_cosmetics(cosmetics, function ()
			self._weapon_unit:set_moving(true)
		end)
	end
end

function InvIconCreator:_update_mask_blueprint()
	if alive(self._mask_unit) then
		local blueprint = self:_get_mask_blueprint_from_ui()
		self._mask_unit:base():apply_blueprint(blueprint)
	end
end

function InvIconCreator:_get_weapon_qualities()
	local qualities = {}
	self._ctrlrs.weapon.qualities = {}

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
		table.insert(self._ctrlrs.weapon.qualities, data.id)
		table.insert(t, name)
	end

	return t
end

function InvIconCreator:_get_weapon_colors()
	self._ctrlrs.weapon.weapon_colors = {}
	local t = {}

	for name, item_data in pairs(tweak_data.blackmarket.weapon_skins) do
		if item_data.is_a_color_skin then
			table.insert(self._ctrlrs.weapon.weapon_colors, name)
			table.insert(t, managers.localization:text(item_data.name_id))
		end
	end

	table.insert(self._ctrlrs.weapon.weapon_colors, 1, "none")
	table.insert(t, 1, "none")

	return t
end

function InvIconCreator:_get_weapon_color_variations()
	local t = {}
	local weapon_color_variation_template = tweak_data.blackmarket.weapon_color_templates.color_variation

	for index = 1, #weapon_color_variation_template do
		local text_id = tweak_data.blackmarket:get_weapon_color_index_string(index)
		table.insert(t, managers.localization:text(text_id))
	end

	return t
end

function InvIconCreator:_get_weapon_pattern_scales()
	local t = {}

	for index, data in ipairs(tweak_data.blackmarket.weapon_color_pattern_scales) do
		table.insert(t, managers.localization:text(data.name_id))
	end

	return t
end

function InvIconCreator:_get_mask_materials()
	self._ctrlrs.mask.materials = {}
	local t = {}

	for name, item_data in pairs(tweak_data.blackmarket.materials) do
		table.insert(self._ctrlrs.mask.materials, name)
		table.insert(t, managers.localization:text(item_data.name_id))
	end

	return t
end

function InvIconCreator:_get_mask_patterns()
	self._ctrlrs.mask.textures = {}
	local t = {}

	for name, item_data in pairs(tweak_data.blackmarket.textures) do
		table.insert(self._ctrlrs.mask.textures, name)
		table.insert(t, managers.localization:text(item_data.name_id))
	end

	return t
end

function InvIconCreator:_get_all_mask_colors()
	self._ctrlrs.mask.colors = {}
	local t = {}

	for name, item_data in pairs(tweak_data.blackmarket.mask_colors) do
		table.insert(self._ctrlrs.mask.colors, name)
		table.insert(t, managers.localization:text(item_data.name_id))
	end

	self._ctrlrs.mask.color1:SetItems(t)
	self._ctrlrs.mask.color2:SetItems(t)
	self._ctrlrs.mask.color1:SetSelectedItem(managers.localization:text("bm_clr_nothing"))
	self._ctrlrs.mask.color2:SetSelectedItem(managers.localization:text("bm_clr_nothing"))
end

function InvIconCreator:start_one_weapon()
	local factory_id = self._ctrlrs.weapon.factory_id:SelectedItem()
	if factory_id ~= "" then
		local weapon_skin_idx = self._ctrlrs.weapon.weapon_skin:Value()
		local weapon_skin = self._ctrlrs.weapon.weapon_skins[weapon_skin_idx]
		weapon_skin = weapon_skin ~= "none" and weapon_skin
		local blueprint = self:_get_blueprint_from_ui()
		local cosmetics = self:_make_current_weapon_cosmetics()
		self:start_jobs({
			{
				factory_id = factory_id,
				blueprint = blueprint,
				weapon_skin = cosmetics
			}
		})
	end
end

function InvIconCreator:start_one_mask(with_blueprint)
	local mask_id = self._ctrlrs.mask.mask_id:SelectedItem()
	if mask_id ~= "" then
		local blueprint = with_blueprint and self:_get_mask_blueprint_from_ui() or nil

		self:start_jobs({
			{
				mask_id = mask_id,
				blueprint = blueprint
			}
		})
	end
end

function InvIconCreator:preview_one_weapon()
	local factory_id = self._ctrlrs.weapon.factory_id:SelectedItem()
	if factory_id == "" then
		self:destroy_items()
	else
		local weapon_skin_idx = self._ctrlrs.weapon.weapon_skin:Value()
		local weapon_skin = self._ctrlrs.weapon.weapon_skins[weapon_skin_idx]
		weapon_skin = weapon_skin ~= "none" and weapon_skin
		local blueprint = self:_get_blueprint_from_ui()
		local cosmetics = self:_make_current_weapon_cosmetics()
		self._jobs = {{factory_id = factory_id, blueprint = blueprint, weapon_skin = cosmetics}}
		self:_create_weapon(factory_id, blueprint, cosmetics, function() 
			self:_setup_camera() 
			self:_update_item()
		end)
	end
end

function InvIconCreator:preview_one_mask(with_blueprint)
	local mask_id = self._ctrlrs.mask.mask_id:SelectedItem()
	if mask_id == "" then
		self:destroy_items()
	else
		local blueprint = with_blueprint and self:_get_mask_blueprint_from_ui() or nil
		self._jobs = {{mask_id = mask_id, blueprint = blueprint}}

		self:_create_mask(mask_id, blueprint)
		self:_setup_camera() 
	end
end

function InvIconCreator:start_jobs(jobs)
	self._working_9_to_5 = true
	self._current_job = 0
	self._jobs = jobs
end

function InvIconCreator:_start_job()
	self._has_job = true
	local job = self._jobs[self._current_job]

	if job.factory_id then
		self:_create_weapon(job.factory_id, job.blueprint, job.weapon_skin, ClassClbk(self, "start_create"))
	elseif job.mask_id then
		self:_create_mask(job.mask_id, job.blueprint)
	elseif job.melee_id then
		self:_create_melee(job.melee_id)
	elseif job.throwable_id then
		self:_create_throwable(job.throwable_id)
	elseif job.player_style then
		self:_create_player_style(job.player_style, job.material_variation, job.character_id, job.anim_pose)
	elseif job.glove_id then
		self:_create_gloves(job.glove_id, job.character_id, job.anim_pose)
	elseif job.character_id then
		self:_create_character(job.character_id, job.anim_pose)
	end

	if not self._wait_for_assemble then
		self:start_create()
	end
end

function InvIconCreator:start_create()
	self._wait_for_assemble = nil

	if not self._has_job then
		return
	end
	self:_setup_camera(true)
	self:_update_item()
	self:_create_backdrop()
	--managers.editor:enable_all_post_effects()
	self._vp:vp():set_post_processor_effect("World", Idstring("hdr_post_processor"), Idstring("empty"))
	self._vp:vp():set_post_processor_effect("World", Idstring("bloom_combine_post_processor"), Idstring("bloom_combine_empty"))
	managers.environment_controller:set_ao_setting("off", self._vp:vp())
	managers.environment_controller:set_aa_setting("off", self._vp:vp())
	managers.environment_controller:set_dof_setting("none")
	managers.environment_controller:set_base_chromatic_amount(0)
	managers.environment_controller:set_base_contrast(0)
	World:effect_manager():set_rendering_enabled(false)

	self._hidden_ws = {}
	for _,ws in pairs(Overlay:gui():workspaces()) do
		self._hidden_ws[ws] = ws:visible()
		ws:hide()
	end

	self._steps = {}
	self._current_step = 0

	table.insert(self._steps, callback(self, self, "_take_screen_shot_1"))
	table.insert(self._steps, callback(self, self, "_pre_screen_shot_2"))
	table.insert(self._steps, callback(self, self, "_take_screen_shot_2"))
	table.insert(self._steps, callback(self, self, "end_create"))
end

function InvIconCreator:end_create()
	self:change_visualization("deferred_lighting")
	self._vp:vp():set_post_processor_effect("World", Idstring("hdr_post_processor"), Idstring(managers.user:get_setting("light_adaption") and "default" or "no_light_adaption"))
	self._vp:vp():set_post_processor_effect("World", Idstring("bloom_combine_post_processor"), Idstring("bloom_combine"))
	managers.environment_controller:set_ao_setting(managers.user:get_setting("video_ao"), self._vp:vp())
	managers.environment_controller:set_aa_setting(managers.user:get_setting("video_aa"), self._vp:vp())
	managers.environment_controller:set_dof_setting("standard")
	self:_set_fixed_resolution(self._saved_resolution)
	managers.environment_controller:set_base_chromatic_amount(self._old_data.base_chromatic_amount)
	managers.environment_controller:set_base_contrast(self._old_data.base_contrast)
	World:effect_manager():set_rendering_enabled(true)
	self._backdrop:set_visible(true)

	for _,ws in pairs(Overlay:gui():workspaces()) do
		if self._hidden_ws[ws] == true then
			ws:show()
		end
	end
	self._hidden_ws = nil

	self._has_job = false
end

function InvIconCreator:change_visualization(viz)
	for _, vp in ipairs(managers.viewport:viewports()) do
		vp:set_visualization_mode(viz)
	end
end

function InvIconCreator:_set_fixed_resolution(size)
    Application:set_mode(size.x, size.y, false, -1, false, true)
	managers.viewport:set_aspect_ratio2(size.x / size.y)

	if managers.viewport then
		managers.viewport:resolution_changed()
	end

end

function InvIconCreator:check_next_job()
	if self._has_job then
		return
	end
	self._current_job = self._current_job + 1

	if self._current_job > #self._jobs then
		self._working_9_to_5 = false

		return
	end

	self:_start_job()
end

function InvIconCreator:_next_step()
	self._current_step = self._current_step + 1

	if self._current_step > #self._steps then
		return
	end

	local func = self._steps[self._current_step]

	func()
end

function InvIconCreator:_take_screen_shot_1()
	local name = self._current_texture_name .. "_dif.tga"
	local path = self.ExportPath

	Application:screenshot(path .. name)
end

function InvIconCreator:_pre_screen_shot_2()
	--managers.editor:on_post_processor_effect("empty")
	self:change_visualization("depth_visualization")
	self._backdrop:set_visible(false)
end

function InvIconCreator:_take_screen_shot_2()
	local name = self._current_texture_name .. "_dph.tga"
	local path = self.ExportPath

	Application:screenshot(path .. name)
end

function InvIconCreator:_get_blueprint_from_ui()
	local blueprint = {}

	for _, item in pairs(self._ctrlrs.weapon.weapon_mods:Items()) do
		local type = item:Name()
		local index = item:Value()
		if index then
			local part_id = self._ctrlrs.weapon.weapon_mod_options[type][index]
			if part_id ~= self.OPTIONAL then
				table.insert(blueprint, part_id)
			end
		end
    end

	return blueprint
end

function InvIconCreator:_get_mask_blueprint_from_ui()
	local blueprint = {}

	local color_a_idx = self._ctrlrs.mask.color1:Value()
	local color_b_idx = self._ctrlrs.mask.color2:Value()
	local pattern_idx = self._ctrlrs.mask.pattern:Value()
	local material_idx = self._ctrlrs.mask.material:Value()

	blueprint.color_a = {id = self._ctrlrs.mask.colors[color_a_idx] or "nothing"}
	blueprint.color_b = {id = self._ctrlrs.mask.colors[color_b_idx] or "nothing"}
	blueprint.pattern = {id = self._ctrlrs.mask.textures[pattern_idx] or "no_color_no_material"}
	blueprint.material = {id = self._ctrlrs.mask.materials[material_idx] or "plastic"}

	return blueprint
end

function InvIconCreator:_create_weapon(factory_id, blueprint, weapon_skin_or_cosmetics, assembled_clbk)
	self:destroy_items()

	local cosmetics = {}

	if type(weapon_skin_or_cosmetics) == "string" then
		cosmetics.id = weapon_skin_or_cosmetics
		cosmetics.quality = "mint"
	else
		cosmetics = weapon_skin_or_cosmetics
	end

	self._current_texture_name = factory_id .. (cosmetics and "_" .. cosmetics.id or "")
	local unit_name = tweak_data.weapon.factory[factory_id].unit

	managers.dyn_resource:load(Idstring("unit"), Idstring(unit_name), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

	local rot = Rotation(180, 0, 0)
	self._wait_for_assemble = true
	self._ignore_first_assemble_complete = false
	self._weapon_unit = World:spawn_unit(Idstring(unit_name), Vector3(), rot)

	self._weapon_unit:base():set_factory_data(factory_id)
	self._weapon_unit:base():assemble_from_blueprint(factory_id, blueprint, nil, ClassClbk(self, "_assemble_completed", {
		cosmetics = cosmetics or {},
		clbk = assembled_clbk or function ()
		end
	}))
	self._weapon_unit:set_moving(true)
	self._weapon_unit:base():_set_parts_enabled(true)
	self._weapon_unit:base():_chk_charm_upd_state()
end

function InvIconCreator:_create_mask(mask_id, blueprint)
	self:destroy_items()

	self._current_texture_name = mask_id
	local rot = Rotation(90, 90, 0)
	local mask_unit_name = managers.blackmarket:mask_unit_name_by_mask_id(mask_id)

	managers.dyn_resource:load(Idstring("unit"), Idstring(mask_unit_name), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

	self._mask_unit = World:spawn_unit(Idstring(mask_unit_name), Vector3(), rot)

	if not tweak_data.blackmarket.masks[mask_id].type then
		-- Nothing
	end

	if blueprint then
		self._mask_unit:base():apply_blueprint(blueprint)
	end

	self._mask_unit:set_moving(true)
end

function InvIconCreator:_assemble_completed(data)
	if self._ignore_first_assemble_complete then
		self._ignore_first_assemble_complete = false

		return
	end
	self._weapon_unit:base():change_cosmetics(data.cosmetics, function ()
		self._weapon_unit:set_moving(true)
		call_on_next_update(function ()
			data.clbk(self._weapon_unit)
		end)
	end)
end

function InvIconCreator:_make_current_weapon_cosmetics()
	local weapon_skin_idx = self._ctrlrs.weapon.weapon_skin:Value()
	local weapon_skin = self._ctrlrs.weapon.weapon_skins[weapon_skin_idx]
	local weapon_color_idx = self._ctrlrs.weapon.weapon_color:Value()
	local weapon_color = self._ctrlrs.weapon.weapon_colors[weapon_color_idx]
	local quality_idx = self._ctrlrs.weapon.weapon_quality:Value()
	local quality = self._ctrlrs.weapon.qualities[quality_idx]
	local color_index = self._ctrlrs.weapon.weapon_color_variation:Value()
	local pattern_scale = self._ctrlrs.weapon.weapon_pattern_scale:Value()

	if weapon_skin ~= "none" then
		return self:_make_weapon_cosmetics(weapon_skin, quality)
	elseif weapon_color ~= "none" then
		return self:_make_weapon_cosmetics(weapon_color, quality, color_index, pattern_scale)
	end

	return nil
end

function InvIconCreator:_make_weapon_cosmetics(id, quality, color_index, pattern_scale)
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


