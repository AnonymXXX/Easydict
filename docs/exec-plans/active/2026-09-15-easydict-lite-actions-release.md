# Easydict Lite GitHub Actions 发布

- 状态：active
- 创建日期：2026-09-15
- 负责人：AnonymXXX
- 参考工作流：https://github.com/AnonymXXX/walkgate/actions

## 目标与范围

- 增加与 WalkGate 一致的 Tag/手动触发 GitHub Actions 发布入口。
- 使用现有 `Local Mac App Code Signing` 身份构建和签名 Apple Silicon Lite 包。
- 自动创建或更新 GitHub Release，上传 DMG 与 SHA-256。
- 不调用上游 Developer ID、公证、Sparkle 或 App Store Connect 发布流程。

## 工作计划

1. 读取 WalkGate 线上成功工作流并确认 Easydict Lite 的发布差异。
2. 增加 Lite 打包脚本和 GitHub Actions 工作流。
3. 本地构建、签名、DMG、校验和与工作流语法验证。
4. 配置仓库 Actions Secrets，提交并推送到 `origin/dev`。
5. 回读远端工作流与 Secrets 元数据，记录结果并归档计划。

## 验收标准

- `v<version>-lite.<number>` Tag 推送和手动输入已有 Tag 均可触发。
- 构建产物 Bundle ID 为 `com.anonymxxx.EasydictLite`，架构为 `arm64`。
- App 和 DMG 使用稳定本地身份签名；DMG 与 SHA-256 通过校验。
- 远端 Actions 列表可见 `Release Lite`，所需 Secrets 名称齐全。
