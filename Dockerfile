# syntax=docker/dockerfile:1-labs

FROM ubuntu:24.04

RUN cat /etc/apt/sources.list.d/ubuntu.sources

ARG TARGETOS
ARG TARGETARCH

# Add plucky sources
RUN if [ "$TARGETOS/${TARGETARCH}" = "linux/amd64" ]; then \
		echo Downloading amd64 binaries; \
		PLUCKY_URL="http://archive.ubuntu.com/ubuntu/"; \
        PLUCKY_SECURITY_URL="http://security.ubuntu.com/ubuntu/"; \
	elif [ "$TARGETOS/${TARGETARCH}" = "linux/arm64" ]; then \
		echo Downloading arm64 binaries; \
        PLUCKY_URL="http://ports.ubuntu.com/ubuntu-ports/"; \
        PLUCKY_SECURITY_URL="http://ports.ubuntu.com/ubuntu-ports/"; \
	else \
		echo "Unsupported target os and platform $TARGETOS/${TARGETARCH}"; \
		exit 1; \
	fi; \
    echo "Types: deb" > /etc/apt/sources.list.d/plucky.sources && \
    echo "URIs: ${PLUCKY_URL}" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "Suites: plucky plucky-updates plucky-backports" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "Components: main restricted universe multiverse" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "Types: deb" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "URIs: ${PLUCKY_SECURITY_URL}" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "Suites: plucky-security" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "Components: main restricted universe multiverse" >> /etc/apt/sources.list.d/plucky.sources && \
    echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" >> /etc/apt/sources.list.d/plucky.sources

# Add pinning to prefer packages from the base release (jammy) over plucky, except for kcov
RUN echo "Package: *" > /etc/apt/preferences.d/plucky-pin && \
    echo "Pin: release n=plucky" >> /etc/apt/preferences.d/plucky-pin && \
    echo "Pin-Priority: -10" >> /etc/apt/preferences.d/plucky-pin && \
    echo "" >> /etc/apt/preferences.d/plucky-pin && \
    echo "Package: kcov" >> /etc/apt/preferences.d/plucky-pin && \
    echo "Pin: release n=plucky" >> /etc/apt/preferences.d/plucky-pin && \
    echo "Pin-Priority: 500" >> /etc/apt/preferences.d/plucky-pin

RUN cat /etc/apt/sources.list.d/plucky.sources
RUN cat /etc/apt/preferences.d/plucky-pin

RUN apt-get update && apt-get install --no-install-recommends -y curl xz-utils ca-certificates kcov minisign && rm -rf /var/lib/apt/lists/*

ARG ZIG_VERSION=0.15.1

# Install zig
RUN if [ "$TARGETOS/${TARGETARCH}" = "linux/amd64" ]; then \
		echo Downloading amd64 binaries; \
		ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz"; \
	elif [ "$TARGETOS/${TARGETARCH}" = "linux/arm64" ]; then \
		echo Downloading arm64 binaries; \
        ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-aarch64-linux-${ZIG_VERSION}.tar.xz"; \
	else \
		echo "Unsupported target os and platform $TARGETOS/${TARGETARCH}"; \
		exit 1; \
	fi; \
    curl -sSL --fail -o zig.tar.xz "$ZIG_URL" && \
    mkdir -p /usr/local/zig && \
    tar -xf zig.tar.xz -C /usr/local/zig --strip-components=1

ENV PATH=/usr/local/zig:$PATH
RUN zig version

ADD . /app
WORKDIR /app

RUN --security=insecure zig build coverage

RUN cat zig-out/coverage/cov.xml |grep line-rate