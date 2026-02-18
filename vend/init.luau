local fs = require("@std/fs")
local toml = require("@self/toml")
local glob = require("@self/glob")
local rmdir = require("@self/rmdir")

-- Hack; TOML batteries library treats arrays as strings, so we need
-- to split it manually
local function toml_array(value: string): { string }
	local result = {}
	for glob_string in string.gmatch(value, '"([^"]*)"') do
		table.insert(result, glob_string)
	end
	return result
end

local function vend(main_toml_path: string)
	local parent_path = string.gsub(main_toml_path, "/[^/]+$", "")
	local locations_of_packages = { main_toml_path }

	-- Workspaces: find all members
	local main_toml = toml.deserialize(fs.readfiletostring(main_toml_path))
	if main_toml.workspace then
		table.clear(locations_of_packages)
		for _, glob_string in toml_array(main_toml.workspace.members) do
			for _, path in glob(parent_path .. "/" .. glob_string) do
				table.insert(locations_of_packages, path)
			end
		end
	end

	-- Create a directory just for us
	local vend_path = parent_path .. "/.vending-machine"
	pcall(rmdir, vend_path)
	fs.createdirectory(vend_path)

	-- Create a "virtual package" representing the external consumer.
	local rotriever_toml = [[
[package]
name = "VendingMachine"
files = []
publish = false

[dependencies]
]]
	for index, path in locations_of_packages do
		rotriever_toml ..= "test" .. index .. ' = { path = "../' .. path .. '" }\n'
	end
	fs.writestringtofile(vend_path .. "/rotriever.toml", rotriever_toml)
end

vend("./example/single-package/rotriever.toml")
vend("./example/workspace/rotriever.toml")
