FROM ubuntu:18.04

ARG TARGETARCH
ARG TIKA_VERSION=3.3.1
ARG TIKA_UID=1000
ARG TIKA_GID=1000
ARG TIKA_USER=tika
ARG TIKA_GROUP=tika

# Create work directory early so wget has a target
RUN mkdir -p /home/work

# Install Tesseract:
#   - amd64: use alex-p PPA for Tesseract 4
#   - arm64: use default Ubuntu repos
RUN apt-get update && apt-get install -y software-properties-common ca-certificates wget gosu \
    && if [ "${TARGETARCH}" = "amd64" ]; then \
        add-apt-repository -y ppa:alex-p/tesseract-ocr \
        && apt-get update --allow-releaseinfo-change; \
    else \
        apt-get update; \
    fi \
    && apt-get install -y tesseract-ocr-all openjdk-11-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Download Tika Server
RUN wget -q \
    https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar \
    -O /home/work/tika-server-standard-${TIKA_VERSION}.jar

# Bake ARGs into ENV so entrypoint and runtime can reference them
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