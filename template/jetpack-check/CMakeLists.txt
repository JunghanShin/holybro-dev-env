# JetPack 라이브러리를 각각 링크해 보는 예제. 환경 점검과 CMake 사용 예시로 쓴다.
cmake_minimum_required(VERSION 3.18)
project(jetpack_check LANGUAGES C CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(CUDAToolkit REQUIRED)
find_package(OpenCV REQUIRED COMPONENTS core imgproc)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GST REQUIRED IMPORTED_TARGET gstreamer-1.0)

find_path(TENSORRT_INCLUDE NvInfer.h REQUIRED)
find_library(NVINFER nvinfer REQUIRED)
find_path(CUDNN_INCLUDE cudnn.h REQUIRED)
find_library(CUDNN cudnn REQUIRED)
find_path(VPI_INCLUDE vpi/Version.h PATHS /opt/nvidia/vpi3/include REQUIRED)
find_library(VPI nvvpi PATHS /opt/nvidia/vpi3/lib/aarch64-linux-gnu REQUIRED)
find_path(NVBUF_INCLUDE nvbufsurface.h PATHS /usr/src/jetson_multimedia_api/include REQUIRED)
find_library(NVBUF nvbufsurface PATHS /usr/lib/aarch64-linux-gnu/nvidia REQUIRED)

# CUDA: 커널을 실제로 실행한다. cudart는 정적 링크라 Jetson에 CUDA 런타임이 없어도 된다.
add_executable(check-cuda cuda_main.cu)
set_target_properties(check-cuda PROPERTIES CUDA_RUNTIME_LIBRARY Static)

# 나머지: 라이브러리를 불러와 버전을 출력한다.
add_executable(check-libs libs_main.cpp)
target_include_directories(check-libs PRIVATE ${TENSORRT_INCLUDE} ${CUDNN_INCLUDE} ${VPI_INCLUDE} ${NVBUF_INCLUDE})
target_link_libraries(check-libs PRIVATE
    CUDA::cudart ${NVINFER} ${CUDNN} ${VPI} ${NVBUF} ${OpenCV_LIBS} PkgConfig::GST)

install(TARGETS check-cuda check-libs RUNTIME DESTINATION bin)
