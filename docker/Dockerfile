FROM bitwalker/alpine-elixir-phoenix:1.13 AS builder

WORKDIR /app

RUN apk --no-cache --update add alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3 file qemu-x86_64 jq

ENV GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc \
    GLIBC_VERSION=2.30-r0 \
    PORT=4000 \
    MIX_ENV="prod" \
    SECRET_KEY_BASE="RMgI4C1HSkxsEjdhtGMfwAHfyT6CKWXOgzCboJflfSm4jeAlic52io05KB6mqzc5" \
    PATH="$HOME/.cargo/bin:${PATH}" \
    RUSTFLAGS="-C target-feature=-crt-static"

RUN set -ex && \
    apk --update add libstdc++ curl ca-certificates && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION}; \
        do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

# Get Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ARG CACHE_EXCHANGE_RATES_PERIOD
ARG DISABLE_READ_API
ARG API_PATH
ARG NETWORK_PATH
ARG DISABLE_WEBAPP
ARG DISABLE_WRITE_API
ARG CACHE_ENABLE_TOTAL_GAS_USAGE_COUNTER
ARG WOBSERVER_ENABLED
ARG ADMIN_PANEL_ENABLED
ARG CACHE_ADDRESS_WITH_BALANCES_UPDATE_INTERVAL
ARG SOCKET_ROOT

# Cache elixir deps
ADD mix.exs mix.lock ./
ADD apps/block_scout_web/mix.exs ./apps/block_scout_web/
ADD apps/explorer/mix.exs ./apps/explorer/
ADD apps/ethereum_jsonrpc/mix.exs ./apps/ethereum_jsonrpc/
ADD apps/indexer/mix.exs ./apps/indexer/
ADD config/ ./config/

RUN mix do deps.get, local.rebar --force, deps.compile

# Update base image npm
RUN npm install -g npm@7.24.1

# Cache npm deps before application code

ADD apps/block_scout_web/assets/ ./apps/block_scout_web/assets/
ADD apps/explorer/package*.json ./apps/explorer/

# Add blockscout npm deps
RUN cd apps/block_scout_web/assets/ && \
    npm install && \
    npm run deploy

RUN cd apps/explorer/ && \
    npm install && \
    apk update && apk del --force-broken-world alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3

# Add app code
ADD . .

ARG DISABLE_WRITE_API="false"
ARG DISABLE_INDEXER="false"
ARG DISABLE_WEBAPP="false"
ARG ENABLE_SOURCIFY_INTEGRATION="true"
ARG SOURCIFY_SERVER_URL="https://sourcify.dev/server"
ARG SOURCIFY_REPO_URL="https://repo.sourcify.dev/contracts/full_match/"

ENV DISABLE_WRITE_API=${DISABLE_WRITE_API} \
    DISABLE_INDEXER=${DISABLE_INDEXER} \
    DISABLE_WEBAPP=${DISABLE_WEBAPP} \
    ENABLE_SOURCIFY_INTEGRATION=${ENABLE_SOURCIFY_INTEGRATION} \
    SOURCIFY_SERVER_URL=${SOURCIFY_SERVER_URL} \
    SOURCIFY_REPO_URL=${SOURCIFY_REPO_URL}

RUN if [ "$COIN" != "" ]; then \
        sed -i s/"POA"/"${COIN}"/g apps/block_scout_web/priv/gettext/en/LC_MESSAGES/default.po; \
        sed -i "/msgid \"Ether\"/{n;s/msgstr \"\"/msgstr \"${COIN}\"/g}" apps/block_scout_web/priv/gettext/default.pot; \
        sed -i "/msgid \"Ether\"/{n;s/msgstr \"\"/msgstr \"${COIN}\"/g}" apps/block_scout_web/priv/gettext/en/LC_MESSAGES/default.po; \
        sed -i "/msgid \"ETH\"/{n;s/msgstr \"\"/msgstr \"${COIN}\"/g}" apps/block_scout_web/priv/gettext/default.pot; \
        sed -i "/msgid \"ETH\"/{n;s/msgstr \"\"/msgstr \"${COIN}\"/g}" apps/block_scout_web/priv/gettext/en/LC_MESSAGES/default.po; \
    fi

# Invalidate cache via modifying build args on compilation
ARG FORCE_MIX_COMPILE_CACHE_MISS
RUN mix compile && mix phx.digest
