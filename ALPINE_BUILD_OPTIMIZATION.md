# ONNX Runtime Alpine Linux 构建优化指南

## 概述

本文档说明如何在 Alpine Linux 平台上优化 ONNX Runtime 的构建，通过禁用不需要的依赖来加速编译过程并减小最终库的大小。

## Alpine x86_64 平台不需要的依赖

### 1. GPU 加速器（全部禁用）
- **CUDA/cuDNN**: NVIDIA GPU 支持
- **TensorRT**: NVIDIA 推理优化
- **ROCm**: AMD GPU 支持
- **OpenVINO**: Intel GPU/VPU 支持
- **DirectML**: Windows DirectX ML
- **CoreML**: Apple Core ML
- **WINML**: Windows ML

### 2. ARM/移动平台特定（全部禁用）
- **KLEIDIAI**: ARM Kleidi AI 优化库
- **SVE**: ARM Scalable Vector Extension
- **ARMNN**: ARM NN 框架
- **ACL**: ARM Compute Library
- **RKNPU**: Rockchip NPU
- **QNN**: Qualcomm Neural Network
- **SNPE**: Snapdragon NPE
- **VITISAI**: Xilinx Vitis AI
- **CANN**: Huawei Ascend NPU
- **MIGRAPHX**: AMD MIGraphX

### 3. WebAssembly（禁用）
- Emscripten 相关的所有功能
- WASM 线程支持
- WASM 异常处理

### 4. 语言绑定（只保留 C API）
- **Python**: pybind11（不需要 Python 绑定）
- **C#**: .NET 绑定
- **Java**: JNI 绑定
- **Node.js**: JavaScript 绑定
- **Objective-C**: macOS/iOS 绑定

### 5. 测试和开发工具（禁用）
- **googletest**: 单元测试框架
- **google_benchmark**: 性能基准测试
- **ONNX tests**: ONNX 兼容性测试

### 6. 训练功能（禁用）
- 训练 API
- 训练操作符
- NCCL 分布式训练

### 7. 其他可选功能（禁用）
- **XNNPACK**: Google 神经网络库（可选，但会增加依赖）
- **WebNN**: Web Neural Network API
- **WebGPU**: Web GPU API
- **mimalloc**: Microsoft 内存分配器（使用系统 malloc 即可）

## 必需的依赖

以下依赖是构建 ONNX Runtime CPU 版本所必需的：

1. **abseil-cpp**: Google C++ 基础库
2. **protobuf**: Protocol Buffers（ONNX 模型格式）
3. **re2**: 正则表达式库
4. **flatbuffers**: 序列化库
5. **Eigen**: 线性代数库
6. **onnx**: ONNX 格式定义
7. **date**: Howard Hinnant 的日期库
8. **nlohmann/json**: JSON 库
9. **GSL**: Guidelines Support Library
10. **MP11**: Boost Meta-Programming Library

## 构建步骤

### 方法 1: 使用优化脚本（推荐）

```bash
cd /opt/onnxruntime
chmod +x build-alpine-optimized.sh
./build-alpine-optimized.sh
```

### 方法 2: 手动构建

