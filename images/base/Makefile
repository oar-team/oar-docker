.PHONY: build clean

IMAGE=oarcluster/base
RECIPE=debian
BUILD_PATH=/tmp/kameleon

build:
	docker images | grep -q "$(IMAGE)" | awk '{print $3}' | xargs -I {} docker rmi {}
	kameleon build $(RECIPE) -b $(BUILD_PATH)

clean:
	kameleon clear $(RECIPE) -b $(BUILD_PATH)
	rm $(BUILD_PATH)/builds -fr
