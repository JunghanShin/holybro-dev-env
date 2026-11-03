# Jetson(JetPack 6.2.2, aarch64, Ubuntu 22.04)용 크로스 컴파일 설정.
# sysroot에는 CUDA, TensorRT, cuDNN, VPI, Multimedia API, OpenCV, GStreamer가 들어 있다.
# 다른 sysroot를 쓰려면 환경 변수 JETSON_SYSROOT를 지정한다.
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

if(DEFINED ENV{JETSON_SYSROOT})
    set(JETSON_SYSROOT $ENV{JETSON_SYSROOT})
else()
    set(JETSON_SYSROOT /opt/jetson/sysroot)
endif()
set(CMAKE_SYSROOT ${JETSON_SYSROOT})
set(CMAKE_FIND_ROOT_PATH ${JETSON_SYSROOT})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Jetson 라이브러리가 서로를 찾을 수 있게 링크 검색 경로를 더한다(libnvinfer → libcudart 등).
# Jetson의 동적 링커와 같은 목록을 쓰도록 sysroot의 /etc/ld.so.conf.d를 읽는다.
set(_jetson_link_dirs
    ${JETSON_SYSROOT}/usr/lib/aarch64-linux-gnu
    ${JETSON_SYSROOT}/usr/local/cuda-12.6/targets/aarch64-linux/lib)
file(GLOB _jetson_ld_confs ${JETSON_SYSROOT}/etc/ld.so.conf.d/*.conf)
foreach(conf ${_jetson_ld_confs})
    file(STRINGS ${conf} _lines REGEX "^/")
    foreach(dir ${_lines})
        string(STRIP "${dir}" dir)
        list(APPEND _jetson_link_dirs ${JETSON_SYSROOT}${dir})
    endforeach()
endforeach()
list(REMOVE_DUPLICATES _jetson_link_dirs)
set(_jetson_link_flags "")
foreach(dir ${_jetson_link_dirs})
    string(APPEND _jetson_link_flags " -Wl,-rpath-link,${dir}")
endforeach()
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_jetson_link_flags}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${_jetson_link_flags}")

# CUDA: PC에서 도는 nvcc가 ARM64 코드를 만든다. Orin의 GPU 아키텍처는 sm_87.
set(CMAKE_CUDA_COMPILER /usr/local/cuda-12.6/bin/nvcc)
set(CMAKE_CUDA_HOST_COMPILER aarch64-linux-gnu-g++)
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES 87)
endif()
set(CUDAToolkit_ROOT /usr/local/cuda-12.6)

# pkg-config(GStreamer, OpenCV 등)가 sysroot의 .pc 파일을 읽게 한다.
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${JETSON_SYSROOT})
set(ENV{PKG_CONFIG_LIBDIR} "${JETSON_SYSROOT}/usr/lib/aarch64-linux-gnu/pkgconfig:${JETSON_SYSROOT}/usr/share/pkgconfig:${JETSON_SYSROOT}/usr/lib/pkgconfig")

# ctest가 ARM64 시험 바이너리를 PC에서 QEMU로 실행한다(GPU 기능은 Jetson에서만 동작).
set(CMAKE_CROSSCOMPILING_EMULATOR qemu-aarch64 -L ${JETSON_SYSROOT})
