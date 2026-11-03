#include <cstdio>
#include <cuda_runtime.h>

__global__ void add(const float* a, const float* b, float* c, int n) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];
}

int main() {
    constexpr int n = 1 << 20;
    float *a = nullptr, *b = nullptr, *c = nullptr;
    if (cudaMallocManaged(&a, n * sizeof(float)) != cudaSuccess ||
        cudaMallocManaged(&b, n * sizeof(float)) != cudaSuccess ||
        cudaMallocManaged(&c, n * sizeof(float)) != cudaSuccess) {
        std::printf("cuda: allocation failed (%s)\n", cudaGetErrorString(cudaGetLastError()));
        return 1;
    }
    for (int i = 0; i < n; ++i) {
        a[i] = 1.0f;
        b[i] = 2.0f;
    }
    add<<<(n + 255) / 256, 256>>>(a, b, c, n);
    const cudaError_t err = cudaDeviceSynchronize();
    if (err != cudaSuccess) {
        std::printf("cuda: kernel failed (%s)\n", cudaGetErrorString(err));
        return 1;
    }
    int wrong = 0;
    for (int i = 0; i < n; ++i) wrong += c[i] != 3.0f;

    cudaDeviceProp prop{};
    cudaGetDeviceProperties(&prop, 0);
    std::printf("cuda: %s (sm_%d%d), %d elements, %s\n", prop.name, prop.major, prop.minor, n,
                wrong == 0 ? "OK" : "WRONG RESULT");
    cudaFree(a);
    cudaFree(b);
    cudaFree(c);
    return wrong == 0 ? 0 : 1;
}
