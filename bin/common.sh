# jetson-env, jetson-build가 함께 쓰는 함수. 직접 실행하지 않는다.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
IMAGE="jetson-dev:$VERSION"
PROJECT_MARKER=".jetson-dev-env"

require_docker() {
    if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
        echo "Docker에 연결할 수 없습니다. Docker를 실행하고 README의 문제 해결 항목을 확인하세요." >&2
        exit 1
    fi
}

build_image() {
    docker build -t "$IMAGE" -f "$REPO_ROOT/docker/Dockerfile" "$REPO_ROOT"
}

ensure_image() {
    if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
        echo "이미지 $IMAGE 가 없어 빌드합니다." >&2
        build_image
    fi
}

# 위로 올라가며 .jetson-dev-env가 있는 폴더를 찾는다. 없으면 시작 폴더를 쓴다.
# 표식이 있으면 저장소 전체가 마운트되어 ../libs 같은 공용 코드도 보인다.
find_project_root() {
    local dir="$1"
    while [ "$dir" != "/" ] && [ -n "$dir" ]; do
        if [ -f "$dir/$PROJECT_MARKER" ]; then
            echo "$dir"
            return
        fi
        local parent
        parent="$(dirname "$dir")"
        [ "$parent" = "$dir" ] && break
        dir="$parent"
    done
    echo "$1"
}

check_project_version() {
    local marker="$1/$PROJECT_MARKER"
    [ -f "$marker" ] || return 0
    local wanted
    wanted="$(tr -d '[:space:]' < "$marker")"
    if [ "$wanted" != "$VERSION" ]; then
        echo "경고: 이 프로젝트는 환경 $wanted 기준인데 현재 환경은 $VERSION 입니다." >&2
        echo "      jetson-dev-env 저장소를 맞춘 뒤 jetson-env build를 실행하세요." >&2
    fi
}

# run_in_container PROJECT_ROOT WORKDIR_UNDER_ROOT CMD...
run_in_container() {
    local root="$1"
    local relative="$2"
    shift 2
    ensure_image

    local tty_args=()
    if [ -t 0 ] && [ -t 1 ]; then tty_args=(-it); fi

    local mount_src="$root"
    local user_args=()
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            # Git Bash: Windows 경로로 넘기고 경로 자동 변환을 끈다
            mount_src="$(cd "$root" && pwd -W)"
            export MSYS_NO_PATHCONV=1
            ;;
        *)
            user_args=(--user "$(id -u):$(id -g)" -e HOME=/tmp)
            ;;
    esac

    # JETSON_DOCKER_ARGS: 명령별 추가 옵션(jetson-debug의 네트워크 등).
    # compile_commands.json은 편집기 자동 완성용으로 항상 만든다(CMake 환경 변수).
    local extra_args=()
    [ -n "${JETSON_DOCKER_ARGS:-}" ] && read -r -a extra_args <<< "$JETSON_DOCKER_ARGS"

    docker run --rm ${tty_args[@]+"${tty_args[@]}"} ${user_args[@]+"${user_args[@]}"} \
        ${extra_args[@]+"${extra_args[@]}"} -e CMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -v "$mount_src:/work" -w "/work${relative:+/$relative}" \
        ${JETSON_SYSROOT:+-v "$JETSON_SYSROOT:/sysroot:ro" -e JETSON_SYSROOT=/sysroot} \
        "$IMAGE" "$@"
}

# 프로젝트 루트 기준 상대 경로. 같으면 빈 문자열.
relative_path() {
    local root="$1"
    local path="$2"
    if [ "$root" = "$path" ]; then
        echo ""
    else
        echo "${path#"$root"/}"
    fi
}
