VERSION := $(shell cat VERSION)
LDFLAGS := -ldflags "-X main.version=$(VERSION)"
-include .env
.PHONY: version


# -
# Local
# -


fast:
	go build $(LDFLAGS) -o samp-servers-api

static:
	CGO_ENABLED=0 GOOS=linux go build -a $(LDFLAGS) -o samp-servers-api .

local: fast
	DEBUG=1 \
	./samp-servers-api

version:
	git tag $(VERSION)
	git push
	git push origin $(VERSION)

test:
	go test -v -race


# -
# Docker
# -


build:
	docker build --no-cache -t southclaws/samp-servers-api:$(VERSION) .

push:
	docker push southclaws/samp-servers-api:$(VERSION)
	
run:
	-docker stop samp-servers-api
	-docker rm samp-servers-api
	docker run \
		--name samp-servers-api \
		--network host \
		--env-file .env \
		southclaws/samp-servers-api:$(VERSION)

run-prod:
	-docker stop samp-servers-api
	-docker rm samp-servers-api
	docker run \
		--name samp-servers-api \
		--detach \
		--publish 7790:80 \
		--restart always \
		--env-file .env \
		southclaws/samp-servers-api:$(VERSION)
	docker network connect mongodb samp-servers-api


# -
# Testing
# -


mongodb:
	-docker stop mongodb
	-docker rm mongodb
	-docker stop express
	-docker rm express
	docker run \
		--name mongodb \
		--publish 27017:27017 \
		--detach \
		mongo
	sleep 5
	docker run \
		--name express \
		--publish 8081:8081 \
		--link mongodb:mongo \
		--detach \
		mongo-express
