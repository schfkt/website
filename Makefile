SHELL := /bin/bash

.PHONY: build publish server

build:
	yarn build
	hugo

publish: build
	cd public && \
		git add . && \
		git commit -m "Rebuild the site on `date`"

server:
	hugo server -D
