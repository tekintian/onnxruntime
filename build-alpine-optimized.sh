#!/bin/bash
# ONNX Runtime Alpine 优化构建脚本
# 禁用所有不需要的依赖以加速构建

set -e

BUILD_DIR="${1:-/opt/onnxruntime}"
cd "$BUILD_DIR"

# 设置日志文件（在 build 目录下）
LOG_FILE="${BUILD_DIR}/build/build.log"
mkdir -p "${BUILD_DIR}/build"
echo "==========================================" | tee "$LOG_FILE"
echo "ONNX Runtime for Alpine - Optimized Build" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "日志文件: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 设置本地镜像加速（如果 LOCAL_MIRROR 已设置）
if [ -n "${LOCAL_MIRROR}" ]; then
    echo "✅ 启用本地镜像加速: ${LOCAL_MIRROR}"
    export onnxruntime_CMAKE_DEPS_MIRROR_DIR="/opt/deps"
    mkdir -p /opt/deps
    
    # 预下载所有依赖到本地目录（保持 GitHub URL 路径结构）
    if [ -f "/opt/php-configure-options.sh" ]; then
        . /opt/php-configure-options.sh
        
        echo "📦 预下载必需依赖..."
        
        # 辅助函数：创建目录并下载
        download_dep() {
            local url="$1"
            local path="${url#https://}"
            local local_path="/opt/deps/${path}"
            local dir=$(dirname "$local_path")
            mkdir -p "$dir"
            download "$url" "$local_path"
        }
        
        download_dep "https://github.com/abseil/abseil-cpp/archive/refs/tags/20250814.0.zip"
        download_dep "https://github.com/google/re2/archive/refs/tags/2024-07-02.zip"
        download_dep "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v21.12.zip"
        download_dep "https://github.com/HowardHinnant/date/archive/refs/tags/v3.0.1.zip"
        download_dep "https://github.com/eigen-mirror/eigen/archive/1d8b82b0740839c0de7f1242a3585e3390ff5f33/eigen-1d8b82b0740839c0de7f1242a3585e3390ff5f33.zip"
        download_dep "https://github.com/google/flatbuffers/archive/refs/tags/v23.5.26.zip"
        download_dep "https://github.com/onnx/onnx/archive/refs/tags/v1.21.0.zip"
        download_dep "https://github.com/nlohmann/json/archive/refs/tags/v3.11.3.zip"
        download_dep "https://github.com/microsoft/GSL/archive/refs/tags/v4.0.0.zip"
        download_dep "https://github.com/boostorg/mp11/archive/refs/tags/boost-1.82.0.zip"
        
        echo "✅ 依赖预下载完成"
        echo "📁 文件结构："
        find /opt/deps -type f | head -20
    fi
else
    echo "⚠️  未设置 LOCAL_MIRROR，将直接从 GitHub 下载"
fi

# 创建优化的 CMake 配置文件
cat > cmake/alpine_optimization.cmake << 'EOF'
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
EOF

echo "✅ Created Alpine optimization config"
echo "🚀 Starting build with optimized configuration..."

# 执行构建
bash ./build.sh \
    --config Release \
    --build_shared_lib \
    --parallel $(nproc) \
    --skip_tests \
    --disable_contrib_ops \
    --skip_submodule_sync \
    --allow_running_as_root \
    --cmake_extra_defines \
        "onnxruntime_BUILD_SHARED_LIB=ON" \
        "onnxruntime_USE_CUDA=OFF" \
        "onnxruntime_USE_ROCM=OFF" \
        "onnxruntime_USE_TENSORRT=OFF" \
        "onnxruntime_USE_OPENVINO=OFF" \
        "onnxruntime_USE_DNNL=OFF" \
        "onnxruntime_USE_DIRECTML=OFF" \
        "onnxruntime_USE_COREML=OFF" \
        "onnxruntime_USE_WINML=OFF" \
        "onnxruntime_USE_NNAPI_BUILTIN=OFF" \
        "onnxruntime_USE_KLEIDIAI=OFF" \
        "onnxruntime_USE_SVE=OFF" \
        "onnxruntime_USE_ARMNN=OFF" \
        "onnxruntime_USE_ACL=OFF" \
        "onnxruntime_USE_RKNPU=OFF" \
        "onnxruntime_USE_QNN=OFF" \
        "onnxruntime_USE_SNPE=OFF" \
        "onnxruntime_USE_VITISAI=OFF" \
        "onnxruntime_USE_CANN=OFF" \
        "onnxruntime_USE_MIGRAPHX=OFF" \
        "onnxruntime_ENABLE_PYTHON=OFF" \
        "onnxruntime_BUILD_UNIT_TESTS=OFF" \
        "onnxruntime_BUILD_BENCHMARKS=OFF" \
        "onnxruntime_ENABLE_TRAINING=OFF" \
        "onnxruntime_USE_XNNPACK=OFF" \
        "onnxruntime_USE_MIMALLOC=OFF" \
        "onnxruntime_ENABLE_LTO=OFF" \
        "onnxruntime_CMAKE_DEPS_MIRROR_DIR=/opt/deps" \
        "CMAKE_CXX_FLAGS=-Wno-maybe-uninitialized"

echo "✅ Build completed!" | tee -a "$LOG_FILE"
echo "📦 Checking output..." | tee -a "$LOG_FILE"
ls -lh "${BUILD_DIR}/build/Linux/Release/libonnxruntime*" 2>/dev/null | tee -a "$LOG_FILE" || echo "No libraries found" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "📄 Full build log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "💡 To view errors: grep -i 'error' $LOG_FILE | tail -20" | tee -a "$LOG_FILE"
