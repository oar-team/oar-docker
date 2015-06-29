.PHONY: debian7 debian8

VERSION = 1.1

all: debian7 debian8

debian7:
	docker images | grep -q oardocker/debian7 | awk '{print $3}' | xargs -I {} docker rmi {}
	sudo kameleon build debian7.yaml -g version:$(VERSION)
	docker tag oardocker/debian7:$(VERSION) oardocker/debian7:latest

debian8:
	docker images | grep -q oardocker/debian8 | awk '{print $3}' | xargs -I {} docker rmi {}
	sudo kameleon build debian8.yaml -g version:$(VERSION)
	docker tag oardocker/debian8:$(VERSION) oardocker/debian8:latest


push:
	docker push oardocker/debian7:$(VERSION)
	docker push oardocker/debian7:latest
	docker push oardocker/debian8:$(VERSION)
	docker push oardocker/debian8:latest
