InvIconCreator.ANIM_POSES_PATH = "anims/units/menu_character/player_criminal/menu_criminal"
InvIconCreator.ANIM_POSES_FILE_EXTENSION = "animation_states"
InvIconCreator.ANIM_POSES_STATE_NAME = "std/stand/still/idle/menu"
local sky_rot_key = Idstring("sky_orientation/rotation"):key()

function InvIconCreator:Init()
	self.ExportPath = Path:CombineDir(self.ModPath, "Export")
	if not FileIO:Exists(self.ExportPath) then
		FileIO:MakeDir(self.ExportPath)
	end
	self:_set_anim_poses()
    Hooks:Add("MenuManagerPopulateCustomMenus", "InvIconCreatorSetupMenu", ClassClbk(self, "SetupMenu"))
end

function InvIconCreator:SetupMenu()
    local node = MenuHelperPlus:GetNode("menu_main", "options")
	if node then
		local menu_node = MenuHelperPlus:NewNode("menu_main", {
			name = "InventoryIconCreator"
		})

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
	
    local main_panel = self._main_menu:DivGroup({
        name = "MainPanel",
        text = "Inventory Icon Creator",
        scrollbar = false,
		auto_height = false,
		w = 260,
		h = self._main_menu.h,
        inherit_values = {
			scroll_color = Color.white,
            size = 15,
			offset = 2,
        },
        private = {
            size = 20,
            background_color = tweak_data.screen_colors.button_stage_3,
            full_bg_color = Color(0.4, 0, 0, 0),
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

	self._tabs_holder = items:Holder({
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
		full_bg_color = Color(0.5, 0.2, 0.2, 0.2),
		inherit_values = {
			scroll_color = Color.white,
			size = 15,
			offset = 2
		},
		background_visible = false
    })

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
			full_bg_color = Color(0.5, 0.2, 0.2, 0.2),
			background_color = tweak_data.screen_colors.button_stage_3,
			foreground = Color.white
		}
	})

    self._backdrop_position = Vector3(-500, 0, 0)
	self._backdrop_rotation = Rotation(180, 0, -90)
	self._item_position = Vector3(0, 0, 0)
	self._item_rotation = Rotation(0, 0, 0)
	self._sky_rotation = 215
	self._custom_ctrlrs = {
		resolution = {},
		light = {}
	}

	self._custom_ctrlrs.auto_refresh = settings_group:Toggle({name = "AutoRefresh", text = "Automatic Refresh", help = "Automatically refresh the spawned items every time an option changes", value = true})
	self:_create_position_control("ItemPosition", self._item_position, settings_group, ClassClbk(self, "_update_item_position"))
	self:_create_rotation_control("ItemRotation", self._item_rotation, settings_group, ClassClbk(self, "_update_item_rotation"))
	local lights = settings_group:Group({
		name = "LightSettings", 
		text = "Custom Light Source", 
		size = 15, 
		inherit_values = {size = 12},
		offset = 2, 
		closed = true,
		auto_height = true, 
		full_bg_color = false
	})

	self._custom_ctrlrs.light.use = lights:Toggle({name = "UseLight", text = "Use custom light source", value = false, on_callback = ClassClbk(self, "_update_light")})
	self._custom_ctrlrs.light.position = self:_create_position_control("LightPosition", self._light_position, lights, ClassClbk(self, "_update_light_position"))
	self._custom_ctrlrs.light.range = lights:NumberBox({name = "LightFarRange", text = "Light Far Range", value = 300, on_callback = ClassClbk(self, "_update_light_range")})
	self._custom_ctrlrs.light.color = lights:ColorTextBox({name = "LightColor", text = "Light Color", value = Vector3(1,1,1), on_callback = ClassClbk(self, "_update_light_color")})
	self._custom_ctrlrs.light.intensity = lights:Slider({name = "Intensity", value = 1, min = 0, max = 50, floats = 0, on_callback = ClassClbk(self, "_update_light_intensity")})
	self._custom_ctrlrs.light.debug = lights:Toggle({name = "LightDebug", text = "Light Debug", value = false})
	settings_group:Slider({name = "SkyRotation", text = "Sky Rotation", value = 215, min = 0, max = 360, floats = 0, on_callback = ClassClbk(self, "_update_sky_rotation")})
    self:_create_position_control("BackdropPosition", self._backdrop_position, settings_group, ClassClbk(self, "_update_backdrop_position"))
	self:_create_rotation_control("BackdropRotation", self._backdrop_rotation, settings_group, ClassClbk(self, "_update_backdrop_rotation"))

    local resoltion = settings_group:Holder({name = "CustomResoltionSize", text = false, auto_height = true, full_bg_color = false, offset = 2, inherit_values = {offset = 0}, background_visible = false, align_method = "centered_grid"})
	self._custom_ctrlrs.resolution.use = resoltion:Toggle({name = "custom_resolution", text = "Use custom resolution", help = "Export images with a custom resolution.", value = false, on_callback = ClassClbk(self, "_update_resolution_buttons")})
	self._custom_ctrlrs.resolution.width = resoltion:NumberBox({name = "custom_resolution_w", text = "Width", w = resoltion:ItemsWidth() / 2 - resoltion:OffsetX(), enabled = false, control_slice = 0.7, value = 64, min = 64, max = 8192, floats = 0})
	self._custom_ctrlrs.resolution.height = resoltion:NumberBox({name = "custom_resolution_h", text = "Height",w = resoltion:ItemsWidth() / 2 - resoltion:OffsetX(), enabled = false, control_slice = 0.7, value = 64, min = 64, max = 8192, floats = 0})

	self._items = {
		Weapons = InvIconWeapons:new(self, item_panels),
		Masks = InvIconMasks:new(self, item_panels),
		Melee = InvIconMelee:new(self, item_panels),
		Throwable = InvIconThrowable:new(self, item_panels),
		Character = InvIconCharacter:new(self, item_panels),
		Outfit = InvIconPlayerStyle:new(self, item_panels),
		Gloves = InvIconGloves:new(self, item_panels)
	}

	local item_tabs = {"Weapons", "Masks", "Melee", "Throwable", "Character", "Outfit", "Gloves"}
	for _, tab_name in ipairs(item_tabs) do
        self._tabs_holder:Button({name = tab_name, text = string.pretty2(tab_name), size_by_text = true, offset = 2, on_callback = ClassClbk(self, "OpenItemTab")})
    end
	self:OpenItemTab(nil, "Weapons")

