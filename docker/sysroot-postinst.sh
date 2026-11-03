#!/usr/bin/env bash
# 패키지 압축만 풀었기 때문에 실행되지 않은 설치 후 스크립트(postinst)의 결과를 대신 만든다.
# Jetson에서 update-alternatives가 만드는 링크와 같다.
set -euo pipefail

root="$1"
inc="$root/usr/include"
lib="$root/usr/lib/aarch64-linux-gnu"

# cuDNN: /usr/include/cudnn*.h → aarch64-linux-gnu/cudnn*_v9.h, libcudnn*.so → libcudnn*.so.9
for header in "$inc"/aarch64-linux-gnu/cudnn*_v9.h; do
    name="$(basename "$header" _v9.h).h"
    ln -sfn "aarch64-linux-gnu/$(basename "$header")" "$inc/$name"
done
for soname in "$lib"/libcudnn*.so.9; do
    ln -sfn "$(basename "$soname")" "${soname%.9}"
done
for archive in "$lib"/libcudnn*_static_v9.a; do
    [ -e "$archive" ] && ln -sfn "$(basename "$archive")" "${archive%_v9.a}.a"
done
echo "cuDNN links: $(ls "$inc"/cudnn*.h | wc -l) headers, $(ls "$lib"/libcudnn*.so | wc -l) libraries"

# EGL(nvidia-l4t-3d-core): Jetson은 tegra-egl 폴더를 라이브러리 검색 경로에 등록한다(libnvvpi → libEGL_nvidia).
if [ -d "$lib/tegra-egl" ]; then
    mkdir -p "$root/etc/ld.so.conf.d"
    echo "/usr/lib/aarch64-linux-gnu/tegra-egl" > "$root/etc/ld.so.conf.d/aarch64-linux-gnu_EGL.conf"
    echo "EGL: registered tegra-egl"
fi
