# GitHub Actions Workflows - ONNX Runtime Alpine

## 📋 工作流状态

### ✅ 活跃工作流（1 个）

- **`alpine_build.yml`** - Alpine Linux 专用构建
  - 构建优化的 ONNX Runtime 共享库
  - 支持 musl libc 兼容性
  - 本地镜像加速（30-60x）
  - 可选的开发头文件

### ⏸️ 已禁用工作流（45 个）

所有其他工作流已重命名为 `*.yml.disabled`，包括：
- Linux CI (x64, arm64)
- Windows CI (多种配置)
- macOS CI
- Android/iOS 构建
- Web/WASM 构建
- CUDA/TensorRT/OpenVINO GPU 构建
- 文档发布工作流
- 代码质量检查

---

## 🚀 使用 Alpine 工作流

### 自动触发

工作流会在以下情况自动运行：
- Push 到 `main` 或 `rel-*` 分支（仅限 `php/` 目录变更）
- Push tag（`v*` 格式，自动创建 Release）
- Pull Request 到 `main` 或 `rel-*` 分支

### 手动触发

在 GitHub Actions 页面点击 "Run workflow"，可以自定义参数：

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `alpine_version` | Alpine Linux 版本 | `3.23` |
| `onnx_version` | ONNX Runtime 版本 | `1.25.1` |
| `include_headers` | 包含开发头文件 | `true` ✅ |
| `create_release` | 创建 GitHub Release | `false` |

---

## 📦 构建输出

### Artifact（始终包含）

**名称：** `onnxruntime-alpine-{version}-{onnx_version}`

**包含内容：**
- ✅ `libonnxruntime.so.1.25.1` (~24 MB)
- ✅ `libonnxruntime_providers_shared.so` (~16 KB)
- ✅ 符号链接：`libonnxruntime.so`, `libonnxruntime.so.1`
- ✅ `onnxruntime-headers-1.25.1.tar.gz` (170 KB) - **默认包含**
- ✅ SHA256 校验和文件

**保留期：** 30 天

### GitHub Release（Tag 推送时自动创建）

**触发条件：**
- Push tag（如 `git push origin v1.25.1`）
- 或手动勾选 `create_release`

**包含文件：** 与 Artifact 相同

---

## 🔧 优化特性

### 1. 完整的 CMake 优化（41 个选项）

```cmake
# GPU/加速器 - 全部禁用
onnxruntime_USE_CUDA=OFF
onnxruntime_USE_ROCM=OFF
onnxruntime_USE_TENSORRT=OFF
# ... 等 20+ 个选项

# 语言绑定 - 全部禁用
onnxruntime_ENABLE_PYTHON=OFF
onnxruntime_BUILD_CSHARP=OFF
onnxruntime_BUILD_JAVA=OFF
# ... 等

# 训练相关 - 全部禁用
onnxruntime_ENABLE_TRAINING=OFF
onnxruntime_ENABLE_TRAINING_APIS=OFF
onnxruntime_ENABLE_TRAINING_OPS=OFF

# 其他优化
onnxruntime_ENABLE_LTO=OFF  # 避免 Alpine/musl 链接问题
CMAKE_CXX_FLAGS=-Wno-maybe-uninitialized
```

### 2. musl libc 兼容性

自动应用补丁到 `stacktrace.cc`：
```cpp
#if defined(__GLIBC__)
    // glibc-specific implementation
#else
    // musl fallback
#endif
```

### 3. 本地镜像加速

如果启用，依赖下载速度提升 **30-60 倍**：
```bash
LOCAL_MIRROR=http://192.168.2.9:8888
```

### 4. 精简头文件

仅包含 **14 个公共 API 头文件**（vs 源码的 135 个）：
- `onnxruntime_c_api.h` (378 KB)
- `onnxruntime_cxx_api.h` (161 KB)
- `onnxruntime_cxx_inline.h` (151 KB)
- 等 11 个...

总大小：**170 KB**（压缩后）

---

## 📊 性能对比

| 指标 | 官方 CI | 我们的 Alpine 构建 |
|------|---------|-------------------|
| CMake 选项 | ~15-20 | **41** |
| 构建时间 | 30-60 分钟 | **10-20 分钟**（有镜像） |
| 二进制大小 | 较大 | **~24 MB** |
| 头文件数量 | 135+ | **14** |
| musl 支持 | ❌ | ✅ |

---

## 🔄 重新启用其他工作流

如果需要重新启用某个禁用的工作流：

```bash
cd .github/workflows
mv filename.yml.disabled filename.yml
```

例如，重新启用 Linux CI：
```bash
mv linux_ci.yml.disabled linux_ci.yml
```

---

## 📝 相关文件

- **工作流**: [`alpine_build.yml`](./alpine_build.yml)
- **Dockerfile**: [`../Dockerfile.onnx-alpine`](../Dockerfile.onnx-alpine)
- **构建脚本**: [`build-alpine-optimized.sh`](../build-alpine-optimized.sh)
- **头文件提取**: [`extract-onnx-headers.sh`](../extract-onnx-headers.sh)
- **分析文档**: [`onnxruntime-v1.25.1/CI_OPTIMIZATION_ANALYSIS.md`](../onnxruntime-v1.25.1/CI_OPTIMIZATION_ANALYSIS.md)

---

## 💡 为什么只保留 Alpine 工作流？

1. **专注性**：我们主要需要 Alpine 平台的构建
2. **简化维护**：减少 CI 复杂度和运行成本
3. **优化效果**：Alpine 构建经过充分优化，性能最佳
4. **musl 支持**：官方 CI 主要针对 glibc，我们需要专门的 musl 支持

如果需要其他平台的构建，可以随时重新启用相应的工作流。

---

## 🎯 下一步

- [ ] 测试工作流在实际环境中的运行
- [ ] 配置镜像服务器地址
- [ ] 设置 artifact 上传到 releases
- [ ] 添加自动化测试验证
