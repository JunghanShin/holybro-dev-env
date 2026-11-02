#!/usr/bin/env bash
# jetson-env, jetson-build, jetson-deploy를 명령으로 등록하고 이미지를 빌드한다.
# 시스템 폴더는 건드리지 않는다. ~/.local/bin에 실행 스크립트만 만든다.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.local/bin"
mkdir -p "$TARGET_DIR"

for name in jetson-env jetson-build jetson-deploy; do
    cat > "$TARGET_DIR/$name" <<EOF
#!/usr/bin/env bash
exec bash "$REPO_ROOT/bin/$name" "\$@"
EOF
    chmod +x "$TARGET_DIR/$name"
done
echo "명령 등록: $TARGET_DIR"

"$TARGET_DIR/jetson-env" build
"$TARGET_DIR/jetson-env" check

case ":$PATH:" in
    *":$TARGET_DIR:"*) ;;
    *)
        echo
        echo "PATH에 $TARGET_DIR 가 없습니다. 아래 줄을 실행한 뒤 터미널을 다시 여세요."
        echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        ;;
esac
echo
echo "설치 완료. README의 '첫 빌드' 단계로 확인하세요."
