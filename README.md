# jetson-dev-env

Windows PC에서 Jetson용 C/C++/CUDA 프로그램을 개발하는 환경입니다. JetPack 라이브러리가 들어 있어 CUDA, TensorRT, Multimedia API 등을 쓰는 프로그램도 PC에서 빌드합니다. 이 저장소를 받아 설치하면 팀원 모두 같은 도구와 같은 라이브러리 버전으로 빌드합니다.

```text
Windows PC
  └─ WSL2 또는 Git Bash
       └─ Docker 컨테이너 (Ubuntu 22.04)
            ├─ aarch64 크로스 컴파일러, CUDA 크로스 컴파일러(nvcc)
            └─ Jetson sysroot (JetPack 6.2.2 헤더·라이브러리)
                  │ jetson-build
                  ▼
               ARM64 실행 파일 ── jetson-deploy ──► Jetson에서 실행
```

| 항목 | 값 |
|---|---|
| 대상 | Jetson Orin 계열(GPU `sm_87`), **JetPack 6.2.2** (L4T 36.5.0), Ubuntu 22.04, aarch64 |
| 컴파일러 | `aarch64-linux-gnu-g++` 11.4, CUDA `nvcc` 12.6 |
| 도구 | CMake 3.22, Ninja, pkg-config, QEMU(ARM64 시험 실행) |

### 들어 있는 JetPack 라이브러리

| 라이브러리 | 버전 | sysroot 경로 |
|---|---|---|
| CUDA (cudart, cuBLAS, cuFFT, NPP 등) | 12.6 | `/usr/local/cuda-12.6` |
| TensorRT | 10.3.0 | `/usr/include/aarch64-linux-gnu`, `/usr/lib/aarch64-linux-gnu` |
| cuDNN | 9.3.0 | 위와 같음 |
| VPI | 3.2.4 | `/opt/nvidia/vpi3` |
| Multimedia API (NvBufSurface, V4L2 인코더·디코더) | 36.5.0 | `/usr/src/jetson_multimedia_api`, `/usr/lib/aarch64-linux-gnu/nvidia` |
| OpenCV (NVIDIA 빌드) | 4.8.0 | `/usr/include/opencv4` |
| GStreamer | 1.20 | pkg-config `gstreamer-1.0` |

버전은 `docker/jetpack-6.2.2.list`에 고정되어 있습니다. Jetson에서 `apt-get -s install nvidia-jetpack=6.2.2+b24`로 얻은 목록입니다. sysroot는 컨테이너의 `/opt/jetson/sysroot`에 있고, `jetson-build`가 자동으로 사용합니다.

Jetson과 같은 Ubuntu 22.04와 같은 라이브러리 버전으로 빌드해야, glibc나 라이브러리 차이로 실행이 안 되는 문제를 피할 수 있습니다.

