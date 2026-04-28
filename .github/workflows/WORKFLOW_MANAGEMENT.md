# GitHub Actions 工作流管理 - 快速指南

## 📊 当前状态

- ✅ **活跃工作流**: 1 个 (`alpine_build.yml`)
- ⏸️ **已禁用工作流**: 45 个 (`*.yml.disabled`)

---

## 🚀 Alpine 工作流

### 触发条件

**自动触发：**
- Push 到 `main` 或 `rel-*` 分支（仅 `php/` 目录变更）
- Pull Request 到 `main` 或 `rel-*` 分支

**手动触发：**
- GitHub Actions → "Alpine Linux Build" → "Run workflow"

### 构建参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `alpine_version` | `3.23` | Alpine Linux 版本 |
| `onnx_version` | `1.25.1` | ONNX Runtime 版本 |
| `include_headers` | `false` | 是否包含开发头文件 |
| `enable_mirror` | `true` | 是否启用本地镜像加速 |

### 构建输出

**运行时镜像：**
```bash
alpine:3.23-onnx1.25.1
```

**开发镜像（可选）：**
```bash
alpine:3.23-onnx1.25.1-dev
```

---

## 🔄 管理工作流

### 禁用工作流

```bash
cd .github/workflows
mv filename.yml filename.yml.disabled
```

### 启用工作流

```bash
cd .github/workflows
mv filename.yml.disabled filename.yml
```

### 批量禁用所有工作流

```bash
cd .github/workflows
bash disable-all-workflows.sh
```

### 批量启用所有工作流

```bash
cd .github/workflows
for file in *.yml.disabled; do
    mv "$file" "${file%.disabled}"
done
```

---

## 📋 已禁用的工作流列表

### Linux 构建
- `linux_ci.yml.disabled` - Linux x64/arm64 CI
- `linux_minimal_build.yml.disabled` - Linux 最小化构建
- `linux_cuda_ci.yml.disabled` - Linux CUDA 构建
- `linux_tensorrt_ci.yml.disabled` - Linux TensorRT 构建
- `linux_openvino_ci.yml.disabled` - Linux OpenVINO 构建
- `linux_webgpu.yml.disabled` - Linux WebGPU 构建
- `linux-wasm-ci-build-and-test-workflow.yml.disabled` - Linux WASM 构建
- `linux_cuda_plugin_ci.yml.disabled` - Linux CUDA Plugin 构建

### Windows 构建
- `windows_x64_release_build_x64_release.yml.disabled`
- `windows_x64_debug_build_x64_debug.yml.disabled`
- `windows_cuda.yml.disabled`
- `windows_tensorrt.yml.disabled`
- `windows_openvino.yml.disabled`
- `windows_dml.yml.disabled`
- `windows_webgpu.yml.disabled`
- `windows_qnn_x64.yml.disabled`
- `windows_x86.yml.disabled`
- `windows_build_x64_asan.yml.disabled`
- `windows_cuda_plugin.yml.disabled`
- `windows_gpu_doc_gen.yml.disabled`
- `windows_x64_release_vitisai_build_x64_release.yml.disabled`
- `windows_x64_release_ep_generic_interface_build_x64_release_ep_generic_interface.yml.disabled`
- `windows_x64_release_xnnpack.yml.disabled`
- `windows-web-ci-workflow.yml.disabled`

### macOS 构建
- `mac.yml.disabled` - macOS CI
- `macos-ci-build-and-test-workflow.yml.disabled` - macOS 构建测试

### 移动平台
- `android.yml.disabled` - Android 构建
- `ios.yml.disabled` - iOS 构建
- `react_native.yml.disabled` - React Native 构建

### Web 平台
- `web.yml.disabled` - Web/WASM 构建

### 文档发布
- `publish-c-apidocs.yml.disabled` - C API 文档
- `publish-csharp-apidocs.yml.disabled` - C# API 文档
- `publish-java-apidocs.yml.disabled` - Java API 文档
- `publish-js-apidocs.yml.disabled` - JavaScript API 文档
- `publish-objectivec-apidocs.yml.disabled` - Objective-C API 文档
- `publish-python-apidocs.yml.disabled` - Python API 文档
- `publish-gh-pages.yml.disabled` - GitHub Pages

### 代码质量
- `codeql.yml.disabled` - CodeQL 安全分析
- `lint.yml.disabled` - 代码风格检查
- `pr_checks.yml.disabled` - PR 检查
- `cffconvert.yml.disabled` - CITATION.cff 验证
- `gradle-wrapper-validation.yml.disabled` - Gradle Wrapper 验证

### 其他
- `labeler.yml.disabled` - PR 标签自动化
- `title-only-labeler.yml.disabled` - 标题标签
- `reusable_linux_build.yml.disabled` - 可重用 Linux 构建
- `generate-skip-doc-change.py` - Python 脚本（非工作流）

---

## 💡 使用建议

### 场景 1：只需要 Alpine 构建
✅ 保持当前状态（推荐）

### 场景 2：需要测试其他平台
1. 启用相应的工作流
2. 测试完成后重新禁用

### 场景 3：需要完整 CI
批量启用所有工作流（不推荐，会增加 CI 运行时间）

---

## 🔍 查看工作流状态

```bash
# 查看活跃工作流
ls -1 *.yml

# 查看已禁用工作流
ls -1 *.yml.disabled

# 统计数量
echo "活跃: $(ls -1 *.yml | wc -l)"
echo "禁用: $(ls -1 *.yml.disabled | wc -l)"
```

---

## 📝 注意事项

1. **GitHub 只会识别 `.yml` 文件**
   - `.yml.disabled` 文件会被忽略
   - 重命名后立即生效

2. **工作流历史保留**
   - 禁用工作流不会删除之前的运行记录
   - 可以在 GitHub Actions 页面查看历史

3. **分支保护**
   - 如果禁用了 PR 检查工作流，确保有其他检查机制

4. **成本考虑**
   - 禁用工作流可以减少 GitHub Actions 分钟数消耗
   - 自托管 runner 不受影响

---

## 🎯 最佳实践

1. **只启用需要的工作流**
   - 减少 CI 运行时间
   - 降低资源消耗
   - 简化维护

2. **定期清理**
   - 删除不再需要的工作流
   - 更新过时的工作流配置

3. **文档化**
   - 记录为什么禁用某个工作流
   - 说明如何重新启用

4. **测试**
   - 在重新启用工作流前，先在测试分支验证
   - 确保工作流配置仍然有效

---

## 📞 需要帮助？

- 查看详细文档：[`README.md`](./README.md)
- 查看 Alpine 工作流：[`alpine_build.yml`](./alpine_build.yml)
- 查看禁用脚本：[`disable-all-workflows.sh`](./disable-all-workflows.sh)
