
include env_make

NS       = bodsch

REPO     = docker-samba4
NAME     = samba4
INSTANCE = default

BUILD_DATE    := $(shell date +%Y-%m-%d)
BUILD_VERSION := $(shell date +%y%m)
SAMBA_VERSION ?= $(shell curl \
  --silent \
  --location \
  --retry 3 \
  http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/APKINDEX.tar.gz | \
  gunzip | \
  strings | \
  grep -A1 "P:samba-dc" | \
  tail -n1 | \
  cut -d ':' -f2 | \
  cut -d '-' -f1)


.PHONY: build push shell run start stop rm release

default: build

params:
	@echo ""
	@echo " SAMBA_VERSION: $(SAMBA_VERSION)"
	@echo " BUILD_DATE   : $(BUILD_DATE)"
	@echo ""


build:	params
	docker build \
		--rm \
		--compress \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg SAMBA_VERSION=$(SAMBA_VERSION) \
		--tag $(NS)/$(REPO):$(SAMBA_VERSION) .

clean:
	docker rmi \
		--force \
		$(NS)/$(REPO):$(SAMBA_VERSION)
	sudo rm -rf ${DATA_DIR}

history:
	docker history \
		$(NS)/$(REPO):$(SAMBA_VERSION)

push:
	docker push \
		$(NS)/$(REPO):$(SAMBA_VERSION)

shell:
	docker run \
		--rm \
		--name $(NAME)-$(INSTANCE) \
		--interactive \
		--tty \
		--privileged \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):$(SAMBA_VERSION) \
		/bin/sh

run:
	docker run \
		--rm \
		--name $(NAME)-$(INSTANCE) \
		--privileged \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):$(SAMBA_VERSION)

exec:
	docker exec \
		--interactive \
		--tty \
		$(NAME)-$(INSTANCE) \
		/bin/sh

start:
	docker run \
		--detach \
		--name $(NAME)-$(INSTANCE) \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):$(SAMBA_VERSION)

stop:
	docker stop \
		$(NAME)-$(INSTANCE)

rm:
	docker rm \
		$(NAME)-$(INSTANCE)

release: build
	make push -e VERSION=$(SAMBA_VERSION)

default: build


