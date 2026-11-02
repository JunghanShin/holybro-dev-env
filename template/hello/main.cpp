#include <sys/utsname.h>

#include <cstdio>

int main() {
    utsname info{};
    uname(&info);
    std::printf("hello from %s (%s)\n", info.nodename, info.machine);
    return 0;
}