end

function InvIconCreator:OpenExportsFolder(item)
	local open_path = string.gsub(self.ExportPath, "%./", "")
    open_path = string.gsub(self.ExportPath, "/", "\\")
    Application:shell_explore_to_folder(open_path)
end

function InvIconCreator:OpenItemTab(item, name)
    name = name or item:Name()
    self._current_tab = name
    for _, tab in pairs(self._tabs_holder:Items()) do
        tab:SetBorder({bottom = tab.name == name})
    end

    for tab_name, tab in pairs(self._items) do
        tab:SetEnabled(name == tab_name)
    end

	if self._custom_ctrlrs.auto_refresh:Value() then
		self:destroy_items()
		self:preview_one_item()
	end
end

function InvIconCreator:preview_one_item()
	if self._has_job then
		return
	end
	
	self:current_tab():preview_item()
end

function InvIconCreator:start_one_item()
	if self._has_job then
		return
	end

	self:current_tab():start_item()
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
	if self._has_job then
		return false
	end
    return self._main_menu:ShouldClose()
end

function InvIconCreator:hide()
    self:set_enabled(false)
    managers.menu_scene:set_scene_template("standard")
    return true
end


function InvIconCreator:opened()
	managers.menu_scene:set_scene_template("icon_creator")

	self:setup_camera()
    self._vp:set_active(true)
	DelayedCalls:Add("InvCreatorToggleUnits", 0.01, ClassClbk(self, "toggle_menu_units", false))
	self:_create_light()

    self:_create_backdrop()
end

function InvIconCreator:Update(t, dt)
	if not self._update_time or self._update_time > 0.1 then
		if self._steps then
			self:_next_step()
		end
		self._update_time = 0
	end
	self._update_time = self._update_time + dt
	self:check_next_job()
