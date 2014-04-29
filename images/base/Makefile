.PHONY: build clean

IMAGE=oarcluster/base
RECIPE=debian
BUILD_PATH=/tmp/kameleon

build:
	kameleon build $(RECIPE) -b $(BUILD_PATH)
	docker images | grep -q "$(IMAGE)" | awk '{print $3}' | xargs -I {} docker rmi {}
	cat $(RECIPE)_base.tar.gz | docker import - $(IMAGE)

clean:
	kameleon clear $(RECIPE) -b $(BUILD_PATH)
	rm $(BUILD_PATH)/builds -fr

push:
	docker push $(IMAGE)
