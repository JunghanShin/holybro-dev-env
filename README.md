# jetson-dev-env

Windows PC에서 Jetson용 C/C++ 프로그램을 크로스 컴파일하는 환경입니다. 이 저장소를 받아 설치하면 팀원 모두 같은 도구로 빌드합니다.

```text
Windows PC
  └─ WSL2 또는 Git Bash
       └─ Docker 컨테이너 (Ubuntu 22.04, aarch64 크로스 컴파일러)
             │ jetson-build
             ▼
          ARM64 실행 파일 ── jetson-deploy ──► Jetson에서 실행
```

| 항목 | 값 |
|---|---|
| 대상 | Jetson Orin NX, JetPack 6.2.x, Ubuntu 22.04, aarch64 |
| 컴파일러 | `aarch64-linux-gnu-g++` 11.4 |
| 도구 | CMake 3.22, Ninja, QEMU(ARM64 시험 실행) |

Jetson과 같은 Ubuntu 22.04에서 빌드해야 glibc 차이로 실행이 안 되는 문제를 피할 수 있습니다.

## 지원 범위

| 항목 | 지원 | 비고 |
|---|---|---|
| JetPack 6.x (Ubuntu 22.04) | 예 | |
| JetPack 5.x 이하 (Ubuntu 20.04 이하) | **아니요** | glibc가 낮아 여기서 빌드한 파일이 실행되지 않음 |
| CMake 프로젝트 | 예 | 실행 파일에 `install` 규칙 필요 |
| Makefile 등 다른 빌드 방식 | 직접 | `jetson-env shell`에서 `aarch64-linux-gnu-g++`로 빌드 |
| 표준 C/C++, Linux 시스템 API | 예 | |
| 외부 라이브러리 (OpenCV, Boost, GStreamer 등) | **아직 아니요** | 이미지에 ARM64판이 없음. sysroot 필요 |
| Jetson 전용 (CUDA, TensorRT, Multimedia API, VPI) | **아직 아니요** | sysroot 필요. 지정 기능만 있고 시험하지 않음 |
| 원격 디버깅 | **아직 아니요** | `gdb-multiarch`만 포함 |

## 설치

### 1. WSL2 설치

PowerShell을 관리자 권한으로 열고 실행한 뒤 재부팅합니다.

```powershell
wsl --install -d Ubuntu-22.04
```

### 2. Docker 설치

