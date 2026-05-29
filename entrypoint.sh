#!/bin/bash
set -e

# Create group if it doesn't exist
if ! getent group "${TIKA_GROUP}" > /dev/null 2>&1; then
    groupadd -g "${TIKA_GID}" "${TIKA_GROUP}"
fi

# Create user if it doesn't exist
if ! getent passwd "${TIKA_USER}" > /dev/null 2>&1; then
    useradd -u "${TIKA_UID}" -g "${TIKA_GROUP}" -s /bin/bash -d /home/work "${TIKA_USER}"
fi

# Fix ownership of the work directory
chown -R "${TIKA_USER}":"${TIKA_GROUP}" /home/work

TIKA_JAR="/home/work/tika-server-standard-${TIKA_VERSION}.jar"

if [ ! -f "${TIKA_JAR}" ]; then
    echo "ERROR: Tika jar not found at ${TIKA_JAR}" >&2
    exit 1
fi

# Drop privileges and exec Tika
exec gosu "${TIKA_USER}" java -jar "${TIKA_JAR}" --host=0.0.0.0 --port=9998