default: image

image:
	docker pull centos:7
	docker build . \
		--file Dockerfile \
		--build-arg PYTHON_VERSION=3.9.9 \
		--tag neubauergroup/centos-python3:debug-local
