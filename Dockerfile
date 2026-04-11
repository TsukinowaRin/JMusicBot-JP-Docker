FROM eclipse-temurin:25-jre

ENV APP_HOME=/opt/jmusicbot-launcher
ENV JMUSICBOT_DATA_DIR=/data
ENV JMUSICBOT_RELEASE_REPO=Cosgy-Dev/JMusicBot-JP
ENV JMUSICBOT_RELEASE_API_URL=https://api.github.com/repos/Cosgy-Dev/JMusicBot-JP/releases/latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq ffmpeg tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${APP_HOME}

COPY config.template.txt ${APP_HOME}/config.template.txt
COPY scripts/entrypoint.sh ${APP_HOME}/entrypoint.sh

RUN chmod +x ${APP_HOME}/entrypoint.sh

VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/tini", "--", "/opt/jmusicbot-launcher/entrypoint.sh"]
