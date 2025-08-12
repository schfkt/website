docker_image := "schfkt/node-sass"
assets_build_cmd := "--output-style compressed styles/bundle.scss static/css/bundle.css"

default: build

assets: docker
  docker run \
    -v ./styles:/app/styles \
    -v ./static/css:/app/static/css \
    {{ docker_image }} {{assets_build_cmd}}

assets-watch: docker
  docker run \
    -v ./styles:/app/styles \
    -v ./static/css:/app/static/css \
    {{ docker_image }} {{assets_build_cmd}} -w

build: assets
  hugo

docker:
  docker build -t {{ docker_image }} .

publish: build
  cd public && \
     git add . && \
     git commit -m "Rebuild the site on `date`"

server:
	hugo server -D
