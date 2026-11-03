#!/usr/bin/env bash
# sysroot 안의 절대 경로 심볼릭 링크(/usr/lib/...)를 sysroot 기준 상대 경로로 바꾼다.
# 그대로 두면 PC의 /usr/lib를 가리켜 링크가 깨진다.
set -euo pipefail

root="$1"
count=0
while IFS= read -r -d '' link; do
    target="$(readlink "$link")"
    case "$target" in
        /*)
            relative="$(realpath -m --relative-to="$(dirname "$link")" "$root$target")"
            ln -sfn "$relative" "$link"
            count=$((count + 1))
            ;;
    esac
done < <(find "$root" -type l -print0)
echo "fixed $count absolute links in $root"
