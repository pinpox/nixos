local Keybind = {}

Keybind.add_global_keybinds = function(keybinds)
	for index, keybind in pairs(keybinds) do
		if(keybind[4] == nil) then
			keybind[4] = {}
		end

		vim.api.nvim_set_keymap(
			keybind[1],
			keybind[2],
			keybind[3],
			keybind[4]
		)
	end
end

Keybind.add_buffer_keybinds = function(keybinds)
	for index, keybind in pairs(keybinds) do
		if(keybind[5] == nil) then
			keybind[5] = {}
		end
		vim.api.nvim_buf_set_keymap(
			keybind[1],
			keybind[2],
			keybind[3],
			keybind[4],
			keybind[5]
		)
	end
end

Keybind.g = Keybind.add_global_keybinds
Keybind.b = Keybind.add_buffer_keybinds

return Keybind
