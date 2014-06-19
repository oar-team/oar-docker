.PHONY: build clean

IMAGE=oarcluster/base
RECIPE=oarcluster_base.yaml

build:
	docker images | grep -q "$(IMAGE)" | awk '{print $3}' | xargs -I {} sudo docker rmi {}
	sudo kameleon build $(RECIPE)
	docker images | grep "oarcluster_base" | awk '{print $3}' | xargs -I {} sudo docker rmi {}
	rm builds -fr
