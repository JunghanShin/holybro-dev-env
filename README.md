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

보드 쪽도 같은 버전이어야 합니다. Holybro 캐리어 보드는 [holybro-build-image](https://github.com/JunghanShin/holybro-build-image)로 이미지를 만들면 같은 목록(`jetpack-6.2.2.list`)으로 JetPack 런타임이 들어갑니다. 다른 보드는 `sudo apt install nvidia-jetpack-runtime=6.2.2+b24`처럼 **버전을 지정해** 설치합니다. NVIDIA 저장소에는 6.2.3도 있어서 버전을 빼면 다른 버전이 설치됩니다.

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

명령을 등록하고 Docker 이미지를 빌드합니다. NVIDIA와 Ubuntu 저장소에서 JetPack 패키지를 약 2.7GB 내려받습니다. 처음에는 20분 안팎 걸리고, 이미지는 약 17GB입니다.

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

SSH 포트가 22가 아니면 두 명령 모두 `-p 포트`를 붙입니다(`jetson-deploy -p 10001 ...`, `ssh -p 10001 ...`).

```bash
jetson-deploy user@<JETSON_IP> /home/user/hello
```

```bash
ssh user@<JETSON_IP> /home/user/hello/hello
```

`hello from ... (aarch64)`가 출력되면 Jetson에서도 정상 실행되는 것입니다.

### Jetson에 JetPack 런타임 설치

JetPack 라이브러리를 쓰는 프로그램을 **실행**하려면 Jetson에도 같은 버전의 런타임이 있어야 합니다. L4T만 설치된 보드에는 TensorRT, cuDNN, VPI, OpenCV, CUDA 런타임이 없습니다. Jetson에서 한 번 설치합니다.

```bash
sudo apt update && sudo apt install nvidia-jetpack-runtime=6.2.2+b24
```

CUDA 런타임(cudart)은 정적 링크하면 설치 없이도 실행됩니다. GPU 드라이버(`libcuda`)와 Multimedia API 런타임은 L4T에 들어 있습니다. `jetpack-check`의 `check-cuda`는 런타임 없이, `check-libs`는 런타임을 설치한 뒤 실행됩니다.

## 구성

```text
jetson-dev-env/
├─ install.sh                 # 명령 등록, 이미지 빌드
├─ VERSION                    # 환경 버전 (이미지 태그)
├─ bin/
│  ├─ jetson-env              # 이미지, 컨테이너 관리
│  ├─ jetson-build            # 크로스 컴파일, 시험
│  └─ jetson-deploy           # Jetson에 복사
├─ docker/
│  ├─ Dockerfile              # 빌드 환경 정의
│  ├─ jetpack-6.2.2.list      # JetPack 패키지 버전 고정 목록
│  └─ sysroot-packages.txt    # sysroot에 넣는 패키지
├─ cmake/jetson-toolchain.cmake  # 컴파일러, sysroot, CUDA, pkg-config 설정
└─ template/
   ├─ hello/                  # 가장 단순한 C++ 프로젝트
   └─ jetpack-check/          # CUDA와 JetPack 라이브러리 사용 예제
```

`install.sh`는 `~/.local/bin`에 명령 3개를 등록합니다. 시스템 폴더는 건드리지 않습니다. 명령은 현재 폴더의 프로젝트를 컨테이너에 마운트해 빌드하므로, 어느 프로젝트에서든 같은 명령을 씁니다.

## 사용법

| 명령 | 내용 |
|---|---|
| `jetson-build` | 현재 폴더를 Jetson용으로 빌드 |
| `jetson-build --test` | 빌드 후 시험 (ARM64를 QEMU로 실행) |
| `jetson-build --native --debug --test` | PC용 디버그 빌드와 시험 |
| `jetson-build --clean` | 빌드 폴더를 지우고 빌드 |
| `jetson-deploy [-p PORT] USER@HOST DIR` | 실행 파일을 Jetson에 복사. 실행 중인 파일도 교체 가능 |
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
| `Docker에 연결할 수 없습니다` | Docker를 실행하고 WSL Integration 확인 |
| `jetson-build: command not found` | `install.sh`의 PATH 안내 실행 후 터미널 다시 열기 |
| `bad interpreter` | 줄바꿈이 CRLF로 바뀜. 저장소를 WSL 안에서 다시 받기 |
| 첫 빌드에서 `CMakeCache` 경로 오류 | 복사해 온 `build/` 폴더 삭제 후 다시 빌드 |
| Jetson에서 `GLIBC_x.xx not found` | `jetson-build`로 빌드했는지 확인 |
| `jetson-deploy`가 `Permission denied` | SSH 키 등록 확인. Git Bash와 PowerShell은 키를 두는 홈 폴더가 다를 수 있음 |
| 빌드가 매우 느림 | 소스를 `/mnt/d`에서 WSL 안으로 옮기기 |
| `Permission denied`로 스크립트 실행 불가 | `git update-index --chmod=+x install.sh bin/*` 후 커밋 |
