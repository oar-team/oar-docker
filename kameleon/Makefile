.PHONY: debian7 debian8

VERSION = 1.0.4

all: debian7 debian8

debian7:
	docker images | grep -q oardocker/debian7 | awk '{print $3}' | xargs -I {} docker rmi {}
	sudo kameleon build debian7.yaml -g version:$(VERSION)

debian8:
	docker images | grep -q oardocker/debian8 | awk '{print $3}' | xargs -I {} docker rmi {}
	sudo kameleon build debian8.yaml -g version:$(VERSION)
