# Alpine CI 工作流 - 构建产物说明

## 🎯 工作流类型

这是一个**原生构建工作流**，不是 Docker 镜像构建工作流。

### 执行环境
```yaml
runs-on: ubuntu-latest
container:
  image: alpine:3.23
  options: --user root
```

**说明：**
- 在 Ubuntu runner 上启动 Alpine 容器
- 所有构建步骤在 Alpine 容器内执行
- 使用真实的 musl libc 环境

---

## 📦 构建产物

### 1. 共享库文件

**主库：**
```
libonnxruntime.so.1.25.1    (~24 MB)
libonnxruntime.so.1         → libonnxruntime.so.1.25.1 (符号链接)
libonnxruntime.so           → libonnxruntime.so.1 (符号链接)
```

**提供者库：**
```
libonnxruntime_providers_shared.so    (~16 KB)
```

### 2. 开发头文件（可选）

```
onnxruntime-headers-1.25.1.tar.gz     (170 KB)
onnxruntime-headers-1.25.1.tar.gz.sha256
```

**包含 14 个公共 API 头文件：**
- `onnxruntime_c_api.h` (378 KB)
- `onnxruntime_cxx_api.h` (161 KB)
- `onnxruntime_cxx_inline.h` (151 KB)
- `cpu_provider_factory.h`
- `core/providers/custom_op_context.h`
- `core/providers/resource.h`
- 等 8 个...

---

## 🔧 构建过程

### 1. 安装依赖
```bash
apk add --no-cache \
  curl bash cmake build-base python3 py3-pip \
  linux-headers git wget xz tar findutils
```

### 2. 应用 musl 补丁
```bash
sed -i 's/.../__GLIBC__/' onnxruntime/core/platform/posix/stacktrace.cc
```

### 3. 执行构建
```bash
bash ./build.sh \
  --config Release \
  --build_shared_lib \
  --parallel $(nproc) \
  --skip_tests \
  --disable_contrib_ops \
  --cmake_extra_defines \
    "onnxruntime_BUILD_SHARED_LIB=ON" \
    "onnxruntime_USE_CUDA=OFF" \
    # ... 共 41 个优化选项
```

### 4. 验证输出
```bash
ls -lh build/Linux/Release/libonnxruntime*.so
```

### 5. 打包头文件
```bash
tar -czf onnxruntime-headers-1.25.1.tar.gz include/
sha256sum onnxruntime-headers-1.25.1.tar.gz > .sha256
```

### 6. 上传 Artifact
```yaml
uses: actions/upload-artifact@v4
with:
  name: onnxruntime-alpine-3.23-1.25.1
  path: artifacts/
```

---

## 📊 与 Docker 镜像构建的对比

| 特性 | 原生构建（当前） | Docker 镜像构建 |
|------|-----------------|----------------|
| 执行环境 | Alpine 容器 | Docker daemon |
| 输出产物 | .so 文件 + 头文件 | Docker 镜像 |
| 用途 | 分发库文件 | 直接运行应用 |
| 灵活性 | 高（可集成到任何项目） | 低（需要 Docker） |
| 文件大小 | ~24 MB | ~50-100 MB（含基础镜像） |
| 适用场景 | SDK 分发、嵌入式 | 微服务、容器化应用 |

---

## 🚀 使用构建产物

### 方法 1：下载 Artifact

1. 进入 GitHub Actions 页面
2. 选择最近的成功构建
3. 下载 `onnxruntime-alpine-3.23-1.25.1` artifact
4. 解压后得到所有库文件和头文件

### 方法 2：在自己的项目中使用

```dockerfile
FROM alpine:3.23

# 复制构建产物
COPY libonnxruntime.so* /usr/local/lib/
COPY libonnxruntime_providers_shared.so /usr/local/lib/

# 如果使用 C++ 开发，复制头文件
RUN apk add --no-cache tar
COPY onnxruntime-headers-1.25.1.tar.gz /tmp/
RUN tar -xzf /tmp/onnxruntime-headers-1.25.1.tar.gz -C /usr/local/ && \
    rm /tmp/onnxruntime-headers-1.25.1.tar.gz

# 更新库缓存
RUN ldconfig

# 设置环境变量
ENV LD_LIBRARY_PATH=/usr/local/lib
```

### 方法 3：编译时使用

