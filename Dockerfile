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
  mkdir -p /out/app/teslacamplayer/wwwroot && \
  cp -r /tmp/build/* /out/app/teslacamplayer/ && \
  cp -r wwwroot/css/ /out/app/teslacamplayer/wwwroot/css/

# runtime
FROM ghcr.io/imagegenius/baseimage-alpine:3.20

# set version label
ARG BUILD_DATE
ARG VERSION
ARG TESLACAMPLAYER_VERSION
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
