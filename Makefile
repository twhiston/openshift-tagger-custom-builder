include ./env_make

.PHONY: build push shell run start stop rm release  pushaslatest

build:
	docker build --build-arg DRUPAL_CORE_VERSION=$(DRUPAL_CORE_VERSION) --build-arg PHP_VERSION=$(PHP_VERSION) -t $(NS)/$(REPO):$(DRUPAL_CORE_VERSION) .

push:
	docker push $(NS)/$(REPO):$(DRUPAL_CORE_VERSION)

pushaslatest:
	docker tag $(NS)/$(REPO):$(DRUPAL_CORE_VERSION) $(NS)/$(REPO):latest
	docker push $(NS)/$(REPO):latest

shell:
	docker run --rm --name $(NAME)-$(INSTANCE) -i -t $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(DRUPAL_CORE_VERSION) /bin/bash

run:
	docker run --rm --name $(NAME)-$(INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(DRUPAL_CORE_VERSION)

start:
	docker run -d --name $(NAME)-$(INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(DRUPAL_CORE_VERSION)

stop:
	docker stop $(NAME)-$(INSTANCE)

rm:
	docker rm $(NAME)-$(INSTANCE)

release: build
	make push
	make pushaslatest

default: build
