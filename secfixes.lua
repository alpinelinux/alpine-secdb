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

opthelp = [[
 --repo=REPO		set repository
 --release=VERSION	distro release branch
]]

opts, args = require('optarg').from_opthelp(opthelp)

repo = (opts.repo or "main")
distroversion = (opts.release or "v3.4")

-- print header
io.write(([[
---
distroversion: %s
reponame: %s
archs:
  - x86_64
  - x86
  - armhf
urlprefix: http://dl-cdn.alpinelinux.org/alpine
apkurl: "{{urlprefix}}/{{distroversion}}/{{reponame}}/{{arch}}/{{pkg.name}}-{{pkg.ver}}.apk"
packages:
]]):format(distroversion, repo))

for i = 1,#arg do
	read_apkbuild(arg[i])
end
