.PHONY: build clean

IMAGE=oarcluster/base
RECIPE=debian

build:
	kameleon build $(RECIPE)
	docker images | grep -q "$(IMAGE)" | awk '{print $3}' | xargs -I {} docker rmi {}
	cat $(RECIPE)_base.tar.gz | docker import - $(IMAGE)

clean:
	kameleon clear $(RECIPE)
	rm ./builds -fr

push:
	docker push $(IMAGE)
