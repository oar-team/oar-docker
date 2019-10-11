.PHONY: build

DEBIAN_VERSION=debian10
DEBIAN_SUITE=buster
DOCKER_TAG=oardocker/${DEBIAN_VERSION}
VERSION:=2019.10.10

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
#BASE_DOCKERFILES=$(shell find $(ROOT_DIR)/../oardocker/templates -path "*/base/Dockerfile" | grep ${DEBIAN_SUITE})

build:
	kameleon build ${DEBIAN_VERSION}.yaml -g version:$(VERSION)
	docker tag ${DOCKER_TAG}:$(VERSION) ${DOCKER_TAG}:latest
	#sed -i "s|FROM.*|FROM ${DOCKER_TAG}:$(VERSION)|" $(BASE_DOCKERFILES)

push:
	docker login
	docker push ${DOCKER_TAG}:$(VERSION)
	docker push ${DOCKER_TAG}:latest
	docker logout
	git tag -s -m "kameleon build for oardocker/${DEBIAN_VERSION}:$(VERSION)" "build_${DEBIAN_VERSION}_$(VERSION)"

cleanup:
	docker images -q --filter "dangling=true" | xargs -I {} bash -c "docker rmi {} 2> /dev/null || true"
	rm -rf build/

release: push cleanup
