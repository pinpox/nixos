#! /usr/bin/env lua

local M = {}

-- Luafilesystem allows to iterate over a directory.
local Lfs = require "lfs"

-- for each filename in the directory
for filename in Lfs.dir "./generators/" do
	-- if it is a file
	if Lfs.attributes ("./generators/" .. filename, "mode") == "file" then
		-- transform the filename into a module name
		local name = "generators/" .. filename
		name = name:sub (1, #name-4)
		name = name:gsub ("/", ".")
		print(name)
		-- and require it
		M[name] = require (name)
	end
end

return M