보드 쪽도 같은 버전이어야 합니다. Holybro 캐리어 보드는 [holybro-build-image](https://github.com/JunghanShin/holybro-build-image)로 이미지를 만들면 같은 목록(`jetpack-6.2.2.list`)으로 JetPack 런타임이 들어갑니다. 다른 보드는 [Jetson에 JetPack 런타임 설치](#jetson에-jetpack-런타임-설치)대로 6.2.2 고정 파일을 넣고 설치합니다. NVIDIA 저장소에는 6.2.3도 있어서 고정하지 않으면 설치가 실패하거나 다른 버전이 설치됩니다.

## 지원 범위

| 항목 | 지원 | 비고 |
|---|---|---|
| JetPack 6.2.2 (L4T r36.5) | 예 | |
| 다른 JetPack 6.x | 확인 필요 | 라이브러리 버전이 다르면 `jetpack-*.list`를 다시 만듦 |
| JetPack 5.x 이하 | **아니요** | Ubuntu 20.04 이하라 glibc가 낮음 |
| CMake 프로젝트 | 예 | 실행 파일에 `install` 규칙 필요 |
| Makefile 등 다른 빌드 방식 | 직접 | `jetson-env shell`에서 `aarch64-linux-gnu-g++ --sysroot=/opt/jetson/sysroot`로 빌드 |
| C/C++, CUDA | 예 | |
| JetPack 라이브러리 | 예 | 위 표 |
| 그 밖의 라이브러리 | 프로젝트별 | 소스째 함께 빌드하거나, `.so`를 실행 파일과 함께 배포 |
| 원격 디버깅 | **아직 아니요** | `gdb-multiarch`만 포함 |

## 설치

필요한 것은 Windows 10/11 PC 하나입니다. WSL2, Ubuntu, Docker 엔진은 스크립트가 없을 때만 설치합니다. Docker Desktop은 필요 없습니다. Docker Desktop은 회사 규모에 따라 유료라서 쓰지 않고, WSL 안에 무료인 Docker 엔진을 설치합니다.

### 자동 설치 (권장)

PowerShell에서 설치 스크립트를 받아 실행합니다.

```powershell
irm https://raw.githubusercontent.com/JunghanShin/jetson-dev-env/main/setup.ps1 -OutFile $env:TEMP\jetson-setup.ps1; powershell -ExecutionPolicy Bypass -File $env:TEMP\jetson-setup.ps1
```

스크립트는 없는 것만 설치하고, 사람이 해야 할 단계에서 멈춰 안내합니다. 안내를 따른 뒤 **같은 명령을 다시 실행하면 이어서 진행**합니다.

| 단계 | 스크립트가 하는 일 | 사람이 할 일 |
|---|---|---|
| 1. WSL2 | 없으면 설치 (관리자 창을 스스로 엶) | 관리자 권한 허용, **재부팅** |
| 2. Ubuntu | WSL에 Ubuntu가 없으면 Ubuntu 22.04 설치. 이미 있으면 그대로 사용 | 처음 실행 때 **리눅스 사용자 이름과 비밀번호** 입력 |
| 3. 저장소 | Ubuntu 홈(`~/jetson-dev-env`)에 받기. 이미 있으면 최신으로 | — |
| 4. Docker 엔진 | 없으면 Ubuntu에 설치하고 시작, 사용자를 `docker` 그룹에 추가 | sudo 비밀번호 입력 |
| 5. 개발 환경 | 명령 등록, 이미지 빌드(JetPack 패키지 약 2.7GB 다운로드, 처음 20분 안팎, 이미지 약 17GB) | — |

끝에 도구 버전이 표시되면 성공입니다. 이후 작업은 **시작 메뉴의 Ubuntu 터미널**에서 합니다.

- WSL의 Ubuntu 버전은 상관없습니다(22.04, 24.04 등). 빌드는 컨테이너 안의 Ubuntu 22.04에서 합니다.
- 다른 배포판을 쓰려면 `-Distro Ubuntu-24.04`처럼 지정합니다.
- 저장소를 회사 GitLab으로 옮기면 `-RepoUrl <주소>`로 받을 주소를 바꿉니다.

### 직접 설치

자동 설치를 쓰지 않을 때입니다.

1. 관리자 PowerShell에서 WSL2와 Ubuntu를 설치하고 재부팅합니다.
   ```powershell
   wsl --install -d Ubuntu-22.04
   ```
2. Ubuntu 터미널에서 저장소를 받습니다. 빌드 속도를 위해 `/mnt/c`가 아니라 WSL 안(`~/`)에 둡니다.
   ```bash
   git clone https://github.com/JunghanShin/jetson-dev-env.git ~/jetson-dev-env
   ```
3. 설치합니다. Docker가 없으면 Docker 엔진을 설치하고, 이어서 이미지를 빌드합니다.
   ```bash
   ~/jetson-dev-env/install.sh
   ```

**Docker Desktop을 이미 쓰고 있다면:** 그대로 씁니다. `install.sh`는 Docker가 동작하면 설치를 건너뜁니다. Docker Desktop이 꺼져 있으면 켜라고 안내하고 멈춥니다. Git Bash에서도 Docker Desktop이 있으면 쓸 수 있습니다.

## 첫 빌드

예제를 복사해 빌드합니다.

```bash
cp -r ~/jetson-dev-env/template/hello ~/hello && cd ~/hello
```

```bash
jetson-build --test
```

`100% tests passed`와 `ARM aarch64`가 표시되면 환경이 갖춰진 것입니다. 여기까지는 Jetson이 없어도 됩니다.

JetPack 라이브러리 빌드는 `template/jetpack-check`로 확인합니다. CUDA 커널과 각 라이브러리를 링크한 실행 파일 두 개가 나오면 됩니다.

```bash
cp -r ~/jetson-dev-env/template/jetpack-check ~/jetpack-check && cd ~/jetpack-check && jetson-build
```

## 선택: Jetson에서 실행해 보기

빌드한 실행 파일을 Jetson에 복사해 실제로 실행합니다. `user@<JETSON_IP>`는 Jetson 계정과 주소로 바꿉니다.

`jetson-deploy`는 비밀번호를 묻지 않으므로 SSH 키를 먼저 등록합니다. 키가 이미 있으면 첫 명령은 건너뜁니다. 두 번째 명령에서 Jetson 비밀번호를 한 번 입력합니다.

```bash
ssh-keygen -t ed25519
```

```bash
cat ~/.ssh/id_ed25519.pub | ssh user@<JETSON_IP> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

SSH 포트가 22가 아니면 두 명령 모두 `-p 포트`를 붙입니다(`jetson-deploy -p 2222 ...`, `ssh -p 2222 ...`).

```bash
jetson-deploy user@<JETSON_IP> /home/user/hello
```

```bash
ssh user@<JETSON_IP> /home/user/hello/hello
```

`hello from ... (aarch64)`가 출력되면 Jetson에서도 정상 실행되는 것입니다.

### Jetson에 JetPack 런타임 설치

JetPack 라이브러리를 쓰는 프로그램을 **실행**하려면 Jetson에도 같은 버전의 런타임이 있어야 합니다. L4T만 설치된 보드에는 TensorRT, cuDNN, VPI, OpenCV, CUDA 런타임이 없습니다.

NVIDIA 저장소에는 JetPack 6.2.3도 있어서, `nvidia-jetpack-runtime=6.2.2+b24`처럼 버전을 지정해도 하위 패키지가 6.2.3으로 잡혀 설치가 실패합니다. 먼저 `board/jetpack-6.2.2.pref`(6.2.2 버전 고정 파일)를 보드에 넣고 설치합니다. L4T 패키지는 고정하지 않으므로 L4T 36.5.x 보드면 됩니다.

PC에서 고정 파일을 보드로 복사합니다.
```bash
scp board/jetpack-6.2.2.pref dev@<Jetson IP>:/tmp/
```
Jetson에서 설치합니다.
```bash
sudo cp /tmp/jetpack-6.2.2.pref /etc/apt/preferences.d/ && sudo apt update && sudo apt install nvidia-jetpack-runtime=6.2.2+b24
```

- 파일 이름은 `.pref`로 끝나야 합니다. 다른 확장자는 apt가 읽지 않습니다.
- 고정 파일은 보드에 남겨 둡니다. `apt upgrade`를 해도 6.2.2에 머뭅니다.
- Holybro 캐리어 보드는 holybro-build-image로 만든 이미지에 런타임과 고정 파일이 이미 들어 있습니다.

CUDA 런타임(cudart)은 정적 링크하면 설치 없이도 실행됩니다. GPU 드라이버(`libcuda`)와 Multimedia API 런타임은 L4T에 들어 있습니다. `jetpack-check`의 `check-cuda`는 런타임 없이, `check-libs`는 런타임을 설치한 뒤 실행됩니다.

## 구성

```text
jetson-dev-env/
├─ setup.ps1                  # Windows 자동 설치: WSL2, Ubuntu, 저장소, install.sh
├─ install.sh                 # Docker 엔진(없을 때), 명령 등록, 이미지 빌드
├─ VERSION                    # 환경 버전 (이미지 태그)
├─ bin/
│  ├─ jetson-env              # 이미지, 컨테이너 관리
│  ├─ jetson-build            # 크로스 컴파일, 시험
│  ├─ jetson-deploy           # Jetson에 복사
│  └─ jetson-debug            # Jetson 프로그램 원격 디버깅(gdbserver + gdb-multiarch)
├─ docker/
│  ├─ Dockerfile              # 빌드 환경 정의
│  ├─ jetpack-6.2.2.list      # JetPack 패키지 버전 고정 목록
│  └─ sysroot-packages.txt    # sysroot에 넣는 패키지
├─ board/jetpack-6.2.2.pref  # Jetson에 넣는 JetPack 6.2.2 apt 버전 고정 파일
├─ cmake/jetson-toolchain.cmake  # 컴파일러, sysroot, CUDA, pkg-config 설정
└─ template/
   ├─ hello/                  # 가장 단순한 C++ 프로젝트
   └─ jetpack-check/          # CUDA와 JetPack 라이브러리 사용 예제
```

`install.sh`는 `~/.local/bin`에 명령 4개(`jetson-env`, `jetson-build`, `jetson-deploy`, `jetson-debug`)를 등록합니다. 시스템 폴더는 건드리지 않습니다. 명령은 현재 폴더의 프로젝트를 컨테이너에 마운트해 빌드하므로, 어느 프로젝트에서든 같은 명령을 씁니다.

## 사용법

| 명령 | 내용 |
|---|---|
| `jetson-build` | 현재 폴더를 Jetson용으로 빌드 |
| `jetson-build --test` | 빌드 후 시험 (ARM64를 QEMU로 실행) |
| `jetson-build --native --debug --test` | PC용 디버그 빌드와 시험 |
| `jetson-build --clean` | 빌드 폴더를 지우고 빌드 |
| `jetson-deploy [-p PORT] USER@HOST DIR` | 실행 파일을 Jetson에 복사. 실행 중인 파일도 교체 가능 |
| `jetson-debug [-p PORT] USER@HOST PROGRAM [-- 인자]` | Jetson의 프로그램을 PC의 gdb로 디버깅 ([원격 디버깅](#원격-디버깅)) |
| `jetson-env shell` | 컨테이너 셸 |
| `jetson-env check` | 도구 버전 확인 |
| `jetson-env save FILE`, `load FILE` | 이미지를 파일로 전달 |

결과는 `build/<jetson|native>/install/bin/`에 생깁니다. 편집기 자동 완성용 `build/<jetson|native>/compile_commands.json`도 함께 만들어집니다.

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

Dev Containers 확장과 WSL 확장을 설치합니다. WSL 안의 Docker 엔진을 쓰므로 VS Code 설정에서 **Dev › Containers: Execute In WSL**을 켭니다(Docker Desktop을 쓰면 필요 없음). `jetson-dev` 이미지가 빌드된 상태에서 프로젝트를 열고 **Reopen in Container**를 실행합니다. 프로젝트에 `.devcontainer/`가 있어야 하며, 템플릿에 포함되어 있습니다. 컨테이너 터미널에서도 `jetson-build`를 쓸 수 있습니다.

**자동 완성(IntelliSense):** `jetson-build`가 만든 `build/jetson/compile_commands.json`을 C/C++ 확장이 읽어, CUDA·TensorRT 같은 Jetson sysroot 헤더도 찾습니다. 템플릿의 `.devcontainer/devcontainer.json`에 설정이 들어 있습니다. 기존 프로젝트는 아래 설정을 `.devcontainer/devcontainer.json`의 `customizations.vscode.settings`에 넣습니다.

```json
"C_Cpp.default.compileCommands": "${workspaceFolder}/build/jetson/compile_commands.json",
"C_Cpp.default.intelliSenseMode": "linux-gcc-arm64"
```

처음 열었을 때 빨간 줄이 보이면 `jetson-build`를 한 번 실행합니다. 경로가 컨테이너 기준(`/work`, `/opt/jetson/sysroot`)이라 **Reopen in Container로 열었을 때** 동작합니다.

## 원격 디버깅

Jetson에서 실행 중인 프로그램에 PC의 gdb로 중단점을 걸고 한 줄씩 실행합니다. SSH 하나로 Jetson에 `gdbserver`를 띄우고 포트를 PC로 가져오므로, SSH 말고 따로 열 포트는 없습니다(SSH 포트가 22가 아니면 `-p 포트`). 디버그 정보와 라이브러리는 PC의 빌드 결과와 sysroot에서 읽습니다.

1. 디버그 빌드:
   ```bash
   jetson-build --debug
   ```
2. Jetson에 복사:
   ```bash
   jetson-deploy dev@<Jetson IP> /home/dev/myapp
   ```
3. 디버깅 시작. 프로젝트 폴더에서 실행합니다. 프로그램 인자는 `--` 뒤에 씁니다.
   ```bash
   jetson-debug dev@<Jetson IP> /home/dev/myapp/myapp -- --config test.json
   ```
4. gdb 화면에서 평소처럼 씁니다. 프로그램은 시작 직전에 멈춰 있습니다.
   ```text
   (gdb) break main
   (gdb) continue
   (gdb) next / step / print 변수 / bt
   (gdb) quit
   ```
   `quit`하면 Jetson의 프로그램과 `gdbserver`도 끝납니다. 프로그램 출력은 같은 터미널에 나옵니다.

- Jetson에 `gdbserver`가 있어야 합니다. holybro-build-image 이미지에는 들어 있고, 없으면 `sudo apt install gdbserver`.
- 2번에서 복사한 파일과 PC의 `build/jetson/install/bin/`의 파일이 같아야 합니다. 다시 빌드했으면 다시 복사합니다.
- DURU 워커처럼 Manager가 띄우는 프로그램은, 디버깅하는 동안 Manager에서 그 워커를 멈추고(`POST /workers/<id>/stop`) 위처럼 직접 띄웁니다.
- 첫 줄에 `channel ... open failed`가 한 번 보이는 것은 gdbserver가 열리기 전의 연결 확인이라 무시합니다.

## 라이브러리 추가

개발 환경에 없는 라이브러리를 쓸 때는 **PC의 sysroot와 Jetson에 같은 버전**이 있어야 합니다. 한쪽에만 있으면 PC에서는 빌드되고 Jetson에서는 `error while loading shared libraries`로 실행되지 않습니다.

| 라이브러리 | 방법 |
|---|---|
| 헤더만 있는 라이브러리(Eigen, nlohmann/json 등), 소스로 받는 라이브러리 | 프로젝트에 소스로 넣고 같이 빌드합니다(예: `third_party/`). 정적 링크되므로 Jetson에 설치할 것이 없습니다. **가장 간단합니다** |
| 제조사 SDK(XIMEA 등) | 그 워커·프로젝트가 SDK 파일을 갖고, 빌드용 헤더·라이브러리와 Jetson 설치를 함께 관리합니다(예: DURU `workers/ximea/install/`) |
| Ubuntu 패키지(Boost, protobuf 등) | 아래 절차 |

Ubuntu 패키지 추가 절차:

1. Jetson에서 패키지 이름과 버전을 확인합니다.
   ```bash
   apt-cache policy libboost-system-dev
   ```
2. `docker/sysroot-packages.txt`에 `-dev` 패키지를 추가합니다. Jetson의 버전과 다르게 잡히면 `docker/jetpack-6.2.2.list`에 `이름=버전`으로 고정합니다.
3. `VERSION`을 올리고 이미지를 다시 빌드합니다(`jetson-env build`). 팀원도 `git pull` 후 다시 빌드합니다.
4. Jetson에는 같은 버전의 실행용 패키지(`-dev`가 없는 것)를 설치합니다. DURU처럼 설치 스크립트가 있는 프로젝트는 그 스크립트에 넣습니다.
   ```bash
   sudo apt install libboost-system1.74.0
   ```
5. Jetson에서 `ldd <실행 파일> | grep "not found"`가 아무것도 출력하지 않는지 확인합니다.

## 환경 변경

1. `docker/Dockerfile`이나 `cmake/`를 고칩니다.
2. `VERSION`을 올립니다.
3. 팀원은 `git pull` 후 `jetson-env build`를 실행합니다.
4. 프로젝트의 `.jetson-dev-env`와 `.devcontainer/devcontainer.json`의 버전도 맞춥니다.

Dockerfile은 Ubuntu 22.04 저장소의 최신 패키지를 받으므로, 만드는 시점에 따라 패치 버전이 조금 다를 수 있습니다. 완전히 같게 맞추려면 한 사람이 만든 이미지를 `jetson-env save`로 전달합니다.

## JetPack 라이브러리 사용

`CMakeLists.txt`에서 평소처럼 찾으면 sysroot에서 찾아집니다. 전체 예제는 `template/jetpack-check/CMakeLists.txt`입니다.

```cmake
project(my_app LANGUAGES CXX CUDA)          # CUDA를 쓰면 언어에 추가

find_package(CUDAToolkit REQUIRED)          # CUDA::cudart, CUDA::cublas ...
find_package(OpenCV REQUIRED)               # ${OpenCV_LIBS}
find_package(PkgConfig REQUIRED)
pkg_check_modules(GST REQUIRED IMPORTED_TARGET gstreamer-1.0)   # PkgConfig::GST

find_library(NVINFER nvinfer REQUIRED)       # TensorRT
find_library(NVBUF nvbufsurface PATHS /usr/lib/aarch64-linux-gnu/nvidia REQUIRED)
find_path(NVBUF_INCLUDE nvbufsurface.h PATHS /usr/src/jetson_multimedia_api/include REQUIRED)
find_library(VPI nvvpi PATHS /opt/nvidia/vpi3/lib/aarch64-linux-gnu REQUIRED)
```

- 경로는 Jetson 기준으로 적습니다. 빌드할 때는 sysroot 아래에서 찾아집니다.
- CUDA 아키텍처는 기본 `sm_87`(Orin)입니다. 바꾸려면 `CMAKE_CUDA_ARCHITECTURES`를 지정합니다.
- GPU를 쓰는 코드는 PC의 QEMU 시험에서 동작하지 않습니다. Jetson에서 실행해 확인합니다.
- 다른 sysroot를 쓰려면 `JETSON_SYSROOT=/path jetson-build`로 지정합니다.

## JetPack 버전 변경

1. Jetson에서 새 버전의 패키지 목록을 얻습니다.

```bash
apt-get -s install nvidia-jetpack=<버전> | awk '/^Inst/{print $2"="$3}' | tr -d '('
```

2. 그 결과로 `docker/jetpack-<버전>.list`를 만들고, `Dockerfile`의 목록 파일 이름과 L4T 저장소(`L4T_RELEASE`), CUDA 크로스 컴파일러 버전을 맞춥니다.
3. `VERSION`을 올리고 이미지를 다시 빌드합니다.

## 문제 해결

| 증상 | 조치 |
|---|---|
| `Docker에 연결할 수 없습니다` | WSL Docker 엔진: Ubuntu 터미널에서 `sudo service docker start`. 한 번 `install.sh`를 다시 실행하면 자동 시작도 설정됨. Docker Desktop: 실행하고 WSL Integration 확인 |
| `permission denied ... docker.sock` | `docker` 그룹이 아직 적용 안 됨. Ubuntu 터미널을 닫고 다시 열기 |
| `jetson-build: command not found` | `install.sh`의 PATH 안내 실행 후 터미널 다시 열기 |
| `bad interpreter` | 줄바꿈이 CRLF로 바뀜. 저장소를 WSL 안에서 다시 받기 |
| 첫 빌드에서 `CMakeCache` 경로 오류 | 복사해 온 `build/` 폴더 삭제 후 다시 빌드 |
| Jetson에서 `GLIBC_x.xx not found` | `jetson-build`로 빌드했는지 확인 |
| `jetson-deploy`가 `Permission denied` | SSH 키 등록 확인. Git Bash와 PowerShell은 키를 두는 홈 폴더가 다를 수 있음 |
| `CMakeCache.txt` 등에 `Permission denied` (Docker Desktop에서 WSL Docker 엔진으로 바꾼 뒤) | Docker Desktop이 만든 `build/` 폴더가 WSL에서 root 소유로 보입니다. Windows 탐색기나 `sudo rm -rf build`로 `build/` 폴더를 지우고 다시 빌드 |
| WSL에서 `jetson-deploy`·`jetson-debug`가 `Permission denied (publickey)` | WSL에는 Windows의 SSH 키가 없습니다. WSL에서 `ssh-keygen -t ed25519`로 키를 만들어 Jetson에 등록(`ssh-copy-id`) |
| 빌드가 매우 느림 | 소스를 `/mnt/d`에서 WSL 안으로 옮기기 |
| `Permission denied`로 스크립트 실행 불가 | `git update-index --chmod=+x install.sh bin/*` 후 커밋 |
