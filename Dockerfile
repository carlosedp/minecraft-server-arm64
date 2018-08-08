FROM carlosedp/debian-oraclejava:8-172

LABEL maintainer "Carlosedp"

ENV JAVA_HOME=/opt/java

RUN apt-get update -q \
  && apt-get install -q -y --no-install-recommends ca-certificates curl wget unzip openssl imagemagick lsof git jq mysql-client gosu python python-dev python-pip iputils-ping iputils-tracepath iputils-arping adduser passwd python-setuptools \
  && rm -rf /tmp/* \
  && apt-get autoremove --purge -y && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD su-exec-arm64 /usr/bin/su-exec
RUN chmod +x /usr/bin/su-exec

RUN pip install mcstatus

HEALTHCHECK CMD mcstatus localhost:$SERVER_PORT ping

RUN addgroup --gid 1000 minecraft \
  && adduser --shell /bin/false --uid 1000 --gid 1000 --home /home/minecraft --gecos "" --disabled-password minecraft \
  && mkdir -m 777 /data /mods /config /plugins \
  && chown minecraft:minecraft /data /config /mods /plugins /home/minecraft

EXPOSE 25565 25575

ARG RESTIFY_VER=1.1.4
ARG RCON_CLI_VER=1.4.0
ARG MC_SERVER_RUNNER_VER=1.1.2
ARG ARCH=arm64

ADD restify-arm64 /usr/local/bin/restify
RUN chmod +x /usr/local/bin/restify

ADD rcon-cli-arm64 /usr/local/bin/rcon-cli
RUN chmod +x /usr/local/bin/rcon-cli

ADD mc-server-runner-arm64 /usr/local/bin/mc-server-runner
RUN chmod +x /usr/local/bin/mc-server-runner

COPY mcadmin.jq /usr/share
RUN chmod +x /usr/local/bin/*

VOLUME ["/data","/mods","/config","/plugins"]
COPY server.properties /tmp/server.properties
WORKDIR /data

ENTRYPOINT [ "/start" ]

ENV EULA=TRUE \
    ONLINE_MODE=FALSE \
    VERSION=LATEST \
    GUI=FALSE \
    CONSOLE=TRUE \
    TYPE=FORGE \
    FORGEVERSION=RECOMMENDED

ENV JVM_XX_OPTS="-XX:+UseG1GC" MEMORY="2G" \
    SPONGEBRANCH=STABLE SPONGEVERSION= LEVEL=world \
    PVP=true DIFFICULTY=normal ENABLE_RCON=true RCON_PORT=25575 RCON_PASSWORD=minecraft \
    LEVEL_TYPE=DEFAULT GENERATOR_SETTINGS= WORLD= MODPACK= SERVER_PORT=25565

COPY start* /
