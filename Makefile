DEVICE ?= angler
OPTIONS ?= --no-tor
DEBUG ?= 0

.PHONY: clean
clean:
	rm -rf images helper-repos/android-simg2img helper-repos/super-bootimg update/* log/* *-update.zip *-update-signed.zip || :

.PHONY: mrproper
mrproper: clean
	rm -f *-factory-*.tar.xz *-factory-*.tar.xz.sig packages/*.apk packages/*.apk.asc packages/gapps-delta*.xz packages/gapps-delta*.xz.asc || :
	rm -rf angler-?????? bullhead-?????? || :

.PHONY: docker-clean
docker-clean:
	docker rmi -f mission-improbable || :

.PHONY: docker
docker: docker-build docker-update

.PHONY: docker-build
docker-build:
	@docker build --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) --quiet --pull --tag mission-improbable --rm --label "date=$(shell date +%F_%H%M%S)" . >/dev/null

.PHONY: docker-update
docker-update:
	@[ -d log ] || mkdir log
	@docker run --privileged --rm -v $(PWD):/build mission-improbable /build/update-wrapper.sh $(DEVICE) $(OPTIONS)

.PHONY: docker-debug
docker-debug:
	docker run --privileged --user 0 --rm --interactive --tty --volume $(PWD):/build mission-improbable /bin/bash
