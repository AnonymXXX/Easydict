# Easydict Lite GitHub Actions 发布

- 状态：completed
- 创建日期：2026-09-15
- 完成日期：2026-09-15
- 负责人：AnonymXXX
- 参考工作流：https://github.com/AnonymXXX/walkgate/actions

## 目标与范围

- 增加与 WalkGate 一致的 Tag/手动触发 GitHub Actions 发布入口。
- 使用现有 `Local Mac App Code Signing` 身份构建和签名 Apple Silicon Lite 包。
- 自动创建或更新 GitHub Release，上传 DMG 与 SHA-256。
- 不调用上游 Developer ID、公证、Sparkle 或 App Store Connect 发布流程。

## 落地结果

- 新增 `Release Lite` 工作流，支持 `v<version>-lite.<number>` Tag 和手动输入已有 Tag。
- 新增 Lite 打包脚本，验证版本、Bundle ID、arm64 架构、稳定签名、DMG 和 SHA-256。
- 发布门禁运行稳定测试集合；环境敏感的 OCR、AppleScript、系统音量和时序套件不在 CI 中运行。
- `AnonymXXX/Easydict` 已配置三个签名 Secrets；秘密值未写入仓库或日志。
- 工作流已推送至 `origin/dev` 并由 GitHub API 回读为 active；未创建 Tag 或 Release。

## 验证

- `bash -n scripts/lite/package-release.sh`：通过。
- Workflow YAML 解析和结构检查：通过。
- 稳定测试集合：144 项通过、0 项失败。
- 本地 `v2.22.0-lite.4` 格式试打包：应用版本 `2.22.0 (67)`、Bundle ID
  `com.anonymxxx.EasydictLite`、架构 `arm64`；App/DMG 签名、`hdiutil verify` 和 SHA-256 校验通过。
- 远端 `origin/dev` 包含实现提交 `6baeab5f`，GitHub Actions 列表显示 `Release Lite` 为 active。

## 完成条件

- 工作流、打包脚本、测试门禁、签名 Secrets 和远端 Actions 可见性均已验证。
- 实际发布仍必须由新的 Lite Tag 推送或手动运行触发。
