FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine as builder

RUN git clone https://github.com/hydazz/TeslaCamPlayer /tmp/TeslaCamPlayer

WORKDIR /tmp/TeslaCamPlayer/src/TeslaCamPlayer.BlazorHosted

RUN \
  apk add --no-cache \
    nodejs \
    npm && \
  cd Server && \
  dotnet restore . -r linux-musl-x64 && \
  dotnet publish *.csproj -c Release -o /tmp/build --no-restore --self-contained true -r linux-musl-x64 /p:PublishTrimmed=true /p:DefineConstants=DOCKER && \
  cd ../Client && \
  npm install && \
  npm install -g gulp && \
  gulp default && \
  rm -rf /tmp/build/lib && \
  mkdir -p /out/app/teslacamviewer/wwwroot && \
  cp -r /tmp/build/* /out/app/teslacamviewer/ && \
  cp -r wwwroot/css/ /out/app/teslacamviewer/wwwroot/css/

# runtime
FROM ghcr.io/imagegenius/baseimage-alpine:3.20

# set version label
ARG BUILD_DATE
ARG VERSION
ARG TESLACAMPLAYER_VERSION
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz"

# environment settings
ENV ClipsRootPath=/media
ENV ASPNETCORE_URLS=http://+:5000
ENV HOME=/config

COPY --from=builder /out/ /

RUN \
  echo "**** install packages ****" && \
  apk add -U --upgrade --no-cache \
  	icu-libs \
    ffmpeg && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 5000

VOLUME /config /media
