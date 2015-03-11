.PHONY: debian7

BUILD_PATH=/tmp/kameleon

debian7:
	docker images | grep -q oardocker/debian7 | awk '{print $3}' | xargs -I {} docker rmi {}
	sudo kameleon build debian7.yaml -b $(BUILD_PATH) -g version:1.0.0

debian8:
	docker images | grep -q oardocker/debian8 | awk '{print $3}' | xargs -I {} docker rmi {}
	sudo kameleon build debian8.yaml -b $(BUILD_PATH) -g version:1.0.0
