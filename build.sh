#!/bin/bash
set -e

# --- Defaults ---
IMAGE_NAME="wpik/tika-tesseract-server"
TIKA_VERSION="3.3.1"
TIKA_UID=1000
TIKA_GID=1000
TIKA_USER="tika"
TIKA_GROUP="tika"
PLATFORMS="linux/amd64,linux/arm64"
PUSH=false

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
    echo "  -p, --platforms PLATFORMS     Target platforms            (default: ${PLATFORMS})"
    echo "      --push                    Push image to registry      (default: false)"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --version 3.3.1 --name myrepo/tika:3.3.1"
    echo "  $0 --platforms linux/amd64,linux/arm64 --push"
    echo "  $0 --uid \$(id -u) --gid \$(id -g)"
    exit 0
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)      IMAGE_NAME="$2";    shift 2 ;;
        -v|--version)   TIKA_VERSION="$2";  shift 2 ;;
        -u|--uid)       TIKA_UID="$2";      shift 2 ;;
        -g|--gid)       TIKA_GID="$2";      shift 2 ;;
        --user)         TIKA_USER="$2";     shift 2 ;;
        --group)        TIKA_GROUP="$2";    shift 2 ;;
        -p|--platforms) PLATFORMS="$2";     shift 2 ;;
        --push)         PUSH=true;          shift ;;
        -h|--help)      usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# --- Ensure buildx builder exists ---
BUILDER_NAME="multiplatform-builder"
if ! docker buildx inspect "${BUILDER_NAME}" > /dev/null 2>&1; then
    echo "Creating buildx builder: ${BUILDER_NAME}"
    docker buildx create --name "${BUILDER_NAME}" --use
else
    docker buildx use "${BUILDER_NAME}"
fi

# --- Determine push/load flag ---
# --load works only for single platform (Docker limitation)
# --push is required for multi-platform builds
if [[ "${PLATFORMS}" == *","* ]]; then
    if [ "${PUSH}" = false ]; then
        echo "WARNING: Multi-platform builds require --push to export the image."
        echo "         Add --push to push to registry, or specify a single platform with -p."
        echo ""
    fi
    PUSH_FLAG="--push"
else
    if [ "${PUSH}" = true ]; then
        PUSH_FLAG="--push"
    else
        PUSH_FLAG="--load"
    fi
fi

# --- Summary ---
echo "========================================"
echo "  Building Tika Docker image"
echo "========================================"
echo "  Image name   : ${IMAGE_NAME}"
echo "  Tika version : ${TIKA_VERSION}"
echo "  UID / GID    : ${TIKA_UID} / ${TIKA_GID}"
echo "  User / Group : ${TIKA_USER} / ${TIKA_GROUP}"
echo "  Platforms    : ${PLATFORMS}"
echo "  Push         : ${PUSH}"
echo "========================================"
echo ""

# --- Build ---
docker buildx build \
    --platform "${PLATFORMS}" \
    --build-arg TIKA_VERSION="${TIKA_VERSION}" \
    --build-arg TIKA_UID="${TIKA_UID}" \
    --build-arg TIKA_GID="${TIKA_GID}" \
    --build-arg TIKA_USER="${TIKA_USER}" \
    --build-arg TIKA_GROUP="${TIKA_GROUP}" \
    -t "${IMAGE_NAME}" \
    ${PUSH_FLAG} \
    .

echo ""
echo "Build complete: ${IMAGE_NAME}"
echo ""
echo "Run with defaults:"
echo "  docker run -d -p 9998:9998 ${IMAGE_NAME}"
echo ""
echo "Run as current host user:"
echo "  docker run -d -p 9998:9998 -e TIKA_UID=\$(id -u) -e TIKA_GID=\$(id -g) ${IMAGE_NAME}"