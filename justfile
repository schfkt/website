default: build

build:
  yarn build
  hugo

publish:
  cd public && \
     git add . && \
     git commit -m "Rebuild the site on `date`"

server:
	hugo server -D
