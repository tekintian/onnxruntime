# Alpine Linux 优化配置 - 禁用所有不需要的依赖

# GPU 相关 - 全部禁用
set(onnxruntime_USE_CUDA OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_ROCM OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_TENSORRT OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_OPENVINO OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_DNNL OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_DIRECTML OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_COREML OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_WINML OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_NNAPI_BUILTIN OFF CACHE BOOL "" FORCE)

# ARM/移动平台特定 - 全部禁用
set(onnxruntime_USE_KLEIDIAI OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_SVE OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_ARMNN OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_ACL OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_RKNPU OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_QNN OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_SNPE OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_VITISAI OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_CANN OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_MIGRAPHX OFF CACHE BOOL "" FORCE)

# WebAssembly - 禁用
set(onnxruntime_BUILD_WEBASSEMBLY_STATIC_LIB OFF CACHE BOOL "" FORCE)
set(onnxruntime_ENABLE_WEBASSEMBLY_EXCEPTION_CATCHING OFF CACHE BOOL "" FORCE)
set(onnxruntime_ENABLE_WEBASSEMBLY_THREADS OFF CACHE BOOL "" FORCE)

# Python/语言绑定 - 禁用（我们只需要 C 库）
set(onnxruntime_ENABLE_PYTHON OFF CACHE BOOL "" FORCE)
set(onnxruntime_BUILD_CSHARP OFF CACHE BOOL "" FORCE)
set(onnxruntime_BUILD_JAVA OFF CACHE BOOL "" FORCE)
set(onnxruntime_BUILD_NODEJS OFF CACHE BOOL "" FORCE)
set(onnxruntime_BUILD_OBJC OFF CACHE BOOL "" FORCE)

# 测试和基准 - 禁用
set(onnxruntime_BUILD_UNIT_TESTS OFF CACHE BOOL "" FORCE)
set(onnxruntime_BUILD_BENCHMARKS OFF CACHE BOOL "" FORCE)
set(onnxruntime_RUN_ONNX_TESTS OFF CACHE BOOL "" FORCE)

# 训练相关 - 禁用
set(onnxruntime_ENABLE_TRAINING OFF CACHE BOOL "" FORCE)
set(onnxruntime_ENABLE_TRAINING_OPS OFF CACHE BOOL "" FORCE)
set(onnxruntime_ENABLE_TRAINING_APIS OFF CACHE BOOL "" FORCE)

# 其他可选功能 - 禁用
set(onnxruntime_USE_XNNPACK OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_WEBNN OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_WEBGPU OFF CACHE BOOL "" FORCE)
set(onnxruntime_USE_MIMALLOC OFF CACHE BOOL "" FORCE)
set(onnxruntime_ENABLE_LTO OFF CACHE BOOL "" FORCE)  # 禁用 LTO 以避免 Alpine/musl 链接问题

# 只启用必要的
set(onnxruntime_BUILD_SHARED_LIB ON CACHE BOOL "" FORCE)
set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)

message(STATUS "✅ Alpine optimization applied - disabled unnecessary dependencies")
