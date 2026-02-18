local fs = require("@lute/fs")
local glob = require("./glob")

type Folder = { [string]: Hierarchy }
type Hierarchy = "file" | Folder

local function rmdir_recursive(path: string)
	for _, entry in fs.listdir(path) do
		local child = path .. "/" .. entry.name
		if entry.type == "dir" then
			rmdir_recursive(child)
		else
			fs.remove(child)
		end
	end
	fs.rmdir(path)
end

local function test(name: string, folder: Folder, absolute_path: string, expected_paths: { string })
	-- Create temporary hierarchy in the filesystem
	local root = "./test-hierarchy"
	pcall(rmdir_recursive, root)
	fs.mkdir(root)
	do
		local function visit(folder: Folder, on_disk: string)
			for name, hierarchy in folder do
				local path = on_disk .. "/" .. name
				if hierarchy == "file" then
					local file = fs.open(path, "w+")
					fs.write(file, "content")
					fs.close(file)
				else
					fs.mkdir(path)
					visit(hierarchy, path)
				end
			end
		end
		visit(folder, root)
	end

	local prefix = root .. "/"
	local raw_results = glob(prefix .. absolute_path)
	local stripped = {}
	for _, path in raw_results do
		if string.sub(path, 1, #prefix) == prefix then
			table.insert(stripped, string.sub(path, #prefix + 1))
		else
			error("Path " .. path .. " does not start with " .. prefix)
		end
	end

	local expected = table.concat(expected_paths, ", ")
	local actual = table.concat(stripped, ", ")

	if expected ~= actual then
		print("Test failed: " .. name)
		print("    Expected: " .. expected)
		print("    Actual: " .. actual)
	end
end

-- Literal path with no wildcards
test(
	"literal file path",
	{
		["hello.txt"] = "file",
	},
	"hello.txt",
	{
		"hello.txt",
	}
)

test("literal path not found", {
	["hello.txt"] = "file",
}, "missing.txt", {})

-- Star wildcard
test(
	"star matches all entries",
	{
		["a.txt"] = "file",
		["b.txt"] = "file",
		["subdir"] = {},
	},
	"*",
	{
		"a.txt",
		"b.txt",
		"subdir",
	}
)

test(
	"star with extension filter",
	{
		["a.lua"] = "file",
		["b.txt"] = "file",
		["c.lua"] = "file",
	},
	"*.lua",
	{
		"a.lua",
		"c.lua",
	}
)

test(
	"star does not cross directories",
	{
		["dir"] = {
			["nested.txt"] = "file",
		},
		["top.txt"] = "file",
	},
	"*.txt",
	{
		"top.txt",
	}
)

test(
	"star in nested directory",
	{
		["modules"] = {
			["ModuleA"] = { ["src"] = {} },
			["ModuleB"] = { ["src"] = {} },
			["ModuleC"] = { ["src"] = {} },
		},
	},
	"modules/*",
	{
		"modules/ModuleA",
		"modules/ModuleB",
		"modules/ModuleC",
	}
)

test("no matches", {
	["a.txt"] = "file",
}, "*.lua", {})

-- Question mark wildcard
test(
	"question mark matches single char",
	{
		["a1"] = "file",
		["a2"] = "file",
		["a12"] = "file",
		["b1"] = "file",
	},
	"a?",
	{
		"a1",
		"a2",
	}
)

-- Character classes
test(
	"character class",
	{
		["a1"] = "file",
		["b1"] = "file",
		["c1"] = "file",
		["d1"] = "file",
	},
	"[abc]1",
	{
		"a1",
		"b1",
		"c1",
	}
)

test(
	"negated character class",
	{
		["a1"] = "file",
		["b1"] = "file",
		["c1"] = "file",
	},
	"[!a]1",
	{
		"b1",
		"c1",
	}
)

test(
	"character range",
	{
		["a1"] = "file",
		["b1"] = "file",
		["c1"] = "file",
		["z1"] = "file",
	},
	"[a-c]1",
	{
		"a1",
		"b1",
		"c1",
	}
)

-- Double star
test(
	"double star recursive",
	{
		["a.txt"] = "file",
		["sub"] = {
			["b.txt"] = "file",
			["deep"] = {
				["c.txt"] = "file",
			},
		},
	},
	"**/*.txt",
	{
		"a.txt",
		"sub/b.txt",
		"sub/deep/c.txt",
	}
)

test(
	"double star in middle",
	{
		["a"] = {
			["x.txt"] = "file",
			["b"] = {
				["x.txt"] = "file",
				["c"] = {
					["x.txt"] = "file",
				},
			},
		},
	},
	"a/**/x.txt",
	{
		"a/b/c/x.txt",
		"a/b/x.txt",
		"a/x.txt",
	}
)

test(
	"double star at end",
	{
		["a.txt"] = "file",
		["sub"] = {
			["b.txt"] = "file",
		},
	},
	"**",
	{
		"a.txt",
		"sub",
		"sub/b.txt",
	}
)

-- Cleanup
pcall(rmdir_recursive, "./test-hierarchy")
print("All glob tests done.")
