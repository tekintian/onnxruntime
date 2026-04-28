# Alpine CI 工作流 - 快速开始指南

## 🎯 一句话总结

在 Alpine 容器中编译 ONNX Runtime，输出 .so 库文件和头文件，自动发布到 GitHub Releases。

---

## 🚀 快速开始（3 步）

### 1️⃣ 提交代码并创建 Tag

```bash
git add .
git commit -m "Update ONNX Runtime build"
git tag v1.25.1
git push origin v1.25.1
```

### 2️⃣ 等待构建完成

- ⏱️ 大约 12-17 分钟
- 📊 可在 GitHub Actions 页面查看进度

### 3️⃣ 下载产物

**方式 A：从 Release 下载（推荐）**
```bash
# 访问 Releases 页面
https://github.com/{user}/{repo}/releases

# 或使用 CLI
gh release download onnxruntime-alpine-v1.25.1
```

**方式 B：从 Artifact 下载**
```bash
# 访问 Actions → 最新构建 → Artifacts
# 下载 onnxruntime-alpine-3.23-1.25.1.zip
```

---

## 📦 产物内容

### 默认包含（无需配置）

```
onnxruntime-alpine-3.23-1.25.1/
├── libonnxruntime.so                    # 符号链接
├── libonnxruntime.so.1                  # 符号链接
├── libonnxruntime.so.1.25.1             # 主库 (~24 MB)
├── libonnxruntime_providers_shared.so   # 提供者库 (~16 KB)
├── onnxruntime-headers-1.25.1.tar.gz    # 头文件包 (170 KB) ✅ 默认包含
└── onnxruntime-headers-1.25.1.tar.gz.sha256  # 校验和
```

**头文件包包含 14 个公共 API 头文件：**
- `onnxruntime_c_api.h` (378 KB)
- `onnxruntime_cxx_api.h` (161 KB)
- `onnxruntime_cxx_inline.h` (151 KB)
- 等 11 个...

---

## 🔧 使用示例

### 安装到 Alpine 系统

```bash
# 1. 解压
tar -xzf onnxruntime-alpine-v1.25.1.tar.gz

# 2. 安装库文件
sudo cp libonnxruntime.so* /usr/local/lib/
sudo cp libonnxruntime_providers_shared.so /usr/local/lib/
sudo ldconfig

# 3. 安装头文件（开发需要）
sudo tar -xzf onnxruntime-headers-1.25.1.tar.gz -C /usr/local/

# 4. 验证
ls -lh /usr/local/lib/libonnxruntime*
ls -lh /usr/local/include/onnxruntime/*.h
```

### 在 Docker 中使用

```dockerfile
FROM alpine:3.23

# 复制构建产物
COPY libonnxruntime.so* /usr/local/lib/
COPY libonnxruntime_providers_shared.so /usr/local/lib/

# 可选：安装头文件
COPY onnxruntime-headers-*.tar.gz /tmp/
RUN tar -xzf /tmp/onnxruntime-headers-*.tar.gz -C /usr/local/ && \
    rm /tmp/onnxruntime-headers-*.tar.gz

# 更新库缓存
RUN ldconfig

# 设置环境变量
ENV LD_LIBRARY_PATH=/usr/local/lib
```

### C++ 编译示例

```bash
# 编译
g++ -std=c++17 \
  -I/usr/local/include \
  -L/usr/local/lib \
  -lonnxruntime \
  -o my_app my_app.cpp

# 运行
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
./my_app
```

---

## ⚙️ 配置选项

### 手动触发参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `alpine_version` | `3.23` | Alpine Linux 版本 |
| `onnx_version` | `1.25.1` | ONNX Runtime 版本 |
| `include_headers` | `true` ✅ | **默认包含头文件** |
| `create_release` | `false` | 是否创建 Release |

### 如何不包含头文件？

如果需要减小产物体积，可以显式禁用头文件：

```yaml
# 手动触发时
include_headers: false
```

或在工作流中修改默认值。

---

## 📊 触发条件对比

