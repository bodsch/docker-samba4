export GIT_SHA1          := $(shell git rev-parse --short HEAD)
export DOCKER_IMAGE_NAME := samba4
export DOCKER_NAME_SPACE := ${USER}
export DOCKER_VERSION    ?= latest
export BUILD_DATE        := $(shell date +%Y-%m-%d)
export BUILD_VERSION     := $(shell date +%y%m)
export BUILD_TYPE        ?= stable
export SAMBA_VERSION     ?= $(shell ./hooks/latest_release.sh)


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

client:
	@hooks/client

linter:
	@tests/linter.sh

integration_test:
	@tests/integration_test.sh

test: client linter integration_test
