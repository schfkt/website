FROM node:18.15

WORKDIR /app

COPY package.json .
COPY yarn.lock .
RUN yarn
ENTRYPOINT ["/app/node_modules/.bin/node-sass"]