end

function InvIconCreator:UpdateDebug(t, dt)
	if self._has_job then
		return
	end

	if not self._brush then
		self._brush = Draw:brush(Color.white:with_alpha(0.3))
	end

	if self._custom_ctrlrs.light.use:Value() and self._custom_ctrlrs.light.debug:Value() then
		self._brush:sphere(self._custom_ctrlrs.light.position:Value(), 1, 2)
	end
end


function InvIconCreator:_setup_camera(change_resolution)
	--	self._job_settings = {
--		weapon = {
--			distance = 1500,
--			item_rot = Rotation(180, 0, 0),
--			rot = Rotation(90, 0, 0),
--			res = Vector3(3000, 1000, 0)
--		},
--		mask = {
--			distance = 1500,
--			item_rot = Rotation(90, 90, 0),
--			rot = Rotation(90, 0, 0),
--			res = Vector3(1000, 1000, 0)
--		},
--		melee = {
--			distance = 1375,
--			rot = Rotation(90, 0, 0),
--			res = Vector3(2500, 1000, 0),
--			fov = 4
--		},
--		throwable = {
--			distance = 1500,
--			rot = Rotation(90, 0, 0),
--			res = Vector3(2500, 1000, 0)
--		},
--		character = {
--			distance = 4500,
--			fov = 5,
--			rot = Rotation(90, 0, 0),
--			res = Vector3(1500, 3000, 0)
--		},
--		gloves = {
--			distance = 4500,
--			fov = 0.6,
--			rot = Rotation(90, 0, 0),
--			res = Vector3(1000, 1000, 0),
--			offset = Vector3(0, 0, 0)
--		}
--	}
	local job_setting = self:current_tab():job_settings()
	self._current_job_setting = job_setting

		local camera_position = Vector3(0, 0, 0)

	if self._center_points then
		for _, pos in ipairs(self._center_points) do
			mvector3.add(camera_position, pos)
		end

		mvector3.divide(camera_position, #self._center_points)

		self._center_points = nil
	else
		local oobb = self:current_tab():unit():oobb()

		if oobb then
			camera_position = oobb:center()
		end
	end

	self._object_position = mvector3.copy(camera_position)

	mvector3.add(camera_position, job_setting.offset or Vector3(0, 0, 0))
	mvector3.set_x(camera_position, job_setting.distance)

	self._camera_position = camera_position
	self._camera_rotation = job_setting.rot or Rotation()
	self._camera_fov = job_setting.fov or 3

	self._camera_object:set_fov(self._camera_fov)
	self._camera_object:set_position(self._camera_position)
	self._camera_object:set_rotation(self._camera_rotation)

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
	self:_delete_light()
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
	managers.menu_scene._menu_logo:set_visible(visible)
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

	managers.environment_controller:set_dof_setting("none")
	managers.environment_controller:set_base_chromatic_amount(0)
	managers.environment_controller:set_base_contrast(0)
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
	for _, tab in pairs(self._items) do
		tab:destroy_item()
	end
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

function InvIconCreator:auto_refresh()
	return self._custom_ctrlrs.auto_refresh:Value()
end

function InvIconCreator:_update_item()
	local item = self:current_tab():unit()

	if alive(item) then
		local thisrot = self._item_rotation
		local itemrot = self._current_job_setting.item_rot or Rotation()
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

function InvIconCreator:_create_light()
	self._light = self._light or World:create_light("omni|specular")
	self._light:set_far_range(self._custom_ctrlrs.light.range:Value())
	self._light:set_color(self._custom_ctrlrs.light.color:Value())
	self._light:set_position(self._custom_ctrlrs.light.position:Value())
	self:_update_light(self._custom_ctrlrs.light.use)
	self._light:set_specular_multiplier(4)

	BeardLib:AddUpdater("InvIconCreatorDebug", ClassClbk(self, "UpdateDebug"), true)
end

function InvIconCreator:_update_light(item)
	local enabled = item:Value()
	self._custom_ctrlrs.light.position:SetEnabled(enabled)
	self._custom_ctrlrs.light.range:SetEnabled(enabled)
    self._custom_ctrlrs.light.color:SetEnabled(enabled)
	self._custom_ctrlrs.light.debug:SetEnabled(enabled)
	self._light:set_multiplier(enabled and self._custom_ctrlrs.light.intensity:Value() or 0)
end

function InvIconCreator:_update_light_position(item)
	self._light:set_position(item:Value())
end

function InvIconCreator:_update_light_range(item)
	self._light:set_far_range(item:Value())
end

function InvIconCreator:_update_light_color(item)
	local color = item:Value()
	self._light:set_color(color)
	if self._brush then
		self._brush:set_color(color:with_alpha(0.3))
	end
end

function InvIconCreator:_update_light_intensity(item)
	local intensity = item:Value()
	self._light:set_multiplier(intensity)
end

function InvIconCreator:_delete_light()
	self._light:set_multiplier(0)
	BeardLib:RemoveUpdater("InvIconCreatorDebug")
end

function InvIconCreator:start_jobs(jobs)
	self._current_job = 0
	self._jobs = jobs

	BeardLib:AddUpdater("InvIconCreator", ClassClbk(self, "Update"), true)
end

function InvIconCreator:_start_job()
	self._has_job = true

	local job = self._jobs[self._current_job]
	
	if job.factory_id then
		--	self:_create_weapon(job.factory_id, job.blueprint, job.weapon_skin, ClassClbk(self, "start_create"))
		elseif job.mask_id then
		--	self:_create_mask(job.mask_id, job.blueprint)
		elseif job.melee_id then
		--	self:_create_melee(job.melee_id)
		elseif job.throwable_id then
		--	self:_create_throwable(job.throwable_id)
		elseif job.player_style then
		--	self:_create_player_style(job.player_style, job.material_variation, job.character_id, job.anim_pose)
		elseif job.glove_id then
		--	self:_create_gloves(job.glove_id, job.character_id, job.anim_pose)
		elseif job.character_id then
		--	self:_create_character(job.character_id, job.anim_pose)
		end

	self._wait_for_assemble = self:current_tab():_create_item_from_job(job, ClassClbk(self, "start_create"))

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
	self._main_menu:GetItem("MainPanel"):SetEnabled(false)

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

	for _,ws in pairs(Overlay:gui():workspaces()) do
		if self._hidden_ws[ws] == true then
			ws:show()
		end
	end
	managers.mouse_pointer:enable()

	self._hidden_ws = nil
	self._has_job = false
	self:preview_one_item()
	self._backdrop:set_visible(true)
	self._main_menu:GetItem("MainPanel"):SetEnabled(true)
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
		BeardLib:RemoveUpdater("InvIconCreator")
		self._update_time = nil

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

	managers.mouse_pointer:disable()
	Application:screenshot(path .. name)
end

function InvIconCreator:_pre_screen_shot_2()
	--managers.editor:on_post_processor_effect("empty")
	self:change_visualization("depth_visualization")
	self:change_transparent_materials()
	self._backdrop:set_visible(false)
end

function InvIconCreator:_take_screen_shot_2()
	local name = self._current_texture_name .. "_dph.tga"
	local path = self.ExportPath

	Application:screenshot(path .. name)
end

function InvIconCreator:change_transparent_materials()
	self:current_tab():_set_transparent_materials(self._switch_transparent_material)
end

local white_texture = Idstring("units/white_df")
function InvIconCreator:_switch_transparent_material(unit)
	local materials = unit:get_objects_by_type(Idstring("material"))
	for _, m in ipairs(materials) do
		if m:variable_exists(Idstring("fresnel_settings")) then

			--this is really stupid
			Application:set_material_texture(m, Idstring("diffuse_texture"), white_texture, Idstring("normal"), 0)
			Application:set_material_texture(m, Idstring("opacity_texture"), white_texture, Idstring("normal"), 0)
		end
	end
end

function InvIconCreator:_create_character(character_name, anim_pose)
	self._items.Character:_create_item(character_name, anim_pose)
end

function InvIconCreator:current_tab()
	return self._items[self._current_tab]
end

function InvIconCreator:_get_all_anim_poses()
	return self._anim_poses
end


