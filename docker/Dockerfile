# Jetson(JetPack 6.2.x, Ubuntu 22.04, aarch64)용 C/C++ 크로스 컴파일 환경.
# Jetson과 glibc를 맞추기 위해 베이스는 반드시 Ubuntu 22.04로 둔다.
# 이 파일을 바꾸면 저장소 루트의 VERSION을 올린다.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        file \
        g++ \
        g++-aarch64-linux-gnu \
        gdb-multiarch \
        git \
        libc6-dev-arm64-cross \
        ninja-build \
        openssh-client \
        pkg-config \
        qemu-user \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 dev \
    && git config --system --add safe.directory '*'

COPY cmake/jetson-toolchain.cmake /opt/jetson-dev/jetson-toolchain.cmake
COPY docker/jetson-build /usr/local/bin/jetson-build
RUN chmod 755 /usr/local/bin/jetson-build

WORKDIR /work
