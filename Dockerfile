FROM --platform=linux/amd64 tesseractshadow/tesseract4re

# Refresh apt metadata accepting any repo label changes
RUN apt-get update --allow-releaseinfo-change

# Install Java, wget, and gosu (for runtime user switching)
RUN apt-get update && apt-get install -y \
    openjdk-11-jre-headless \
    wget \
    ca-certificates \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Download Apache Tika Server 3.3.1
ENV TIKA_VERSION=3.3.1
RUN wget -q \
    https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar \
    -O /home/work/tika-server-standard-${TIKA_VERSION}.jar

# Default UID/GID — override at runtime with -e
ENV TIKA_UID=1000
ENV TIKA_GID=1000
ENV TIKA_USER=tika
ENV TIKA_GROUP=tika

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9998

ENTRYPOINT ["/entrypoint.sh"]