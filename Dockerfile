FROM node:18-alpine AS builder

WORKDIR /usr/src/app

COPY package.json .
COPY pnpm-lock.yaml .

RUN corepack enable
RUN corepack prepare pnpm@latest --activate
RUN pnpm install

COPY . .

RUN pnpm build

FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y curl
RUN curl -s https://deb.nodesource.com/setup_18.x | bash
RUN apt-get update -y
RUN apt-get install -y nodejs

RUN apt-get install -y nginx

WORKDIR /usr/src/app

RUN corepack enable
RUN corepack prepare pnpm@latest --activate

COPY --from=builder /usr/src/app/package.json .
COPY --from=builder /usr/src/app/pnpm-lock.yaml .

RUN pnpm install --prod

COPY --from=builder /usr/src/app/dist/apps/user-api .
COPY --from=builder /usr/src/app/dist/apps/admin-page /usr/share/nginx/html/app

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD service nginx start && node main.js
