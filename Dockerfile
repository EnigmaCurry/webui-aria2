FROM debian:12

ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} -r dummy && \
    useradd -r -g dummy -u ${UID} dummy

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates aria2 busybox curl gosu && \
    rm -rf /var/lib/apt/lists/*

ADD ./docs /webui-aria2

RUN set -eux; \
    REPO="https://github.com/mattn/goreman"; \
    ARCH=$(uname -m); \
    case "$ARCH" in \
        x86_64)  ARCH=amd64 ;; \
        aarch64) ARCH=arm64 ;; \
        *) echo "❌ unsupported uname -m: $ARCH" >&2; exit 1 ;; \
    esac; \
    TAG=$(curl -fsSL "$REPO/releases/latest" | \
          grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1); \
    curl -fL "$REPO/releases/download/${TAG}/goreman_${TAG}_linux_${ARCH}.tar.gz" \
         -o goreman.tar.gz; \
    tar -xzf goreman.tar.gz && \
    mv goreman*/goreman /usr/local/bin/ && \
    rm -rf goreman* goreman.tar.gz

RUN echo "web: gosu dummy /bin/busybox httpd -f -p \${WEB_PORT} -h /webui-aria2\n" \
         "backend: gosu dummy /usr/bin/aria2c --enable-rpc --rpc-listen-all --rpc-listen-port \${RPC_PORT} --rpc-secret \${RPC_SECRET} --dir=/downloads" \
    > Procfile

# -----------------------------------------------------------------
VOLUME /data
EXPOSE 6800 ${WEB_PORT}

# -----------------------------------------------------------------
CMD ["start"]
ENTRYPOINT ["/usr/local/bin/goreman"]
