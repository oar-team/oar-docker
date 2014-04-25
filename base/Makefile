.PHONY: build clean

build:
	kameleon build debian

clean:
	kameleon clear debian
	sudo rm ./builds -fr

push:
	docker push oarcluster/base
