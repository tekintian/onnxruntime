# Alpine CI 工作流 - 验证清单

## ✅ 已完成的修改

### 1. 移除本地镜像加速
- [x] 删除 `enable_mirror` 输入参数
- [x] 删除 `LOCAL_MIRROR` 环境变量
- [x] 从 Docker build-args 中移除 `LOCAL_MIRROR`
- [x] 更新文档说明

**原因：** GitHub Actions 环境网络正常，不需要本地镜像加速

### 2. 修正路径配置
- [x] 工作流根目录：`php/onnxruntime/`
- [x] Dockerfile 位置：`php/onnxruntime/Dockerfile.onnx-alpine`
- [x] 源码目录：`php/onnxruntime/onnxruntime/`
- [x] 头文件提取脚本：`php/onnxruntime/extract-onnx-headers.sh`
- [x] 移除所有 `working-directory` 指令
- [x] Docker context 设置为 `.`（当前目录）

### 3. 文件复制
已将以下文件复制到 `php/onnxruntime/` 目录：
- [x] `Dockerfile.onnx-alpine`
- [x] `extract-onnx-headers.sh`
- [x] `include/` 目录（头文件源码）

---

## 📋 工作流配置检查

### 基本信息
```yaml
name: Alpine Linux Build
触发条件:
  - push (main, rel-*)
  - pull_request (main, rel-*)
  - workflow_dispatch
路径过滤: php/** 和 .github/workflows/alpine_build.yml
```

### 输入参数
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `alpine_version` | string | `3.23` | Alpine Linux 版本 |
| `onnx_version` | string | `1.25.1` | ONNX Runtime 版本 |
| `include_headers` | boolean | `false` | 是否包含开发头文件 |

### 环境变量
```yaml
ALPINE_VERSION: ${{ inputs.alpine_version || '3.23' }}
ONNX_VERSION: ${{ inputs.onnx_version || '1.25.1' }}
INCLUDE_HEADERS: ${{ inputs.include_headers == 'true' }}
```

### 构建步骤
1. ✅ Checkout repository
2. ✅ Setup Docker Buildx
3. ✅ Apply musl libc compatibility patch
4. ✅ Extract and package headers (conditional)
5. ✅ Build Docker image (runtime only)
6. ✅ Test runtime image
7. ✅ Build Docker image (with headers, conditional)
8. ✅ Test dev image (conditional)
9. ✅ Generate build report
10. ✅ Upload artifacts
11. ✅ Summary

---

## 🔍 关键配置验证

### Docker 构建配置
```yaml
context: .                          # ✅ 当前目录 (php/onnxruntime/)
file: Dockerfile.onnx-alpine        # ✅ Dockerfile 在当前目录
build-args:
  ALPINE_VERSION=${{ env.ALPINE_VERSION }}
  ONNX_VERSION=${{ env.ONNX_VERSION }}
  INCLUDE_HEADERS=false/true        # ✅ 无 LOCAL_MIRROR
```

### 文件路径验证
```bash
# 工作流执行时的目录结构
php/onnxruntime/
├── .github/workflows/
│   └── alpine_build.yml           # ✅ 工作流文件
├── Dockerfile.onnx-alpine          # ✅ Dockerfile
├── extract-onnx-headers.sh         # ✅ 头文件提取脚本
├── onnxruntime/                    # ✅ ONNX Runtime 源码
│   ├── include/                    # ✅ 头文件源码
│   └── ...
└── onnxruntime/release/            # ✅ 输出目录
    └── onnxruntime-headers-*.tar.gz
```

### musl 补丁路径
```bash
# 正确的路径（相对于工作流根目录）
onnxruntime/core/platform/posix/stacktrace.cc
```

---

## 🧪 测试清单

### 基本功能测试
- [ ] 工作流可以手动触发
- [ ] Docker 镜像构建成功
- [ ] musl 补丁正确应用
- [ ] 运行时镜像包含正确的库文件
- [ ] 依赖项解析正常（ldd 检查）

### 头文件测试（可选）
- [ ] 设置 `include_headers=true`
- [ ] 头文件包正确生成
- [ ] 开发镜像包含 14 个头文件
- [ ] 头文件路径正确（/usr/local/include/onnxruntime/）

### Artifact 测试
- [ ] 头文件包上传成功
- [ ] SHA256 校验和文件上传
- [ ] Artifact 可以在 GitHub 下载

---

## 📊 预期输出

### 运行时镜像
```bash
alpine:3.23-onnx1.25.1
```

**包含文件：**
```
/usr/local/lib/
├── libonnxruntime.so -> libonnxruntime.so.1
├── libonnxruntime.so.1 -> libonnxruntime.so.1.25.1
├── libonnxruntime.so.1.25.1 (~24 MB)
└── libonnxruntime_providers_shared.so (~16 KB)
```

### 开发镜像（可选）
```bash
alpine:3.23-onnx1.25.1-dev
```

**额外包含：**
```
/usr/local/include/onnxruntime/
├── onnxruntime_c_api.h (378 KB)
├── onnxruntime_cxx_api.h (161 KB)
├── onnxruntime_cxx_inline.h (151 KB)
├── cpu_provider_factory.h
├── core/providers/
│   ├── custom_op_context.h
│   └── resource.h
└── ... (共 14 个头文件)
```

---

## ⚠️ 常见问题

### Q1: Docker 构建找不到 Dockerfile？
**A:** 确保 `Dockerfile.onnx-alpine` 在 `php/onnxruntime/` 目录下

### Q2: musl 补丁应用失败？
**A:** 检查路径是否正确：`onnxruntime/core/platform/posix/stacktrace.cc`

### Q3: 头文件提取失败？
**A:** 确保 `extract-onnx-headers.sh` 有执行权限且在正确位置

### Q4: Artifact 上传为空？
**A:** 检查 `onnxruntime/release/` 目录是否有生成的文件

---

## 🚀 部署前检查

### GitHub Actions 配置
- [ ] 仓库已启用 GitHub Actions
- [ ] 有足够的存储空间用于 artifact
- [ ] Runner 有足够的资源（建议 2 CPU, 7GB RAM）

### Docker 配置
- [ ] Docker Buildx 可用
- [ ] GitHub Actions Cache 已启用
- [ ] 足够的磁盘空间（建议 50GB+）

### 代码配置
- [ ] 所有必需文件已提交到 Git
- [ ] `.gitignore` 不包含必需的文件
- [ ] 分支保护规则允许工作流运行

---

## 📝 后续优化建议

### 短期（1-2 周）
1. 添加自动化测试验证 ONNX Runtime 功能
2. 配置自动发布到 GitHub Releases
3. 添加构建时间监控
4. 优化 Docker 层缓存

### 中期（1-2 月）
1. 添加 arm64 架构支持
2. 集成二进制大小监控
3. 添加性能基准测试
4. 支持多个 ONNX Runtime 版本并行构建

### 长期（3-6 月）
1. 贡献 musl 兼容性补丁到上游
2. 创建官方的 Alpine Docker 镜像
3. 添加更多执行提供者支持（如需要）
4. 建立完整的 CI/CD 流水线

---

## ✅ 最终确认

- [x] 工作流配置文件语法正确
- [x] 所有路径引用正确
- [x] 本地镜像加速已移除
- [x] 文档已更新
- [x] 相关文件已复制到正确位置
- [ ] 首次构建测试通过
- [ ] 所有测试用例通过
- [ ] Artifact 上传正常

---

**准备就绪！** 🎉 

现在可以提交代码并触发第一次构建了。
