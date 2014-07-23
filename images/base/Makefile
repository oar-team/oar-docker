.PHONY: build clean

IMAGE=oarcluster/base
RECIPE=oarcluster_base.yaml

all: build clean

build:
	docker images | grep "$(IMAGE)" | awk '{print $$3}' | xargs -I {} docker rmi {}
	kameleon build $(RECIPE)

clean:
	docker images | grep "oarcluster_base" | awk '{print $$3}' | xargs -I {} docker rmi {}
	rm builds -fr
