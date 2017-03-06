.PHONY: build

DOCKER_TAG=oardocker/debian8
VERSION:=$(shell date +"%Y.%m.%d")

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BASE_DOCKERFILES=$(shell find $(ROOT_DIR)/../oardocker/templates -path "*/base/Dockerfile")

build:
	sudo kameleon build debian8.yaml -g version:$(VERSION)
	docker tag ${DOCKER_TAG}:$(VERSION) ${DOCKER_TAG}:latest
	sed -i "s|FROM.*|FROM ${DOCKER_TAG}:$(VERSION)|" $(BASE_DOCKERFILES)

push:
	docker push ${DOCKER_TAG}:$(VERSION)
	docker push ${DOCKER_TAG}:latest

cleanup:
	docker images -q --filter "dangling=true" | xargs -I {} bash -c "docker rmi {} 2> /dev/null || true"
	sudo rm -rf build/

release: push cleanup
