local fs = require("@lute/fs")
local path = require("@std/path")

local function matches(pattern: string, name: string, pi: number?, ni: number?): boolean
	local pattern_index = pi or 1
	local name_index = ni or 1
	while pattern_index <= #pattern do
		local pc = string.sub(pattern, pattern_index, pattern_index)
		if pc == "*" then
			pattern_index += 1
			for i = name_index, #name + 1 do
				if matches(pattern, name, pattern_index, i) then
					return true
				end
			end
			return false
		elseif pc == "?" then
			if name_index > #name then
				return false
			end
			pattern_index += 1
			name_index += 1
		elseif pc == "[" then
			if name_index > #name then
				return false
			end
			local nc = string.sub(name, name_index, name_index)
			pattern_index += 1
			local negate = string.sub(pattern, pattern_index, pattern_index) == "!"
			if negate then
				pattern_index += 1
			end
			local found = false
			while pattern_index <= #pattern and string.sub(pattern, pattern_index, pattern_index) ~= "]" do
				local lo = string.sub(pattern, pattern_index, pattern_index)
				pattern_index += 1
				if
					string.sub(pattern, pattern_index, pattern_index) == "-"
					and pattern_index + 1 <= #pattern
					and string.sub(pattern, pattern_index + 1, pattern_index + 1) ~= "]"
				then
					pattern_index += 1
					local hi = string.sub(pattern, pattern_index, pattern_index)
					pattern_index += 1
					if nc >= lo and nc <= hi then
						found = true
					end
				else
					if nc == lo then
						found = true
					end
				end
			end
			pattern_index += 1
			if negate then
				found = not found
			end
			if not found then
				return false
			end
			name_index += 1
		else
			if name_index > #name or string.sub(name, name_index, name_index) ~= pc then
				return false
			end
			pattern_index += 1
			name_index += 1
		end
	end
	return name_index > #name
end

local function walk(dir: string, components: { string }, ci: number, results: { string })
	if ci > #components then
		return
	end
	local ok, entries = pcall(fs.listdir, dir)
	if not ok then
		return
	end
	local comp = components[ci]
	local is_last = ci == #components
	if comp == "**" then
		if not is_last then
			walk(dir, components, ci + 1, results)
		end
		for _, entry in entries do
			local path = dir .. "/" .. entry.name
			if is_last then
				table.insert(results, path)
			end
			if entry.type == "dir" then
				walk(path, components, ci, results)
			end
		end
	else
		for _, entry in entries do
			if matches(comp, entry.name) then
				local path = dir .. "/" .. entry.name
				if is_last then
					table.insert(results, path)
				elseif entry.type == "dir" then
					walk(path, components, ci + 1, results)
				end
			end
		end
	end
end

local function glob(absolute_path: path.pathlike): { string }
	absolute_path = path.format(absolute_path)
	local components = string.split(absolute_path, "/")
	local split_at = #components + 1
	for i, comp in components do
		if string.find(comp, "[%*%?%[]") then
			split_at = i
			break
		end
	end
	local prefix = table.concat(components, "/", 1, split_at - 1)
	local pattern = { table.unpack(components, split_at) }
	if #pattern == 0 then
		if fs.exists(absolute_path) then
			return { absolute_path }
		end
		return {}
	end
	local results: { string } = {}
	walk(prefix, pattern, 1, results)
	table.sort(results)
	return results
end

return glob
