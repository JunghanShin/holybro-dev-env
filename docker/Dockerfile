# Jetson(JetPack 6.2.2, L4T 36.5.0, Ubuntu 22.04, aarch64) 전용 C/C++/CUDA 크로스 컴파일 환경.
#
#   - aarch64 크로스 컴파일러 (Ubuntu)
#   - CUDA 크로스 컴파일러 nvcc (NVIDIA Jetson x86_64 저장소)
#   - Jetson sysroot /opt/jetson/sysroot: Jetson과 같은 저장소의 ARM64 패키지를 받아 압축만 푼다.
#     ARM64 프로그램을 실행하지 않으므로 Docker에 QEMU 설정이 필요 없다.
#
# Jetson과 glibc를 맞추기 위해 베이스는 반드시 Ubuntu 22.04로 둔다.
# 이 파일이나 jetpack-*.list를 바꾸면 저장소 루트의 VERSION을 올린다.
FROM ubuntu:22.04

ARG L4T_RELEASE=r36.5
ARG JETPACK_LIST=jetpack-6.2.2.list
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        curl \
        file \
        g++ \
        g++-aarch64-linux-gnu \
        gdb-multiarch \
        git \
        gnupg \
        libc6-dev-arm64-cross \
        ninja-build \
        openssh-client \
        pkg-config \
        qemu-user \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://repo.download.nvidia.com/jetson/jetson-ota-public.asc \
        | gpg --dearmor -o /usr/share/keyrings/nvidia-jetson.gpg

# CUDA 크로스 컴파일러. Jetson의 CUDA와 같은 버전으로 고정한다.
RUN echo "deb [signed-by=/usr/share/keyrings/nvidia-jetson.gpg] https://repo.download.nvidia.com/jetson/x86_64/jammy ${L4T_RELEASE} main" \
        > /etc/apt/sources.list.d/nvidia-jetson-cross.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        cuda-nvcc-12-6=12.6.68-1 \
        cuda-cross-aarch64-12-6=12.6.11-1 \
    && rm -rf /var/lib/apt/lists/*

# Jetson sysroot. 별도 apt 폴더에서 ARM64 패키지와 의존 패키지를 모두 받아 /opt/jetson/sysroot에 푼다.
COPY docker/${JETPACK_LIST} /tmp/jetpack.list
COPY docker/sysroot-packages.txt /tmp/sysroot-packages.txt
COPY docker/fix-sysroot-links.sh /tmp/fix-sysroot-links.sh
RUN set -eu; \
    A=/tmp/apt-arm64; S=/opt/jetson/sysroot; \
    mkdir -p $A/etc/apt/sources.list.d $A/etc/apt/preferences.d $A/var/lib/apt/lists/partial \
             $A/var/cache/apt/archives/partial $A/var/lib/dpkg $S; \
    touch $A/var/lib/dpkg/status; \
    U="signed-by=/usr/share/keyrings/ubuntu-archive-keyring.gpg"; \
    N="signed-by=/usr/share/keyrings/nvidia-jetson.gpg"; \
    { for suite in jammy jammy-updates jammy-security; do \
          echo "deb [arch=arm64 $U] http://ports.ubuntu.com/ubuntu-ports $suite main restricted universe multiverse"; \
      done; \
      echo "deb [arch=arm64 $N] https://repo.download.nvidia.com/jetson/common ${L4T_RELEASE} main"; \
      echo "deb [arch=arm64 $N] https://repo.download.nvidia.com/jetson/t234 ${L4T_RELEASE} main"; \
    } > $A/etc/apt/sources.list; \
    grep -vE '^(#|$)' /tmp/jetpack.list \
        | awk -F= '{print "Package: "$1"\nPin: version "$2"\nPin-Priority: 1001\n"}' \
        > $A/etc/apt/preferences.d/jetpack; \
    # 목록에 없는 L4T 패키지(firmware, nvsci 등)도 목록의 L4T 버전에 맞춘다. \
    L4T=$(sed -n 's/^nvidia-l4t-core=//p' /tmp/jetpack.list); \
    printf 'Package: nvidia-l4t-*\nPin: version %s\nPin-Priority: 1001\n' "$L4T" \
        >> $A/etc/apt/preferences.d/jetpack; \
    APT="apt-get -o Dir=$A -o Dir::State::status=$A/var/lib/dpkg/status -o APT::Architecture=arm64 \
         -o APT::Architectures::=arm64 -o Debug::NoLocking=1 -o APT::Get::AllowUnauthenticated=false"; \
    $APT update; \
    $APT install -y --download-only --no-install-recommends $(grep -vE '^(#|$)' /tmp/sysroot-packages.txt); \
    for deb in $A/var/cache/apt/archives/*.deb; do dpkg-deb -x "$deb" $S; done; \
    echo "unpacked $(ls $A/var/cache/apt/archives/*.deb | wc -l) packages"; \
    echo "# R36 (release), REVISION: 5.0, BOARD: generic, EABI: aarch64" > $S/etc/nv_tegra_release; \
    bash /tmp/fix-sysroot-links.sh $S; \
    rm -rf $A /tmp/jetpack.list /tmp/sysroot-packages.txt /tmp/fix-sysroot-links.sh \
           $S/usr/share/doc $S/usr/share/man $S/usr/share/locale $S/usr/local/cuda-12.6/doc

COPY docker/sysroot-postinst.sh /tmp/sysroot-postinst.sh
RUN bash /tmp/sysroot-postinst.sh /opt/jetson/sysroot && rm /tmp/sysroot-postinst.sh

RUN useradd --create-home --uid 1000 dev \
    && git config --system --add safe.directory '*'

COPY cmake/jetson-toolchain.cmake /opt/jetson-dev/jetson-toolchain.cmake
COPY docker/jetson-build /usr/local/bin/jetson-build
RUN chmod 755 /usr/local/bin/jetson-build

ENV PATH=/usr/local/cuda-12.6/bin:$PATH
WORKDIR /work
