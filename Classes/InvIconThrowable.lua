InvIconThrowable = InvIconThrowable or class()
function InvIconThrowable:init(parent, holder)
    self._parent = parent
	self._menu = holder:Holder({
		name = "Throwable",
		auto_height = true,
        background_visible = false,
		full_bg_color = false,
		visible = false
	})

	self._throwable_id = self._menu:ComboBox({name = "ThrowableId", text = "Throwable ID", value = 1, items = self:_get_all_throwable(), bigger_context_menu = true, control_slice = 0.6, on_callback = ClassClbk(self, "_update_throwable")})
end

function InvIconThrowable:_get_all_throwable()
	local t = {""}

	for throwable_id, data in pairs(tweak_data.blackmarket.projectiles) do
		if data.throwable and data.unit_dummy then
			table.insert(t, throwable_id)
		end
	end

	table.sort(t)

	return t
end

function InvIconThrowable:_update_throwable(item)
	if self._parent:auto_refresh() then
		self:preview_item(true)
	end
end

function InvIconThrowable:job_settings()
	return {
		distance = 1500,
		rot = Rotation(90, 0, 0),
		res = Vector3(2500, 1000, 0)
    }
end

function InvIconThrowable:_set_transparent_materials(func)
	if alive(self._unit) then
		func(self, self._unit)
    end
end

function InvIconThrowable:SetEnabled(enabled)
    self._menu:SetVisible(enabled)
end

function InvIconThrowable:_create_item(throwable_id)
	self._parent:destroy_items()

	self._parent._current_texture_name = throwable_id
	local throwable_unit_name = tweak_data.blackmarket.projectiles[throwable_id].unit_dummy

	managers.dyn_resource:load(Idstring("unit"), Idstring(throwable_unit_name), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

	self._unit = World:spawn_unit(Idstring(throwable_unit_name), Vector3(), Rotation())

	for _, effect_spawner in ipairs(self._unit:get_objects_by_type(Idstring("effect_spawner"))) do
		effect_spawner:set_enabled(false)
	end

	self._unit:set_moving(true)
end

function InvIconThrowable:_create_item_from_job(job, clbk)
    if job.throwable_id then
        self:_create_item(job.throwable_id)
    end
end

function InvIconThrowable:destroy_item()
	if not alive(self._unit) then
		return
	end

	self._unit:set_slot(0)

	self._unit = nil
end

function InvIconThrowable:preview_item()
	local throwable_id = self._throwable_id:SelectedItem()

	if throwable_id == "" then
		self:destroy_item()
	else
		self:_create_item(throwable_id)
		self._parent:_setup_camera()
		self._parent:_update_item()
	end
end

function InvIconThrowable:start_item()
	local throwable_id = self._throwable_id:SelectedItem()
	if throwable_id ~= "" then
		self._parent:start_jobs({
			{
				throwable_id = throwable_id
			}
		})
	end
end

function InvIconThrowable:unit()
    return self._unit
end

