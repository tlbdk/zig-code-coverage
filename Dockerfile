# syntax=docker/dockerfile:1-labs

FROM ubuntu:24.04

ARG TARGETOS
ARG TARGETARCH

ENV NO_COLOR=true
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections


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

RUN apt-get update -qq && apt-get install -qq --no-install-recommends -y curl xz-utils ca-certificates kcov minisign locales && rm -rf /var/lib/apt/lists/*

# Set UTF8 locals
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'
ENV LC_ALL='en_US.UTF-8'

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

RUN --security=insecure zig build && kcov --dump-summary  --include-pattern=src/  coverage/ zig-out/bin/test
RUN --security=insecure zig build coverage

RUN cat zig-out/coverage/cov.xml |grep line-rate

# Clone c-code-coverage and test if that works

RUN apt-get update -qq && apt-get install -qq --no-install-recommends -y build-essential git cmake && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/tlbdk/c-code-coverage.git

WORKDIR /app/c-code-coverage/src

RUN --security=insecure make kcov

RUN find . |grep cov.xml