| 触发方式 | 构建 | Artifact | Release | 说明 |
|---------|------|----------|---------|------|
| `git push main` | ✅ | ✅ | ❌ | 日常开发 |
| `git push origin v1.25.1` | ✅ | ✅ | ✅ | **正式发布** |
| Pull Request | ✅ | ✅ | ❌ | PR 验证 |
| 手动触发 | ✅ | ✅ | 可选 | 测试/调试 |

---

## ✨ 核心优势

### 1. 完全原生
- ✅ 在真实 Alpine 容器中编译
- ✅ 直接使用 musl libc
- ✅ 无 glibc 兼容层开销

### 2. 深度优化
- ✅ 41 个 CMake 优化标志
- ✅ 禁用所有 GPU/加速器
- ✅ 仅保留 CPU 推理功能
- ✅ LTO 禁用（Alpine 稳定性）

### 3. 完整产物
- ✅ 共享库文件（~24 MB）
- ✅ 14 个公共 API 头文件（170 KB）
- ✅ SHA256 校验和
- ✅ 符号链接

### 4. 自动发布
- ✅ Tag 推送自动创建 Release
- ✅ 自动生成详细说明
- ✅ 所有文件自动上传
- ✅ 支持正式/预发布版本

---

## 🔍 常见问题

### Q1: 头文件在哪里？

**A:** 默认包含在产物中：
```bash
# Artifact 或 Release 中
onnxruntime-headers-1.25.1.tar.gz

# 解压后
tar -xzf onnxruntime-headers-1.25.1.tar.gz
ls include/onnxruntime/*.h  # 14 个头文件
```

### Q2: 如何只获取库文件，不要头文件？

**A:** 目前默认包含头文件。如需排除，手动触发时设置：
```yaml
include_headers: false
```

### Q3: Release 和 Artifact 有什么区别？

**A:** 
- **Artifact**: 临时存储（30 天），适合开发测试
- **Release**: 永久存储，适合正式发布

### Q4: 可以在非 Alpine 系统上使用吗？

**A:** ❌ 不可以。这是 musl libc 编译的，只能在 Alpine 或其他 musl 系统上运行。

### Q5: 如何验证下载的完整性？

**A:** 使用 SHA256 校验和：
```bash
sha256sum -c onnxruntime-headers-1.25.1.tar.gz.sha256
```

---

## 📝 最佳实践

### 1. 版本号管理

使用语义化版本：
```bash
git tag v1.25.1        # 正式版
git tag v1.25.1-rc1    # 候选版
git tag v1.25.1-beta   # 测试版
```

### 2. 发布前检查

- [ ] 本地测试通过
- [ ] 构建成功
- [ ] Artifact 完整
- [ ] 版本号正确

### 3. 发布后验证

- [ ] Release 页面正常
- [ ] 所有文件可下载
- [ ] 校验和匹配
- [ ] 文档清晰

---

## 🔗 相关资源

- **工作流文件**: [`alpine_build.yml`](./.github/workflows/alpine_build.yml)
- **构建产物说明**: [`BUILD_ARTIFACTS.md`](./.github/workflows/BUILD_ARTIFACTS.md)
- **发布指南**: [`RELEASE_GUIDE.md`](./.github/workflows/RELEASE_GUIDE.md)
- **验证清单**: [`VERIFICATION_CHECKLIST.md`](./.github/workflows/VERIFICATION_CHECKLIST.md)
- **工作流管理**: [`WORKFLOW_MANAGEMENT.md`](./.github/workflows/WORKFLOW_MANAGEMENT.md)

---

## ✅ 总结

**默认配置：**
- ✅ 始终包含头文件
- ✅ 自动上传 Artifact
- ✅ Tag 推送自动创建 Release
- ✅ 完整的构建产物

**使用建议：**
1. 日常开发 → Push 到分支（自动构建 + Artifact）
2. 正式发布 → Push Tag（自动构建 + Release）
3. 测试验证 → 手动触发（灵活配置）

**开始使用：**
```bash
git tag v1.25.1
git push origin v1.25.1
# 等待 12-17 分钟
# 下载 Release 产物
```

🎉 **就这么简单！**
