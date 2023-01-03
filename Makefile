#!/usr/bin/make -f

ifneq (,$(wildcard ./.build.env))
    include .build.env
    export
endif

GIT_HASH ?= $(shell git log --format="%h" -n 1)
BUILD_DATE ?= $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

_BUILD_ARGS_TARGET ?= prd
_BUILD_ARGS_TAG ?= latest

_TEST_ARGS_VARIANT ?= fpm
_TEST_ARGS_TAG ?= latest

.DEFAULT_GOAL := help
.PHONY: help build build-apache build-nginx build-dev build-apache-dev build-nginx-dev build-all test

help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

build: # Build [fpm,apache,nginx] prd variant Docker images
	@$(MAKE) -s _build-fpm-prd
	@$(MAKE) -s _build-apache-prd
	@$(MAKE) -s _build-nginx-prd

build-dev: # Build [fpm,apache,nginx] dev variant Docker images
	@$(MAKE) -s _build-fpm-dev
	@$(MAKE) -s _build-apache-dev
	@$(MAKE) -s _build-nginx-dev

build-fpm: # Build [fpm] prd variant Docker image
	@$(MAKE) -s _build-fpm-prd

build-apache: # Build [apache] prd variant Docker image
	@$(MAKE) -s _build-apache-prd

build-nginx: # Build [nginx] prd Docker image
	@$(MAKE) -s _build-nginx-prd

build-fpm-dev: # Build [fpm] dev Docker image
	@$(MAKE) -s _build-fpm-dev

build-apache-dev: # Build [apache] dev Docker image
	@$(MAKE) -s _build-apache-dev

build-nginx-dev: # Build [nginx] dev Docker image
	@$(MAKE) -s _build-nginx-dev

build-all: # Build [fpm,apache,nginx] [prd,dev] variants Docker images
	@$(MAKE) -s _build-fpm-prd
	@$(MAKE) -s _build-fpm-dev
	@$(MAKE) -s _build-apache-prd
	@$(MAKE) -s _build-apache-dev
	@$(MAKE) -s _build-nginx-prd
	@$(MAKE) -s _build-nginx-dev

_build-%: 
	@$(MAKE) -s _builder \
		-e _BUILD_ARGS_TAG="${PHP_VERSION}-$*" \
		-e _BUILD_ARGS_TARGET="$*"

_builder:
	@echo "Build [${DOCKER_IMAGE_NAME}:${_BUILD_ARGS_TAG}] Docker image ..."
	@docker build \
		--build-arg VERSION_ARG="${PHP_VERSION}" \
		--build-arg RELEASE_ARG="${_BUILD_ARGS_TAG}" \
		--build-arg BUILD_DATE_ARG="${BUILD_DATE}" \
		--build-arg VCS_REF_ARG="${GIT_HASH}" \
		--target ${_BUILD_ARGS_TARGET} \
		--tag ${DOCKER_IMAGE_NAME}:${_BUILD_ARGS_TAG} .

test: # Test [fpm,apache,nginx] prd variant Docker images
	@$(MAKE) -s _test-fpm-prd
	@$(MAKE) -s _test-apache-prd
	@$(MAKE) -s _test-nginx-prd

test-dev: # Test [fpm,apache,nginx] dev variant Docker images
	@$(MAKE) -s _test-fpm-dev
	@$(MAKE) -s _test-apache-dev
	@$(MAKE) -s _test-nginx-dev

test-fpm: # Test [fpm] prd variant Docker image
	@$(MAKE) -s _test-fpm-prd

test-fpm-dev: # Test [fpm] dev variant Docker image
	@$(MAKE) -s _test-fpm-dev

test-apache: # Test [apache] prd variant Docker image
	@$(MAKE) -s _test-apache-prd

test-apache-dev: # Test [apache] dev variant Docker image
	@$(MAKE) -s _test-apache-dev

test-nginx: # Test [nginx] prd variant Docker image
	@$(MAKE) -s _test-nginx-prd

test-nginx-dev: ## Test [nginx] dev variant Docker image
	@$(MAKE) -s _test-nginx-dev

