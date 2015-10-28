.PHONY: debian8

VERSION = 1.3

all: debian8

debian8:
	docker images | grep -q oardocker/debian8 | awk '{print $3}' | xargs -I {} docker rmi {}
	sudo kameleon build debian8.yaml -g version:$(VERSION)
	docker tag oardocker/debian8:$(VERSION) oardocker/debian8:latest

push:
	docker push oardocker/debian8:$(VERSION)
	docker push oardocker/debian8:latest
