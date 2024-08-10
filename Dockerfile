FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine as builder

# set version label
ARG TESLACAMPLAYER_VERSION

RUN \
  apk add --no-cache \
    nodejs \
    npm \
    jq && \
  echo "**** download TeslaCamPlayer ****" && \
  mkdir -p \
    /tmp/TeslaCamPlayer && \
  if [ -z ${TESLACAMPLAYER_VERSION} ]; then \
  TESLACAMPLAYER_VERSION=$(curl -sL https://api.github.com/repos/hydazz/TeslaCamPlayer/releases/latest | \
      jq -r '.tag_name'); \
  fi && \
  curl -o \
    /tmp/TeslaCamPlayer.tar.gz -L \
    "https://github.com/hydazz/TeslaCamPlayer/archive/${TESLACAMPLAYER_VERSION}.tar.gz" && \
  tar xf \
    /tmp/TeslaCamPlayer.tar.gz -C \
    /tmp/TeslaCamPlayer --strip-components=1 && \
  cd /tmp/TeslaCamPlayer/src/TeslaCamPlayer.BlazorHosted/Server && \
  dotnet restore . -r linux-musl-x64 && \
  dotnet publish *.csproj -c Release -o /tmp/build --no-restore --self-contained true -r linux-musl-x64 /p:PublishTrimmed=true /p:DefineConstants=DOCKER && \
  cd ../Client && \
  npm install && \
  npm install -g gulp && \
  gulp default && \
  rm -rf /tmp/build/lib && \
  mkdir -p /out/app/teslacamplayer/wwwroot && \
  cp -r /tmp/build/* /out/app/teslacamplayer/ && \
  cp -r wwwroot/css/ /out/app/teslacamplayer/wwwroot/css/

# runtime
FROM ghcr.io/imagegenius/baseimage-alpine:3.20

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz"

# environment settings
ENV ClipsRootPath=/media \
  CacheFilePath=/config/clips.json \
  ASPNETCORE_URLS=http://+:5000

RUN \
  echo "**** install packages ****" && \
  apk add -U --upgrade --no-cache \
  	icu-libs \
    ffmpeg && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

COPY --from=builder /out/ /

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 5000

VOLUME /config /media
