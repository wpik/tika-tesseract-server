# Stage 1: download Tika jar
FROM debian:bookworm-slim AS downloader

ARG TIKA_VERSION=3.3.1

RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q \
    https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar \
    -O /tika-server-standard-${TIKA_VERSION}.jar

# Stage 2: final — same base for all platforms
FROM debian:bookworm-slim

ARG TARGETARCH
ARG TIKA_VERSION=3.3.1
ARG TIKA_UID=1000
ARG TIKA_GID=1000
ARG TIKA_USER=tika
ARG TIKA_GROUP=tika
ARG TESSERACT_LANGS="tesseract-ocr-all"

RUN mkdir -p /home/work

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        gosu \
        openjdk-17-jre-headless \
        tesseract-ocr \
        ${TESSERACT_LANGS} \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=downloader /tika-server-standard-${TIKA_VERSION}.jar /home/work/

ENV TIKA_VERSION=${TIKA_VERSION}
ENV TIKA_UID=${TIKA_UID}
ENV TIKA_GID=${TIKA_GID}
ENV TIKA_USER=${TIKA_USER}
ENV TIKA_GROUP=${TIKA_GROUP}

WORKDIR /home/work

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9998

ENTRYPOINT ["/entrypoint.sh"]
