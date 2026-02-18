local fs = require("@std/fs")
local toml = require("@self/toml")

local function vend(package_toml_path: string)
	local workspace_toml = toml.deserialize(fs.readfiletostring(package_toml_path))
	print(#workspace_toml.workspace.members)
end

vend("./example/workspace/rotriever.toml")
