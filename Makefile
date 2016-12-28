LUA = lua5.3

aports = $(HOME)/aports
gitbranch = $(shell git -C $(aports) rev-parse --abbrev-ref HEAD)
rel = v$(gitbranch:-stable=)


targets = $(rel)/main.yaml $(rel)/community.yaml

all: $(targets)

repo=$(notdir $(basename $@))

$(rel)/%.yaml:
	$(LUA) secfixes.lua --repo $(repo) --release $(rel) \
		$(aports)/$(repo)/*/APKBUILD > $@.tmp \
		&& mv $@.tmp $@

clean:
	rm -f $(targets)

.PHONY: clean
