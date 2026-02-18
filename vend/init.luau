local fs = require("@std/fs")
local path = require("@std/path")
local process = require("@std/process")
local toml = require("@self/toml")
local glob = require("@self/glob")

-- Hack; TOML batteries library treats arrays as strings, so we need
-- to split it manually
local function toml_array(value: string): { string }
	local result = {}
	for glob_string in string.gmatch(value, '"([^"]*)"') do
		table.insert(result, glob_string)
	end
	return result
end

local function vend(main_toml_path: path.path)
	local parent_path = path.dirname(main_toml_path)
	local locations_of_packages = { main_toml_path }

	-- Workspaces: find all members
	local main_toml = toml.deserialize(fs.readfiletostring(main_toml_path))
	if main_toml.workspace then
		table.clear(locations_of_packages)
		for _, glob_string in toml_array(main_toml.workspace.members) do
			for _, globbed in glob(path.join(parent_path, glob_string)) do
				table.insert(locations_of_packages, path.normalize(globbed))
			end
		end
	end

	-- Create a directory just for us
	local vend_path = path.join(process.homedir(), ".vending-machine")
	pcall(fs.removedirectory, vend_path, { recursive = true })
	fs.createdirectory(vend_path)

	-- Create a "virtual package" representing the external consumer.
	local rotriever_toml = [[
[package]
name = "VendingMachine"
version = "1.0.0"
files = []
publish = false

[config]
registry_index = true

[dependencies]
]]
	for index, location in locations_of_packages do
		rotriever_toml ..= "test" .. index .. ' = { path = "' .. path.format(location) .. '" }\n'
	end
	fs.writestringtofile(path.join(vend_path, "rotriever.toml"), rotriever_toml)

	-- Use Rotriever via Foreman
	local foreman_toml = [[
[tools]
rotrieve = { source = "Roblox/rotriever", version = "=0.5.26" }
]]
	fs.writestringtofile(path.join(vend_path, "foreman.toml"), foreman_toml)
	process.run({ "foreman", "install" }, { cwd = path.format(vend_path), stdio = "inherit" })
	process.run({ "rotrieve", "install" }, { cwd = path.format(vend_path), stdio = "inherit" })

	pcall(fs.removedirectory, vend_path, { recursive = true })
end

local main_toml_path = assert(select(2, ...), "path to main rotriever.toml is required")
assert(fs.type(main_toml_path) == "file", "main rotriever.toml must be a file")
vend(path.resolve(main_toml_path))
