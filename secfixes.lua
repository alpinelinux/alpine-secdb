-- script to parse the aports tree and generate the secdb yaml

yaml = require('lyaml')

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

function arch_list(a)
	local str=""
	for i=1,#a do
		str=str.."  - "..a[i].."\n"
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
			assert(string.match(k, "^[0-9]+"))
		end
	end

	f:close()
end

opthelp = [[

 --repo=REPO		set repository
 --release=VERSION	distro release branch
 --verify=FILE		verify generated yaml
]]

archs = {
	["v3.2"] = { "x86_64", "x86", "armhf" },
	["v3.3"] = { "x86_64", "x86", "armhf" },
	["v3.4"] = { "x86_64", "x86", "armhf" },
	["v3.5"] = { "x86_64", "x86", "armhf", "aarch64" },
}

opts, args = require('optarg').from_opthelp(opthelp)

if opts.verify then
	os.exit(verify_yaml(opts.verify))
end

repo = (opts.repo or "main")
distroversion = (opts.release or "v3.4")

-- print header
io.write(([[
---
distroversion: %s
reponame: %s
archs:
]]..arch_list(archs[distroversion])..[[
urlprefix: http://dl-cdn.alpinelinux.org/alpine
apkurl: "{{urlprefix}}/{{distroversion}}/{{reponame}}/{{arch}}/{{pkg.name}}-{{pkg.ver}}.apk"
packages:
]]):format(distroversion, repo))

for i = 1,#arg do
	read_apkbuild(arg[i])
end
