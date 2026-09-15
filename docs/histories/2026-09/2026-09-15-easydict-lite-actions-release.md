## 2026-09-15 | 任务：增加 Easydict Lite GitHub Actions 发布

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-15-easydict-lite-actions-release.md)、[GitHub Actions](https://github.com/AnonymXXX/Easydict/actions)

### 用户请求

参考 WalkGate 的线上发布工作流，为 Easydict Lite 增加同样的一键 GitHub Actions 发布能力。

### 变更

- 增加 `Release Lite` 工作流，支持 Lite Tag 自动触发和手动输入已有 Tag。
- 导入稳定本地签名证书，运行稳定测试，构建并验证 Apple Silicon DMG。
- 新增或更新 GitHub Release，上传 DMG 与 SHA-256；重跑时覆盖资产并保留已有说明。
- 增加本地等价打包脚本和使用说明，并忽略生成的 `dist/` 目录。

### 设计意图

复用 WalkGate 已验证的触发、证书导入、发布和清理结构，但保持 Lite 的 Apple Silicon、个人本地
签名边界，不接入 Easydict 上游的 Developer ID、公证、Sparkle 和 App Store Connect 流程。

### 验证

- 稳定测试集合 144 项通过，完整测试的 7 个失败被确认来自 macOS 26 OCR 差异、AppleScript/
  系统音量环境和精确时序，与本任务变更无关。
- 本地打包产物为 `2.22.0 (67)`、`com.anonymxxx.EasydictLite`、`arm64`；App/DMG 签名、DMG
  容器和 SHA-256 均通过校验。
- GitHub API 回读确认 `Release Lite` 为 active，三个 Actions Secrets 名称齐全，远端 `dev`
  包含实现提交 `6baeab5f`。

### 受影响文件

- `.github/workflows/release-lite.yml`
- `.gitignore`
- `scripts/lite/package-release.sh`
- `scripts/lite/README.md`
- 本任务 plan/history

### 后续事项

- 本任务未创建或推送新的 Lite Tag，也未实际触发 Release；发布时使用新 Tag 或 Actions 手动入口。
