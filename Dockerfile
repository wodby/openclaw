ARG NODE_VER

FROM node:${NODE_VER}

ARG TARGETPLATFORM

ARG OPENCLAW_VER
ENV OPENCLAW_VER="${OPENCLAW_VER}"
ENV OPENCLAW_STATE_DIR="/data"
ARG OPENCLAW_NODE_INSTALL_OLD_SPACE_SIZE=2048
ARG OPENCLAW_NODE_BUILD_OLD_SPACE_SIZE=4096

ENV OPENCLAW_CONFIG_PATH=/home/node/.openclaw/openclaw.json

ENV SHELL=/bin/bash

# Install bash (set as default shell for node user), jq, and Bun (required for build scripts)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends bash passwd jq && \
    chsh -s /bin/bash node && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app
RUN chown node:node /app

RUN if [ -z "$OPENCLAW_VER" ]; then \
      echo "OPENCLAW_VER is required (example: 2026.2.26 or v2026.2.26)"; \
      exit 1; \
    fi && \
    if [ "${OPENCLAW_VER#v}" = "$OPENCLAW_VER" ]; then \
      OPENCLAW_TAG="v$OPENCLAW_VER"; \
    else \
      OPENCLAW_TAG="$OPENCLAW_VER"; \
    fi && \
    curl -fsSL "https://github.com/openclaw/openclaw/archive/refs/tags/${OPENCLAW_TAG}.tar.gz" \
      | tar -xz --strip-components=1 -C /app && \
    chown -R node:node /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

USER node
# Reduce OOM risk on low-memory hosts during dependency installation.
# Docker builds on small VMs may otherwise fail with "Killed" (exit 137).
RUN NODE_OPTIONS=--max-old-space-size=${OPENCLAW_NODE_INSTALL_OLD_SPACE_SIZE} pnpm install --frozen-lockfile

# Optionally install Chromium and Xvfb for browser automation.
# Build with: docker build --build-arg OPENCLAW_INSTALL_BROWSER=1 ...
# Adds ~300MB but eliminates the 60-90s Playwright install on every container start.
# Must run after pnpm install so playwright-core is available in node_modules.
USER root
ARG OPENCLAW_INSTALL_BROWSER=""
RUN if [ -n "$OPENCLAW_INSTALL_BROWSER" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xvfb && \
      mkdir -p /home/node/.cache/ms-playwright && \
      PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
      node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
      chown -R node:node /home/node/.cache/ms-playwright && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

USER node
# Recent OpenClaw releases can exceed Node's default heap during DTS generation.
RUN NODE_OPTIONS=--max-old-space-size=${OPENCLAW_NODE_BUILD_OLD_SPACE_SIZE} pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN NODE_OPTIONS=--max-old-space-size=${OPENCLAW_NODE_BUILD_OLD_SPACE_SIZE} pnpm ui:build

# Expose the CLI binary without requiring npm global writes as non-root.
USER root
RUN ln -sf /app/openclaw.mjs /usr/local/bin/openclaw \
 && chmod 755 /app/openclaw.mjs 

RUN rm /bin/dash && ln -s /bin/bash /bin/dash

RUN gotpl_url="https://github.com/wodby/gotpl/releases/latest/download/gotpl-${TARGETPLATFORM/\//-}.tar.gz"; \
    wget -qO- "${gotpl_url}" | tar xz --no-same-owner -C /usr/local/bin

RUN mkdir -p /data && chown -R node:node /data

ENV NODE_ENV=production

# Security hardening: Run as non-root user
# The node:22-bookworm image includes a 'node' user (uid 1000)
# This reduces the attack surface by preventing container escape via root privileges
USER node

RUN mkdir ~/.openclaw && chmod -R 700 ~/.openclaw

COPY docker-entrypoint.sh /
COPY bin /usr/local/bin
COPY templates /etc/gotpl

ENTRYPOINT ["/docker-entrypoint.sh"]

SHELL ["/bin/bash", "-c"]

VOLUME /data

# Start gateway server with default config.
# Binds to loopback (127.0.0.1) by default for security.
#
# For container platforms requiring external health checks:
#   1. Set OPENCLAW_GATEWAY_TOKEN or OPENCLAW_GATEWAY_PASSWORD env var
#   2. Override CMD: ["node","openclaw.mjs","gateway","--allow-unconfigured","--bind","lan"]
CMD ["node", "openclaw.mjs", "gateway"]