[Docker Desktop](https://www.docker.com/products/docker-desktop/)을 설치하고 실행합니다. Settings → Resources → WSL Integration에서 Ubuntu-22.04를 켭니다.

> Docker Desktop은 일정 규모 이상의 회사에서 유료입니다. 해당되면 WSL 안에 Docker Engine을 설치합니다.

WSL 터미널에서 확인합니다.

```bash
docker info
```

### 3. 이 저장소 받기

WSL 터미널에서 실행합니다. 빌드 속도를 위해 `/mnt/d`가 아니라 WSL 안(`~/`)에 둡니다.

```bash
git clone https://github.com/JunghanShin/jetson-dev-env.git ~/jetson-dev-env
```
### 4. 설치 실행

명령을 등록하고 Docker 이미지를 빌드합니다. 처음에는 약 5분 걸립니다.

```bash
~/jetson-dev-env/install.sh
```

끝에 도구 버전이 표시되면 성공입니다. PATH 안내가 나오면 그대로 따릅니다.

## 첫 빌드

예제를 복사해 빌드합니다.

```bash
cp -r ~/jetson-dev-env/template/hello ~/hello && cd ~/hello
```

```bash
jetson-build --test
```

`100% tests passed`와 `ARM aarch64`가 표시되면 환경이 갖춰진 것입니다. 여기까지는 Jetson이 없어도 됩니다.

## 선택: Jetson에서 실행해 보기

빌드한 실행 파일을 Jetson에 복사해 실제로 실행합니다. Jetson에 SSH로 접속할 수 있어야 하며, `user@<JETSON_IP>`는 Jetson 계정과 주소로 바꿉니다.

```bash
jetson-deploy user@<JETSON_IP> /home/user/hello
```

```bash
ssh user@<JETSON_IP> /home/user/hello/hello
```

`hello from ... (aarch64)`가 출력되면 Jetson에서도 정상 실행되는 것입니다.

## 구성

```text
jetson-dev-env/
├─ install.sh                 # 명령 등록, 이미지 빌드
├─ VERSION                    # 환경 버전 (이미지 태그)
├─ bin/
│  ├─ jetson-env              # 이미지, 컨테이너 관리
│  ├─ jetson-build            # 크로스 컴파일, 시험
│  └─ jetson-deploy           # Jetson에 복사
├─ docker/Dockerfile          # 빌드 환경 정의
├─ cmake/jetson-toolchain.cmake
└─ template/hello/            # 새 프로젝트 시작용 예제
```

`install.sh`는 `~/.local/bin`에 명령 3개를 등록합니다. 시스템 폴더는 건드리지 않습니다. 명령은 현재 폴더의 프로젝트를 컨테이너에 마운트해 빌드하므로, 어느 프로젝트에서든 같은 명령을 씁니다.

## 사용법

| 명령 | 내용 |
|---|---|
| `jetson-build` | 현재 폴더를 Jetson용으로 빌드 |
| `jetson-build --test` | 빌드 후 시험 (ARM64를 QEMU로 실행) |
| `jetson-build --native --debug --test` | PC용 디버그 빌드와 시험 |
| `jetson-build --clean` | 빌드 폴더를 지우고 빌드 |
| `jetson-deploy USER@HOST DIR` | 실행 파일을 Jetson에 복사 |
| `jetson-env shell` | 컨테이너 셸 |
| `jetson-env check` | 도구 버전 확인 |
| `jetson-env save FILE`, `load FILE` | 이미지를 파일로 전달 |

결과는 `build/<jetson|native>/install/bin/`에 생깁니다.

## 새 프로젝트 만들기

`template/hello`를 복사해서 시작합니다. 프로젝트에 필요한 조건은 두 가지입니다.

1. **`CMakeLists.txt`에 설치 규칙:** `install(TARGETS 이름 RUNTIME DESTINATION bin)`. 이 규칙이 있는 실행 파일만 결과에 포함됩니다.
2. **루트에 `.jetson-dev-env`:** 환경 버전을 적은 파일입니다. 현재 환경과 다르면 경고가 나옵니다. 이 파일이 있는 폴더가 컨테이너에 통째로 마운트되므로, 하위 폴더에서 빌드해도 상위의 공용 코드를 쓸 수 있습니다.

정적 라이브러리는 실행 파일에 포함되므로 Jetson에 복사하지 않습니다.

여러 프로젝트를 담은 저장소는 루트에 `.jetson-dev-env`를 두고, 각 하위 프로젝트 폴더에서 `jetson-build`를 실행합니다.

```text
my-repo/
├─ .jetson-dev-env
├─ libs/common/
└─ workers/camera/     ← 여기서 jetson-build. ../../libs도 컨테이너에서 보임
```

## VS Code

Dev Containers 확장을 설치합니다. `jetson-dev` 이미지가 빌드된 상태에서 프로젝트를 열고 **Reopen in Container**를 실행합니다. 프로젝트에 `.devcontainer/`가 있어야 하며, 템플릿에 포함되어 있습니다. 컨테이너 터미널에서도 `jetson-build`를 쓸 수 있습니다.

## 환경 변경

1. `docker/Dockerfile`이나 `cmake/`를 고칩니다.
2. `VERSION`을 올립니다.
3. 팀원은 `git pull` 후 `jetson-env build`를 실행합니다.
4. 프로젝트의 `.jetson-dev-env`와 `.devcontainer/devcontainer.json`의 버전도 맞춥니다.

Dockerfile은 Ubuntu 22.04 저장소의 최신 패키지를 받으므로, 만드는 시점에 따라 패치 버전이 조금 다를 수 있습니다. 완전히 같게 맞추려면 한 사람이 만든 이미지를 `jetson-env save`로 전달합니다.

## Jetson 전용 라이브러리 (sysroot)

CUDA, Multimedia API, TensorRT, xiAPI처럼 Jetson의 헤더와 라이브러리가 필요한 프로젝트는 Jetson에서 복사한 sysroot를 지정합니다. sysroot는 용량이 커서 이 저장소에 넣지 않습니다.

```bash
JETSON_SYSROOT=/path/to/sysroot jetson-build
```

이 경로는 아직 시험하지 않았습니다.

## 문제 해결

| 증상 | 조치 |
|---|---|
| `Docker에 연결할 수 없습니다` | Docker를 실행하고 WSL Integration 확인 |
| `jetson-build: command not found` | `install.sh`의 PATH 안내 실행 후 터미널 다시 열기 |
| `bad interpreter` | 줄바꿈이 CRLF로 바뀜. 저장소를 WSL 안에서 다시 받기 |
| 첫 빌드에서 `CMakeCache` 경로 오류 | 복사해 온 `build/` 폴더 삭제 후 다시 빌드 |
| Jetson에서 `GLIBC_x.xx not found` | `jetson-build`로 빌드했는지 확인 |
| 빌드가 매우 느림 | 소스를 `/mnt/d`에서 WSL 안으로 옮기기 |
| `Permission denied`로 스크립트 실행 불가 | `git update-index --chmod=+x install.sh bin/*` 후 커밋 |
