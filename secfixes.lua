-- script to parse the aports tree and generate the secdb yaml

local yaml = require('lyaml')
local json = require('cjson')

function read_apkbuild(file)
	local repo,  pkg = file:match("([a-z]+)/([^/]+)/APKBUILD")
	local f = io.open(file)
	if f == nil then
		return
	end
	while true do
		line = f:read("*line")
		if line == nil then
			break
		end
		if line:match("^# secfixes") then
			local y = "  - pkg:\n"..
				"      name: "..pkg.."\n"
			while line ~= nil and line:match("^#") do
				local l = line:gsub("^# ", "      ")
				if l == nil then
					break
				end
				y = y..l.."\n"
				line = f:read("*line")
			end
			f:close()
			io.write(y)
			return
		end
	end
	f:close()
end

function arch_list(arches)
	local str=""
	local _,arch
	for _,arch in ipairs(arches) do
		str=str.."  - "..arch.."\n"
	end
	return str
end

function verify_yaml(file)
	f = io.open(file)
	if f == nil then
		return 1
	end
	print("Verifying "..file)
	local data = yaml.load(f:read("*all"))
	for _,p in pairs(data.packages) do
		assert(type(p.pkg.name) == "string")
		assert(type(p.pkg.secfixes) == "table", file..": "..p.pkg.name..": secfixes is not a table")
		for k,v in pairs(p.pkg.secfixes) do
			assert(type(k) == "string", file..": "..p.pkg.name..": not a string: "..tostring(k))
			assert(string.match(k, "^[0-9]+"), p.pkg.name..": "..tostring(k))
			assert(type(v) == "table", file..": "..p.pkg.name..": "..k..": not a table")
		end
	end

	f:close()
end

function get_release(distroversion, filename)
	local f = assert(io.open(filename or "releases.json", "r"))
	local data = assert(json.decode(f:read("*a")))
	f:close()

	for _,rel in ipairs(data.release_branches) do
		if rel.rel_branch == distroversion then
			return rel
		end
	end
end

opthelp = [[

 --repo=REPO		set repository
 --release=VERSION	distro release branch
 --verify=FILE		verify generated yaml
 --releases-json=FILE	path to releases.json
]]

opts, args = require('optarg').from_opthelp(opthelp)

if not opts then
	io.stderr:write(opthelp)
	os.exit(1)
end

if opts.verify then
	os.exit(verify_yaml(opts.verify))
end

repo = (opts.repo or "main")
distroversion = (opts.release or "v3.4")

rel = get_release(distroversion, opts["releases-json"])

-- print header
io.write(([[
---
timestamp: %s
distroversion: %s
reponame: %s
archs:
]]..arch_list(rel.arches)..[[
urlprefix: http://dl-cdn.alpinelinux.org/alpine
apkurl: "{{urlprefix}}/{{distroversion}}/{{reponame}}/{{arch}}/{{pkg.name}}-{{pkg.ver}}.apk"
packages:
]]):format(os.date("!%Y-%m-%dT%TZ"), distroversion, repo))

for i = 1,#arg do
	read_apkbuild(arg[i])
end
