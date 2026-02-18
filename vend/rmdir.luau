local fs = require("@lute/fs")

local function rmdir(path: string)
	for _, entry in fs.listdir(path) do
		local child = path .. "/" .. entry.name
		if entry.type == "dir" then
			rmdir(child)
		else
			fs.remove(child)
		end
	end
	fs.rmdir(path)
end

return rmdir
