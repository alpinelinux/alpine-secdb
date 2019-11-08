LUA = lua5.3

APORTS ?= $(HOME)/aports
gitbranch = $(shell git -C $(APORTS) rev-parse --abbrev-ref HEAD)
rel = v$(gitbranch:-stable=)


targets = $(rel)/main.yaml $(rel)/community.yaml

all: $(targets)

repo=$(notdir $(basename $@))

$(rel)/%.yaml:
	$(LUA) secfixes.lua --repo $(repo) --release $(rel) \
		$(APORTS)/$(repo)/*/APKBUILD > $@.tmp \
		&& $(LUA) secfixes.lua --verify $@.tmp \
		&& mv $@.tmp $@

.PHONY: clean
clean:
	rm -f $(targets)

.PHONY: depend depends
depend depends:
	sudo apk add -U --virtual .secdb-depends lua5.3 lua5.3-lyaml lua5.3-optarg