```bash
# C++ 编译示例
g++ -std=c++17 \
  -I/path/to/include \
  -L/path/to/lib \
  -lonnxruntime \
  -o my_app my_app.cpp

# 运行时
export LD_LIBRARY_PATH=/path/to/lib:$LD_LIBRARY_PATH
./my_app
```

---

## ⚙️ 配置参数

### 输入参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `alpine_version` | `3.23` | Alpine Linux 版本 |
| `onnx_version` | `1.25.1` | ONNX Runtime 版本 |
| `include_headers` | `true` | 是否包含开发头文件 |

### 环境变量

```yaml
ALPINE_VERSION: ${{ inputs.alpine_version }}
ONNX_VERSION: ${{ inputs.onnx_version }}
INCLUDE_HEADERS: ${{ inputs.include_headers }}
```

---

## 📁 Artifact 结构

```
artifacts/
├── libonnxruntime.so                    # 符号链接
├── libonnxruntime.so.1                  # 符号链接
├── libonnxruntime.so.1.25.1             # 主库文件 (~24 MB)
├── libonnxruntime_providers_shared.so   # 提供者库 (~16 KB)
├── onnxruntime-headers-1.25.1.tar.gz    # 头文件包 (170 KB, 可选)
└── onnxruntime-headers-1.25.1.tar.gz.sha256  # 校验和
```

---

## ✅ 验证清单

构建完成后，检查以下内容：

- [ ] `libonnxruntime.so.1.25.1` 存在且大小约 24 MB
- [ ] `libonnxruntime_providers_shared.so` 存在且大小约 16 KB
- [ ] 符号链接正确指向主库文件
- [ ] 如果启用，头文件包包含 14 个头文件
- [ ] SHA256 校验和文件存在
- [ ] Artifact 可以成功下载和解压

---

## 💡 优势

### 相比 Docker 镜像构建

1. **更小的体积**
   - 只输出必要的库文件（~24 MB）
   - 不包含操作系统层

2. **更高的灵活性**
   - 可以集成到任何 Docker 镜像
   - 可以直接用于静态链接
   - 适合嵌入式场景

3. **更快的分发**
   - Artifact 下载速度快
   - 不需要 Docker registry

4. **更好的兼容性**
   - 可以在任何 Alpine 环境中使用
   - 不依赖特定的 Docker 版本

---

## 🎯 典型使用场景

### 1. PHP 扩展开发
```dockerfile
FROM php:8.2-fpm-alpine

# 安装 ONNX Runtime
COPY artifacts/* /usr/local/
RUN ldconfig

# 编译 PHP-ORT 扩展
# ...
```

### 2. Python 应用
```dockerfile
FROM python:3.11-alpine

# 安装 ONNX Runtime
COPY artifacts/lib* /usr/local/lib/
RUN ldconfig

# 安装 Python 绑定
pip install onnxruntime
```

### 3. C++ 应用
```dockerfile
FROM alpine:3.23

# 安装运行时
COPY artifacts/lib* /usr/local/lib/
RUN ldconfig

# 如果需要编译，安装头文件
COPY artifacts/onnxruntime-headers-*.tar.gz /tmp/
RUN tar -xzf /tmp/onnxruntime-headers-*.tar.gz -C /usr/local/

# 编译应用
# g++ -I/usr/local/include -L/usr/local/lib -lonnxruntime ...
```

---

## 📝 注意事项

1. **musl libc 兼容性**
   - 构建产物只能在 musl libc 系统上运行（Alpine）
   - 不能在 glibc 系统（Ubuntu、CentOS）上直接使用

2. **架构限制**
   - 当前只支持 x86_64 架构
   - 如需 arm64，需要修改工作流

3. **版本匹配**
   - 确保使用的 Alpine 版本与构建时一致
   - 不同版本的 musl libc 可能不兼容

4. **符号链接**
   - 上传时会保留符号链接
   - 解压后需要检查链接是否正确

---

## 🔗 相关资源

- **工作流文件**: [`alpine_build.yml`](./alpine_build.yml)
- **构建脚本**: [`../build-alpine-optimized.sh`](../build-alpine-optimized.sh)
- **Dockerfile**: [`../Dockerfile.onnx-alpine`](../Dockerfile.onnx-alpine)（参考）
- **验证清单**: [`VERIFICATION_CHECKLIST.md`](./VERIFICATION_CHECKLIST.md)
