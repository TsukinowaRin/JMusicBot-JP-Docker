FROM maven:3.9.9-eclipse-temurin-25 AS build

WORKDIR /build

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
COPY src/ src/

RUN chmod +x mvnw \
    && ./mvnw --batch-mode --update-snapshots -DskipTests package

FROM eclipse-temurin:25-jre

ENV APP_HOME=/opt/jmusicbot
ENV JMUSICBOT_DATA_DIR=/data
ENV JMUSICBOT_CONFIG_FILE=/data/config.txt

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg tini \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system jmusicbot \
    && useradd --system --gid jmusicbot --create-home --home-dir /home/jmusicbot jmusicbot \
    && mkdir -p "${APP_HOME}" "${JMUSICBOT_DATA_DIR}" \
    && chown -R jmusicbot:jmusicbot "${APP_HOME}" "${JMUSICBOT_DATA_DIR}"

COPY --from=build /build/target/*-All.jar ${APP_HOME}/jmusicbot.jar
COPY src/main/resources/reference.conf ${APP_HOME}/reference.conf
COPY docker/entrypoint.sh ${APP_HOME}/entrypoint.sh

RUN chmod +x ${APP_HOME}/entrypoint.sh

WORKDIR /data
VOLUME ["/data"]

USER jmusicbot

ENTRYPOINT ["/usr/bin/tini", "--", "/opt/jmusicbot/entrypoint.sh"]
