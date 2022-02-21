Hooks:PostHook(MenuSceneManager, "_set_up_templates", "_set_up_icon_creator_template", function(self)
	self._scene_templates.icon_creator = {
        use_character_grab = false,
        character_visible = false,
        lobby_characters_visible = false,
		show_event_units = false,
        hide_menu_logo = true,
		environment = "icon_creator",
		lights = {}
    }
end)
Hooks:PostHook(MenuSceneManager, "_set_up_environments", "_set_up_icon_creator_environment", function(self)
	self._environments.icon_creator = {
		environment = "core/environments/default",
		color_grading = "color_off",
		angle = 215
	}
end)