LUA = lua5.3
APK ?= abuild-apk

releases_json := releases.json
releases_url := https://alpinelinux.org/$(releases_json)

APORTS ?= $(HOME)/aports
gitbranch = $(shell git -C $(APORTS) rev-parse --abbrev-ref HEAD)
rel = v$(gitbranch:-stable=)


targets = $(rel)/main.yaml $(rel)/community.yaml

all: $(targets)

repo=$(notdir $(basename $@))

$(releases_json):
	wget --output-document $@ $(releases_url)

$(rel)/%.yaml: $(releases_json)
	mkdir -p $(dir $@)
	$(LUA) secfixes.lua --repo $(repo) --release $(rel) \
		$(APORTS)/$(repo)/*/APKBUILD > $@.tmp \
		&& $(LUA) secfixes.lua --verify $@.tmp \
		&& mv $@.tmp $@

.PHONY: clean
clean:
	rm -f $(targets) releases.json

.PHONY: depend depends
depend depends:
	$(APK) add -U --virtual .secdb-depends $(LUA) $(LUA)-lyaml $(LUA)-cjson $(LUA)-optarg
