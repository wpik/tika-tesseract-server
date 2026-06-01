# wpik/tika-tesseract-server

A Docker image combining [Apache Tika](https://tika.apache.org/) server
with [Tesseract OCR](https://github.com/tesseract-ocr/tesseract), allowing Tika to automatically perform OCR on images
and scanned PDFs out of the box.

Inspired by [tesseract-shadow/tesseract-ocr-re](https://github.com/tesseract-shadow/tesseract-ocr-re).

Built with:

- **Tesseract 4** (all language packs) via the `alex-p/tesseract-ocr` PPA on `amd64` (Ubuntu 18.04), or the default
  repository on `arm64` (Debian Bullseye Slim)
- **Apache Tika Server** (default: 3.3.1) running on port `9998`
- **Java 11** (OpenJDK headless)
- **gosu** for flexible runtime user/group switching

---

## Supported Platforms

| Platform      | Base image           | Tesseract source           |
|---------------|----------------------|----------------------------|
| `linux/amd64` | Ubuntu 18.04         | `alex-p/tesseract-ocr` PPA |
| `linux/arm64` | Debian Bullseye Slim | Debian default repository  |

---

## Quick Start

```bash
docker run -d -p 9998:9998 wpik/tika-tesseract-server
```

Verify Tika is running:

```bash
curl http://localhost:9998/tika
```

---

## Tika Configuration

Tika can be customised by mounting a `tika-config.xml` file into the container at `/tika-config.xml`. If the file is
present at startup, it is automatically passed to Tika — no extra flags needed.

```bash
docker run -d -p 9998:9998 \
  -v $(pwd)/tika-config.xml:/tika-config.xml:ro \
  wpik/tika-tesseract-server
```

If no file is mounted, Tika starts with its default configuration.

A minimal example `tika-config.xml` to configure OCR language:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<properties>
    <parsers>
        <parser class="org.apache.tika.parser.DefaultParser"/>
    </parsers>
    <ocr>
        <params>
            <param name="language" type="string">eng+pol</param>
        </params>
    </ocr>
</properties>
```

For all available options see the [Tika configuration documentation](https://tika.apache.org/3.0.0/configuring.html).

---

## Extracting Text

Send a file to Tika for text extraction:

```bash
# Plain text output
curl -T document.pdf http://localhost:9998/tika --header "Accept: text/plain"

# JSON metadata + content
curl -T document.pdf http://localhost:9998/rmeta --header "Accept: application/json"

# OCR a scanned image
curl -T scan.png http://localhost:9998/tika --header "Accept: text/plain"
```

---

## Environment Variables

All variables can be overridden at `docker run` time with `-e`.

| Variable       | Default | Description                             |
|----------------|---------|-----------------------------------------|
| `TIKA_VERSION` | `3.3.1` | Tika version (must match the baked jar) |
| `TIKA_UID`     | `1000`  | UID the Tika process runs as            |
| `TIKA_GID`     | `1000`  | GID the Tika process runs as            |
| `TIKA_USER`    | `tika`  | Username created inside the container   |
| `TIKA_GROUP`   | `tika`  | Group name created inside the container |

> **Note:** `TIKA_VERSION` at runtime must match the version baked in at build time.
> Changing it at runtime without rebuilding will cause the container to fail with a clear error.

### Run as a specific user/group

```bash
docker run -d -p 9998:9998 \
  -e TIKA_UID=1500 \
  -e TIKA_GID=1500 \
  -e TIKA_USER=appuser \
  -e TIKA_GROUP=appgroup \
  wpik/tika-tesseract-server
```

### Match your current host user (recommended when mounting volumes)

```bash
docker run -d -p 9998:9998 \
  -e TIKA_UID=$(id -u) \
  -e TIKA_GID=$(id -g) \
  -v $(pwd)/data:/home/work/data \
  wpik/tika-tesseract-server
```

---

## Building the Image

The repository includes a `build.sh` script for convenience.

### Basic build

```bash
./build.sh
```

### All available options

```
Options:
  -n, --name      IMAGE_NAME    Image name and tag          (default: wpik/tika-tesseract-server)
  -v, --version   TIKA_VERSION  Tika version to bake in     (default: 3.3.1)
  -u, --uid       TIKA_UID      Default UID inside image    (default: 1000)
  -g, --gid       TIKA_GID      Default GID inside image    (default: 1000)
      --user      TIKA_USER     Default username            (default: tika)
      --group     TIKA_GROUP    Default group name          (default: tika)
  -p, --platforms PLATFORMS     Target platforms            (default: linux/amd64,linux/arm64)
      --push                    Push image to registry      (default: false)
  -h, --help                    Show this help message
```

### Examples

```bash
# Build for a specific platform only (no push required)
./build.sh --platforms linux/amd64

# Build and push a multi-platform image to a registry
./build.sh --platforms linux/amd64,linux/arm64 --push

# Build with a custom name and Tika version
./build.sh --name myrepo/tika:3.3.1 --version 3.3.1

# Bake in the current host user as the default
./build.sh --uid $(id -u) --gid $(id -g)
```

> **Multi-platform note:** `docker buildx` with multiple platforms requires `--push` to export
> the image to a registry. A single-platform build can be loaded locally without pushing.

---

## Files

| File              | Description                                                   |
|-------------------|---------------------------------------------------------------|
| `Dockerfile`      | Multi-stage, multi-platform Tesseract + Tika image            |
| `entrypoint.sh`   | Creates user/group at runtime, loads config, drops privileges |
| `build.sh`        | Helper script to build the image with common options          |
| `tika-config.xml` | Optional Tika configuration file (mount at runtime)           |

---

## How It Works

1. The container starts as `root` via `entrypoint.sh`.
2. The entrypoint creates the user and group defined by `TIKA_UID`/`TIKA_GID`/`TIKA_USER`/`TIKA_GROUP` if they don't
   already exist.
3. Ownership of `/home/work` is updated to that user.
4. If `/tika-config.xml` is present, it is passed to Tika via `--config`.
5. [`gosu`](https://github.com/tianon/gosu) drops privileges and execs the Tika server process as that user — with no
   extra shell layer, ensuring correct signal handling and PID 1 behaviour.

---

## License

Apache License 2.0 — see [Apache Tika](https://tika.apache.org/)
and [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) for their respective licenses.