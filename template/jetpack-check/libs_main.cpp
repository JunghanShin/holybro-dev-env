// JetPack 라이브러리 버전 출력. Jetson에 JetPack 런타임이 설치되어 있어야 실행된다.
#include <NvInfer.h>
#include <cudnn.h>
#include <cuda_runtime.h>
#include <gst/gst.h>
#include <nvbufsurface.h>
#include <vpi/Version.h>

#include <cstdio>
#include <opencv2/core.hpp>

int main(int argc, char* argv[]) {
    int runtime = 0;
    cudaRuntimeGetVersion(&runtime);
    std::printf("cudart    : %d.%d\n", runtime / 1000, (runtime % 1000) / 10);

    const int32_t trt = getInferLibVersion();
    std::printf("TensorRT  : %d.%d.%d\n", trt / 10000, (trt / 100) % 100, trt % 100);

    std::printf("cuDNN     : %zu\n", cudnnGetVersion());
    const int vpi = vpiGetVersion();  // major*1000000 + minor*1000 + patch
    std::printf("VPI       : %d.%d.%d\n", vpi / 1000000, (vpi / 1000) % 1000, vpi % 1000);
    std::printf("OpenCV    : %s\n", cv::getVersionString().c_str());

    gst_init(&argc, &argv);
    std::printf("GStreamer : %s\n", gst_version_string());

    NvBufSurfaceAllocateParams params{};
    params.params.width = 640;
    params.params.height = 480;
    params.params.colorFormat = NVBUF_COLOR_FORMAT_NV12;
    params.params.layout = NVBUF_LAYOUT_PITCH;
    params.params.memType = NVBUF_MEM_SURFACE_ARRAY;
    params.memtag = NvBufSurfaceTag_NONE;
    NvBufSurface* surface = nullptr;
    const int rc = NvBufSurfaceAllocate(&surface, 1, &params);
    std::printf("NvBufSurf : %s\n", rc == 0 ? "allocated 640x480 NV12" : "allocation failed");
    if (rc == 0) NvBufSurfaceDestroy(surface);
    return rc == 0 ? 0 : 1;
}
