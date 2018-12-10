export GIT_SHA1          := $(shell git rev-parse --short HEAD)
export DOCKER_IMAGE_NAME := samba4
export DOCKER_NAME_SPACE := ${USER}
export DOCKER_VERSION    ?= latest
export BUILD_DATE        := $(shell date +%Y-%m-%d)
export BUILD_VERSION     := $(shell date +%y%m)
export BUILD_TYPE        ?= stable
export SAMBA_VERSION     ?= $(shell ./latest_release.sh)


.PHONY: build shell run exec start stop clean compose-file github-cache

default: build

github-cache:
	@hooks/github-cache

build:
	@hooks/build

shell:
	@hooks/shell

run:
	@hooks/run

exec:
	@hooks/exec

start:
	@hooks/start

stop:
	@hooks/stop

clean:
	@hooks/clean

compose-file:
	@hooks/compose-file

linter:
	@tests/linter.sh

integration_test:
	@tests/integration_test.sh

test: linter integration_test


#include env_make
#
#NS       = bodsch
#
#REPO     = docker-samba4
#NAME     = samba4
#INSTANCE = default
#
#BUILD_DATE    := $(shell date +%Y-%m-%d)
#BUILD_VERSION := $(shell date +%y%m)
#SAMBA_VERSION ?= $(shell ./latest_release.sh)
#
#
#.PHONY: build push shell run start stop rm release
#
#default: build
#
#params:
#	@echo ""
#	@echo " SAMBA_VERSION: $(SAMBA_VERSION)"
#	@echo " BUILD_DATE   : $(BUILD_DATE)"
#	@echo ""
#
#
#build:	params
#	docker build \
#		--rm \
#		--compress \
#		--build-arg BUILD_DATE=$(BUILD_DATE) \
#		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
#		--build-arg SAMBA_VERSION=$(SAMBA_VERSION) \
#		--tag $(NS)/$(REPO):$(SAMBA_VERSION) .
#	docker build \
#		--file Dockerfile.test \
#		--rm \
#		--compress \
#		--build-arg BUILD_DATE=$(BUILD_DATE) \
#		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
#		--build-arg SAMBA_VERSION=$(SAMBA_VERSION) \
#		--tag $(NS)/$(REPO)-test:$(SAMBA_VERSION) .
#
#clean:
#	docker rmi \
#		--force \
#		$(NS)/$(REPO):$(SAMBA_VERSION)
#	sudo rm -rf ${DATA_DIR}
#
#history:
#	docker history \
#		$(NS)/$(REPO):$(SAMBA_VERSION)
#
#push:
#	docker push \
#		$(NS)/$(REPO):$(SAMBA_VERSION)
#
#shell:
#	docker run \
#		--rm \
#		--name $(NAME)-$(INSTANCE) \
#		--interactive \
#		--tty \
#		--privileged \
#		$(PORTS) \
#		$(VOLUMES) \
#		$(ENV) \
#		$(NS)/$(REPO):$(SAMBA_VERSION) \
#		/bin/sh
#
#shell-test:
#	docker run \
#		--rm \
#		--name $(NAME)-$(INSTANCE)-test \
#		--interactive \
#		--tty \
#		--privileged \
#		--link $(NAME)-$(INSTANCE):samba4 \
#		--env SMB_HOST=samba4 \
#		$(NS)/$(REPO)-test:$(SAMBA_VERSION) \
#		/bin/sh
#
#test:
#	docker run \
#		--rm \
#		--name $(NAME)-$(INSTANCE)-test \
#		--privileged \
#		--link $(NAME)-$(INSTANCE):samba4 \
#		--env SMB_HOST=samba4 \
#		$(NS)/$(REPO)-test:$(SAMBA_VERSION) \
#		/tests.sh
#
#run:
#	docker run \
#		--rm \
#		--name $(NAME)-$(INSTANCE) \
#		--privileged \
#		$(PORTS) \
#		$(VOLUMES) \
#		$(ENV) \
#		$(NS)/$(REPO):$(SAMBA_VERSION)
#
#exec:
#	docker exec \
#		--interactive \
#		--tty \
#		$(NAME)-$(INSTANCE) \
#		/bin/sh
#
#start:
#	docker run \
#		--detach \
#		--name $(NAME)-$(INSTANCE) \
#		$(PORTS) \
#		$(VOLUMES) \
#		$(ENV) \
#		$(NS)/$(REPO):$(SAMBA_VERSION)
#
#stop:
#	docker stop \
#		$(NAME)-$(INSTANCE)
#
#rm:
#	docker rm \
#		$(NAME)-$(INSTANCE)
#
#compose-file:
#	echo "BUILD_DATE=$(BUILD_DATE)" > .env
#	echo "BUILD_VERSION=$(BUILD_VERSION)" >> .env
#	echo "SAMBA_DC_ADMIN_PASSWD=krazb4re+H5" >> .env
#	echo "KERBEROS_PASSWORD=kur-z3rSh1t" >> .env
#	echo "SMB_HOST=samba4" >> .env
#	docker-compose \
#		--file docker-compose_example.yml \
#		config > docker-compose.yml
#
#release: build
#	make push -e VERSION=$(SAMBA_VERSION)
#
#default: build
#
#
#
