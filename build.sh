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
TESSERACT_LANGS="all"
TAG=""
PUSH=false
NO_CACHE=false

# --- Usage ---
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --name      IMAGE_NAME   Image name (without tag)        (default: ${IMAGE_NAME})"
    echo "  -t, --tag       TAG          Explicit image tag              (default: auto-generated from langs)"
    echo "  -v, --version   TIKA_VERSION Tika version to bake in         (default: ${TIKA_VERSION})"
    echo "  -u, --uid       TIKA_UID     Default UID inside image        (default: ${TIKA_UID})"
    echo "  -g, --gid       TIKA_GID     Default GID inside image        (default: ${TIKA_GID})"
    echo "      --user      TIKA_USER    Default username                (default: ${TIKA_USER})"
    echo "      --group     TIKA_GROUP   Default group name              (default: ${TIKA_GROUP})"
    echo "  -p|--platforms  PLATFORMS    Target platforms                (default: ${PLATFORMS})"
    echo "  -l, --langs     LANGS        Tesseract languages             (default: ${TESSERACT_LANGS})"
    echo "      --push                   Push image to registry          (default: false)"
    echo "      --no-cache               Disable Docker build cache      (default: false)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Language examples:"
    echo "  --langs all                  # all languages (default)"
    echo "  --langs eng                  # English only"
    echo "  --langs \"eng pol\"            # English and Polish"
    echo "  --langs \"eng pol deu fra\"    # English, Polish, German, French"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --langs eng --push"
    echo "  $0 --langs \"eng pol\" --platforms linux/amd64 "
    echo "  $0 --langs eng --tag 3.3.1-eng --push"
    echo "  $0 --uid \$(id -u) --gid \$(id -g)"
    exit 0
}

# --- Convert short lang codes to full package names ---
# Accepts short codes (eng, pol), full names (tesseract-ocr-eng), or mixed
normalize_langs() {
    local input="$1"
    local result=""
    for lang in ${input}; do
        if [ "${lang}" = "all" ]; then
            result="${result} tesseract-ocr-all"
        elif [[ "${lang}" == tesseract-ocr-* ]]; then
            result="${result} ${lang}"
        else
            result="${result} tesseract-ocr-${lang}"
        fi
    done
    echo "${result}" | xargs
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)      IMAGE_NAME="$2";       shift 2 ;;
        -t|--tag)       TAG="$2";              shift 2 ;;
        -v|--version)   TIKA_VERSION="$2";     shift 2 ;;
        -u|--uid)       TIKA_UID="$2";         shift 2 ;;
        -g|--gid)       TIKA_GID="$2";         shift 2 ;;
        --user)         TIKA_USER="$2";        shift 2 ;;
        --group)        TIKA_GROUP="$2";       shift 2 ;;
        -p|--platforms) PLATFORMS="$2";        shift 2 ;;
        -l|--langs)     TESSERACT_LANGS="$2";  shift 2 ;;
        --push)         PUSH=true;             shift ;;
        --no-cache)     NO_CACHE=true;         shift ;;
        -h|--help)      usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# --- Normalize language codes to package names ---
TESSERACT_LANGS=$(normalize_langs "${TESSERACT_LANGS}")

# --- Auto-generate tag from language list if not explicitly set ---
if [ -z "${TAG}" ]; then
    if [[ "${TESSERACT_LANGS}" == *"tesseract-ocr-all"* ]]; then
        TAG="all"
    else
        TAG=$(echo "${TESSERACT_LANGS}" | tr ' ' '\n' | sed 's/tesseract-ocr-//' | sort | tr '\n' '-' | sed 's/-$//')
    fi
fi

FULL_IMAGE="${IMAGE_NAME}:${TAG}"

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

# --- Determine cache flag ---
CACHE_FLAG=""
if [ "${NO_CACHE}" = true ]; then
    CACHE_FLAG="--no-cache"
fi

# --- Summary ---
echo "========================================"
echo "  Building Tika Docker image"
echo "========================================"
echo "  Image        : ${FULL_IMAGE}"
echo "  Tika version : ${TIKA_VERSION}"
echo "  UID / GID    : ${TIKA_UID} / ${TIKA_GID}"
echo "  User / Group : ${TIKA_USER} / ${TIKA_GROUP}"
echo "  Platforms    : ${PLATFORMS}"
echo "  Languages    : ${TESSERACT_LANGS}"
echo "  Push         : ${PUSH}"
echo "  No cache     : ${NO_CACHE}"
echo "========================================"
echo ""

# --- Build ---
docker buildx build \
    ${CACHE_FLAG} \
    --platform "${PLATFORMS}" \
    --build-arg TIKA_VERSION="${TIKA_VERSION}" \
    --build-arg TIKA_UID="${TIKA_UID}" \
    --build-arg TIKA_GID="${TIKA_GID}" \
    --build-arg TIKA_USER="${TIKA_USER}" \
    --build-arg TIKA_GROUP="${TIKA_GROUP}" \
    --build-arg TESSERACT_LANGS="${TESSERACT_LANGS}" \
    -t "${FULL_IMAGE}" \
    ${PUSH_FLAG} \
    .

echo ""
echo "Build complete: ${FULL_IMAGE}"
echo ""
echo "Run with defaults:"
echo "  docker run -d -p 9998:9998 ${FULL_IMAGE}"
echo ""
echo "Run as current host user:"
echo "  docker run -d -p 9998:9998 -e TIKA_UID=\$(id -u) -e TIKA_GID=\$(id -g) ${FULL_IMAGE}"