InvIconMelee = InvIconMelee or class()
function InvIconMelee:init(parent, holder)
    self._parent = parent
	self._menu = holder:Holder({
		name = "Melee",
		auto_height = true,
        background_visible = false,
		full_bg_color = false,
		visible = false
	})

	self._melee_id = self._menu:ComboBox({name = "MeleeId", text = "Melee ID", value = 1, items = self:_get_all_melee(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_melee")})
end

function InvIconMelee:_get_all_melee()
	local t = {""}

	for melee_id, data in pairs(tweak_data.blackmarket.melee_weapons) do
		if data.unit then
			table.insert(t, melee_id)
		end
	end

	table.sort(t)

	return t
end

function InvIconMelee:_update_melee(item)
	if self._parent:auto_refresh() then
		self:preview_item(true)
	end
end

function InvIconMelee:job_settings()
	return {
		distance = 1375,
		rot = Rotation(90, 0, 0),
		res = Vector3(2500, 1000, 0),
		fov = 4
    }
end

function InvIconMelee:_set_transparent_materials(func)
	if alive(self._unit) then
		func(self, self._unit)
    end
end

function InvIconMelee:SetEnabled(enabled)
    self._menu:SetVisible(enabled)
end

function InvIconMelee:_create_item(melee_id)
	self._parent._current_texture_name = melee_id
	local melee_unit_name = tweak_data.blackmarket.melee_weapons[melee_id].unit
	local unit_id = Idstring(melee_unit_name)

	managers.dyn_resource:load(Idstring("unit"), unit_id, DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

	if alive(self._unit) and self._unit:name() ~= unit_id then
		managers.dyn_resource:unload(Idstring("unit"), self._unit:name(), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)
	end
	self._parent:destroy_items()

	self._unit = World:spawn_unit(unit_id,  Vector3(), Rotation())

	self._unit:set_moving(true)
end

function InvIconMelee:_create_item_from_job(job, clbk)
    if job.melee_id then
        self:_create_item(job.melee_id)
    end
end

function InvIconMelee:destroy_item()
	if not alive(self._unit) then
		return
	end

	self._unit:set_slot(0)

	self._unit = nil
end

function InvIconMelee:preview_item()
	local melee_id = self._melee_id:SelectedItem()

	if melee_id == "" then
		self:destroy_item()
	else
		self:_create_item(melee_id)
		self._parent:_setup_camera()
		self._parent:_update_item()
	end
end

function InvIconMelee:start_item()
	local melee_id = self._melee_id:SelectedItem()
	if melee_id ~= "" then
		self._parent:start_jobs({
			{
				melee_id = melee_id
			}
		})
	end
end

function InvIconMelee:unit()
    return self._unit
end

