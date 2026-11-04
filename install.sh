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

# ---- Docker: 없으면 Ubuntu(WSL 포함)에 Docker 엔진을 설치한다 --------------------------------
# Docker Desktop을 이미 쓰고 있으면 그대로 쓴다. Docker Desktop은 회사 규모에 따라 유료라 설치하지 않는다.
install_docker_engine() {
    . /etc/os-release
    if [ "${ID:-}" != ubuntu ]; then
        echo "Docker를 자동으로 설치할 수 없는 OS입니다(${ID:-unknown}). Docker를 설치한 뒤 다시 실행하세요." >&2
        exit 1
    fi
    echo "Docker 엔진을 설치합니다(sudo 비밀번호를 물을 수 있습니다)."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
}

start_docker_engine() {
    if [ "$(ps -p 1 -o comm= 2>/dev/null)" = systemd ]; then
        sudo systemctl enable --now docker
        return
    fi
    # systemd 없이 뜬 WSL: 지금은 서비스로 띄우고, 다음 시작부터는 systemd로 자동 시작되게 한다
    sudo service docker start
    if grep -qi microsoft /proc/version 2>/dev/null && ! grep -qs '^systemd=true' /etc/wsl.conf; then
        printf '[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null
        echo "WSL에서 systemd를 켰습니다. 다음에 WSL을 다시 시작하면 Docker가 자동으로 뜹니다."
    fi
}

ensure_docker() {
    docker info >/dev/null 2>&1 && return 0
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            echo "Git Bash에서는 Docker Desktop이 필요합니다. Docker Desktop을 실행하거나, WSL에서 설치하세요(README)." >&2
            exit 1
            ;;
    esac
    # Docker Desktop의 WSL 연동이 남긴 docker 명령. 대상이 있으면 Docker Desktop이 꺼진 것이고,
    # 대상이 없으면(Docker Desktop을 지움) 무시하고 Docker 엔진을 설치한다
    local docker_bin docker_real
    docker_bin="$(command -v docker 2>/dev/null || true)"
    docker_real="$(readlink -f "$docker_bin" 2>/dev/null || true)"
    if [ -n "$docker_bin" ] && [[ "$docker_real" == *docker-desktop* ]]; then
        if [ -e "$docker_real" ]; then
            echo "Docker Desktop이 꺼져 있습니다. Docker Desktop을 실행하거나, 지웠다면 WSL을 다시 시작(wsl --shutdown)한 뒤 다시 실행하세요." >&2
            exit 1
        fi
        echo "Docker Desktop이 남긴 docker 연결($docker_bin)은 대상이 없어 무시합니다."
    fi
    if ! dpkg -s docker-ce >/dev/null 2>&1; then
        install_docker_engine
    fi
    start_docker_engine
    if ! id -nG | tr ' ' '\n' | grep -qx docker; then
        sudo usermod -aG docker "$USER"
        echo "$USER 를 docker 그룹에 넣었습니다. 새로 연 터미널부터 sudo 없이 docker를 씁니다."
        # 지금 셸에는 그룹이 아직 없으므로, 남은 단계는 docker 그룹으로 이어서 실행한다
        exec sg docker -c "bash '$REPO_ROOT/install.sh'"
    fi
    docker info >/dev/null 2>&1 || { echo "Docker를 시작하지 못했습니다. 'sudo service docker status'를 확인하세요." >&2; exit 1; }
}
ensure_docker

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
