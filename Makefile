-include env_make

NODE_VER=22

OPENCLAW_VER ?= 2026.3.11
OPENCLAW_VER_MINOR = $(shell echo "${OPENCLAW_VER}" | grep -oE '^[0-9]+\.[0-9]+')

TAG ?= $(OPENCLAW_VER_MINOR)

REPO = wodby/openclaw
NAME = openclaw-$(OPENCLAW_VER)

PLATFORM ?= linux/arm64

IMAGETOOLS_TAG ?= $(TAG)

ifneq ($(ARCH),)
	override TAG := $(TAG)-$(ARCH)
endif

.PHONY: build build-debug buildx-build buildx-push test push shell run start stop logs clean release

default: build

build:
	docker build -t $(REPO):$(TAG) \
		--build-arg OPENCLAW_VER=$(OPENCLAW_VER) \
		--build-arg NODE_VER=$(NODE_VER) \
		./

build-debug:
	docker build -t $(REPO):$(TAG) \
		--build-arg OPENCLAW_VER=$(OPENCLAW_VER) \
		--build-arg NODE_VER=$(NODE_VER) \
		--no-cache --progress=plain ./ 2>&1 | tee build.log

buildx-build:
	docker buildx build --platform $(PLATFORM) -t $(REPO):$(TAG) \
		--build-arg OPENCLAW_VER=$(OPENCLAW_VER) \
		--build-arg NODE_VER=$(NODE_VER) \
		--load \
		./

buildx-push:
	docker buildx build --platform $(PLATFORM) --push -t $(REPO):$(TAG) \
		--build-arg OPENCLAW_VER=$(OPENCLAW_VER) \
		--build-arg NODE_VER=$(NODE_VER) \
		./

buildx-imagetools-create:
	docker buildx imagetools create -t $(REPO):$(IMAGETOOLS_TAG) \
				$(REPO):$(TAG)-amd64 \
				$(REPO):$(TAG)-arm64
.PHONY: buildx-imagetools-create

test:
	cd ./tests && IMAGE=$(REPO):$(TAG) NAME=$(NAME) ./run.sh

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) \
		-e DEBUG=1 \
		-p 18789 \
		-e OPENCLAW_GATEWAY_TOKEN=very-bad-token \
		-e OPENCLAW_GATEWAY_CONTROLUI_ALLOWED_ORIGIN="test" \
		$(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

start:
	docker run -d --name \
		-e DEBUG=1 \
		-e OPENCLAW_GATEWAY_TOKEN=very-bad-token \
		$(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	-docker rm -f $(NAME)

release: build push
