cmake_minimum_required(VERSION 3.16)
project(hello LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(hello main.cpp)
target_compile_options(hello PRIVATE -Wall -Wextra -Wpedantic)

# holybro-deploy는 install 규칙으로 설치된 실행 파일을 복사한다.
install(TARGETS hello RUNTIME DESTINATION bin)

enable_testing()
add_test(NAME hello_runs COMMAND hello)
