#!/bin/bash
set -e

# --- Defaults ---
IMAGE_NAME="wpik/tika-tesseract-server"
TIKA_VERSION="3.3.1"
TIKA_UID=1000
TIKA_GID=1000
TIKA_USER="tika"
TIKA_GROUP="tika"
PLATFORM="linux/amd64"

# --- Usage ---
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --name      IMAGE_NAME    Image name and tag          (default: ${IMAGE_NAME})"
    echo "  -v, --version   TIKA_VERSION  Tika version to bake in     (default: ${TIKA_VERSION})"
    echo "  -u, --uid       TIKA_UID      Default UID inside image    (default: ${TIKA_UID})"
    echo "  -g, --gid       TIKA_GID      Default GID inside image    (default: ${TIKA_GID})"
    echo "      --user      TIKA_USER     Default username            (default: ${TIKA_USER})"
    echo "      --group     TIKA_GROUP    Default group name          (default: ${TIKA_GROUP})"
    echo "  -p, --platform  PLATFORM      Target platform             (default: ${PLATFORM})"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --version 3.3.1 --name myrepo/tika:3.3.1"
    echo "  $0 --uid \$(id -u) --gid \$(id -g)"
    echo "  $0 --platform linux/arm64"
    exit 0
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)     IMAGE_NAME="$2";    shift 2 ;;
        -v|--version)  TIKA_VERSION="$2";  shift 2 ;;
        -u|--uid)      TIKA_UID="$2";      shift 2 ;;
        -g|--gid)      TIKA_GID="$2";      shift 2 ;;
        --user)        TIKA_USER="$2";     shift 2 ;;
        --group)       TIKA_GROUP="$2";    shift 2 ;;
        -p|--platform) PLATFORM="$2";      shift 2 ;;
        -h|--help)     usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# --- Summary ---
echo "========================================"
echo "  Building Tika Docker image"
echo "========================================"
echo "  Image name   : ${IMAGE_NAME}"
echo "  Tika version : ${TIKA_VERSION}"
echo "  UID / GID    : ${TIKA_UID} / ${TIKA_GID}"
echo "  User / Group : ${TIKA_USER} / ${TIKA_GROUP}"
echo "  Platform     : ${PLATFORM}"
echo "========================================"
echo ""

# --- Build ---
docker build \
    --platform "${PLATFORM}" \
    --build-arg TIKA_VERSION="${TIKA_VERSION}" \
    --build-arg TIKA_UID="${TIKA_UID}" \
    --build-arg TIKA_GID="${TIKA_GID}" \
    --build-arg TIKA_USER="${TIKA_USER}" \
    --build-arg TIKA_GROUP="${TIKA_GROUP}" \
    -t "${IMAGE_NAME}" \
    .

echo ""
echo "Build complete: ${IMAGE_NAME}"
echo ""
echo "Run with defaults:"
echo "  docker run -d -p 9998:9998 ${IMAGE_NAME}"
echo ""
echo "Run as current host user:"
echo "  docker run -d -p 9998:9998 -e TIKA_UID=\$(id -u) -e TIKA_GID=\$(id -g) ${IMAGE_NAME}"
