# Jetson(aarch64, Ubuntu 22.04)용 크로스 컴파일 설정.
# Jetson 전용 라이브러리(CUDA, Multimedia API 등)가 필요하면 환경 변수 JETSON_SYSROOT에 sysroot 경로를 지정한다.
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

if(DEFINED ENV{JETSON_SYSROOT})
    set(CMAKE_SYSROOT $ENV{JETSON_SYSROOT})
    set(CMAKE_FIND_ROOT_PATH $ENV{JETSON_SYSROOT} /usr/aarch64-linux-gnu)
else()
    set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)
endif()

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# ctest가 ARM64 시험 바이너리를 PC에서 QEMU로 실행한다.
set(CMAKE_CROSSCOMPILING_EMULATOR qemu-aarch64 -L /usr/aarch64-linux-gnu)
