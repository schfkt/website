SHELL := /bin/bash

.PHONY: build
build:
	yarn build
	hugo

.PHONY: publish
publish: build
	cd public && \
		git add . && \
		git commit -m "Rebuild the site on `date`" &&  \
		git push origin HEAD

.PHONY: server
server:
	hugo server -D