```bash
cd /opt/onnxruntime

bash ./build.sh \
    --config Release \
    --build_shared_lib \
    --parallel $(nproc) \
    --skip_tests \
    --skip_submodule_sync \
    --allow_running_as_root \
    --cmake_extra_defines \
        onnxruntime_BUILD_SHARED_LIB=ON \
        onnxruntime_USE_CUDA=OFF \
        onnxruntime_USE_ROCM=OFF \
        onnxruntime_USE_TENSORRT=OFF \
        onnxruntime_USE_OPENVINO=OFF \
        onnxruntime_USE_DNNL=OFF \
        onnxruntime_USE_DIRECTML=OFF \
        onnxruntime_USE_COREML=OFF \
        onnxruntime_USE_WINML=OFF \
        onnxruntime_USE_NNAPI_BUILTIN=OFF \
        onnxruntime_USE_KLEIDIAI=OFF \
        onnxruntime_USE_SVE=OFF \
        onnxruntime_USE_ARMNN=OFF \
        onnxruntime_USE_ACL=OFF \
        onnxruntime_USE_RKNPU=OFF \
        onnxruntime_USE_QNN=OFF \
        onnxruntime_USE_SNPE=OFF \
        onnxruntime_USE_VITISAI=OFF \
        onnxruntime_ENABLE_PYTHON=OFF \
        onnxruntime_BUILD_UNIT_TESTS=OFF \
        onnxruntime_BUILD_BENCHMARKS=OFF \
        onnxruntime_ENABLE_TRAINING=OFF \
        onnxruntime_USE_XNNPACK=OFF \
        onnxruntime_USE_MIMALLOC=OFF \
        onnxruntime_ENABLE_LTO=ON
```

## Docker 构建注意事项

在 Dockerfile 中构建时，需要确保安装以下系统依赖：

```dockerfile
RUN apk add --no-cache \
    curl bash cmake build-base python3 py3-pip linux-headers git wget
```

**关键点：**
- `git`: 用于子模块管理
- `wget`: CMake FetchContent 下载依赖时需要
- `bash`: build.sh 脚本需要 bash（不是 sh）
- `python3`: 构建脚本基于 Python

## 预期效果

### 构建时间优化
- **优化前**: 40-70 分钟（下载大量不必要的依赖）
- **优化后**: 20-40 分钟（减少约 50% 的依赖下载）

### 镜像大小优化
- **优化前**: ~500MB（包含所有依赖）
- **优化后**: ~200-300MB（仅必需依赖）

### 运行时依赖
最终生成的 `libonnxruntime.so` 只需要：
- libc (musl)
- libstdc++
- libgcc

## 常见问题

### Q: 为什么 abseil-cpp 下载失败？
A: 确保安装了 `wget`，CMake FetchContent 需要它来下载外部依赖。

### Q: 为什么提示 "dubious ownership"？
A: 在 Docker 中以 root 用户解压文件时会出现此警告。解决方法：
```bash
git config --global --add safe.directory /opt/onnxruntime
```

### Q: 可以使用本地镜像加速依赖下载吗？
A: 可以。设置环境变量：
```bash
export onnxruntime_CMAKE_DEPS_MIRROR_DIR="http://your-mirror-server/deps"
```

### Q: 是否需要 flatbuffers Python 包？
A: 不需要。我们只构建 C/C++ 库，不需要 Python 绑定。如果构建脚本抱怨，可以忽略或安装：
```bash
pip3 install flatbuffers
```

## 验证构建

构建完成后，检查输出文件：

```bash
ls -lh /opt/onnxruntime/build/Linux/Release/libonnxruntime.so*
```

应该看到类似：
```
libonnxruntime.so -> libonnxruntime.so.1
libonnxruntime.so.1 -> libonnxruntime.so.1.25.0
libonnxruntime.so.1.25.0
```

测试库是否可以加载：
```bash
ldd /opt/onnxruntime/build/Linux/Release/libonnxruntime.so
```

## 进一步优化建议

1. **使用 LTO (Link Time Optimization)**: 已启用，可以减小库大小并提高性能
2. **strip 符号表**: 构建后执行 `strip --strip-unneeded libonnxruntime.so`
3. **压缩库**: 使用 `upx` 进一步压缩（可能影响加载速度）
4. **自定义算子**: 如果只需要特定算子，可以配置最小化构建

## 参考资料

- [ONNX Runtime Build Instructions](https://onnxruntime.ai/docs/build/)
- [ONNX Runtime CMake Options](https://onnxruntime.ai/docs/build/custom.html)
- [Alpine Linux Package Management](https://wiki.alpinelinux.org/wiki/Alpine_package_management)