test-all: # Test [fpm,apache,nginx] [prd,dev] variant Docker images
	@$(MAKE) -s _test-fpm-prd
	@$(MAKE) -s _test-apache-prd
	@$(MAKE) -s _test-nginx-prd
	@$(MAKE) -s _test-fpm-dev
	@$(MAKE) -s _test-apache-dev
	@$(MAKE) -s _test-nginx-dev

_test-fpm-%:
	@$(MAKE) -s _tester \
		-e _TEST_ARGS_TAG="${PHP_VERSION}-fpm-$*" \
		-e _TEST_ARGS_VARIANT="fpm"

_test-apache-%:
	@$(MAKE) -s _tester \
		-e _TEST_ARGS_TAG="${PHP_VERSION}-apache-$*" \
		-e _TEST_ARGS_VARIANT="apache"

_test-nginx-%:
	@$(MAKE) -s _tester \
		-e _TEST_ARGS_TAG="${PHP_VERSION}-nginx-$*" \
		-e _TEST_ARGS_VARIANT="nginx"

_tester: 
	@$(MAKE) -s _bats \
		-e DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME}:${_TEST_ARGS_TAG}"

_bats:
	@echo "Test [${DOCKER_IMAGE_NAME}] Docker image ..."
	@bats test/tests.${_TEST_ARGS_VARIANT}.bats

trim: # Trim [fpm,apache,nginx] prd variant Docker images
	@$(MAKE) -s _trim-fpm-prd
	@$(MAKE) -s _trim-apache-prd
	@$(MAKE) -s _trim-nginx-prd

trim-dev: # Trim [fpm,apache,nginx] dev variant Docker images
	@$(MAKE) -s _trim-fpm-dev
	@$(MAKE) -s _trim-apache-dev
	@$(MAKE) -s _trim-nginx-dev

trim-fpm: # Test [fpm] prd variant Docker image
	@$(MAKE) -s _trim-fpm-prd

trim-fpm-dev: # Test [fpm] dev variant Docker image
	@$(MAKE) -s _trim-fpm-dev

trim-apache: # Test [apache] prd variant Docker image
	@$(MAKE) -s _trim-apache-prd

trim-apache-dev: # Test [apache] dev variant Docker image
	@$(MAKE) -s _trim-apache-dev

trim-nginx: # Test [nginx] prd variant Docker image
	@$(MAKE) -s _trim-nginx-prd

trim-nginx-dev: ## Test [nginx] dev variant Docker image
	@$(MAKE) -s _trim-nginx-dev

trim-all: # Test [fpm,apache,nginx] [prd,dev] variant Docker images
	@$(MAKE) -s _trim-fpm-prd
	@$(MAKE) -s _trim-apache-prd
	@$(MAKE) -s _trim-nginx-prd
	@$(MAKE) -s _trim-fpm-dev
	@$(MAKE) -s _trim-apache-dev
	@$(MAKE) -s _trim-nginx-dev

_trim-fpm-%:
	@$(MAKE) -s _squash \
		-e _TEST_ARGS_TAG="${PHP_VERSION}-fpm-$*"

_trim-apache-%:
	@$(MAKE) -s _squash \
		-e _TEST_ARGS_TAG="${PHP_VERSION}-apache-$*"

_trim-nginx-%:
	@$(MAKE) -s _squash \
		-e _TEST_ARGS_TAG="${PHP_VERSION}-nginx-$*"

_squash:
	@echo "Trim [${DOCKER_IMAGE_NAME}:${_TEST_ARGS_TAG}] Docker image ..."
	@docker-squash --message "Build and Squashed locally with docker-squash" \
		--tag ${DOCKER_IMAGE_NAME}:${_TEST_ARGS_TAG} \
		--output-path squashed.tar \
		${DOCKER_IMAGE_NAME}:${_TEST_ARGS_TAG}
	@cat squashed.tar | docker load
	@rm squashed.tar

cmd-exists-%:
	@hash $(*) > /dev/null 2>&1 || \
		(echo "ERROR: '$(*)' must be installed and available on your PATH."; exit 1)
