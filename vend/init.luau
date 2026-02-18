local fs = require("@std/fs")
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

local function vend(package_toml_path: string)
	local parent_path = string.gsub(package_toml_path, "/[^/]+$", "")
	local locations_of_packages = { package_toml_path }

	-- Workspaces: find all members
	do
		local package_toml = toml.deserialize(fs.readfiletostring(package_toml_path))
		if package_toml.workspace then
			table.clear(locations_of_packages)
			for _, glob_string in toml_array(package_toml.workspace.members) do
				for _, path in glob(parent_path .. "/" .. glob_string) do
					table.insert(locations_of_packages, path)
				end
			end
		end
	end
	print("Locations of packages: " .. table.concat(locations_of_packages, ", "))
end

vend("./example/single-package/rotriever.toml")
vend("./example/workspace/rotriever.toml")
