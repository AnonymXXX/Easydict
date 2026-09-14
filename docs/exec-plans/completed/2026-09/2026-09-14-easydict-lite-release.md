# 发布 Easydict Lite 首个版本

- 状态：completed
- 创建日期：2026-09-14
- 完成日期：2026-09-14
- 负责人：AnonymXXX
- 关联 Release：https://github.com/AnonymXXX/Easydict/releases/tag/v2.22.0-lite.1

## 背景

个人 Lite fork 已完成核心裁剪并推送到 `origin/dev`，但项目主页仍保留大量上游功能说明，
GitHub 仓库也没有可下载的 Release。

## 目标与范围

- 目标结果：更新 Lite 版 README，构建 Apple Silicon DMG，并创建首个 GitHub Release。
- 允许修改路径：`README.md`、`README_ZH.md`、本任务 plan/history；Git tag 和 GitHub Release。
- 同任务 history：`docs/histories/2026-09/2026-09-14-easydict-lite-release.md`
- 用户限制：只发布当前个人轻量版本。
- 非目标：不启用 Sparkle，不做 Apple Developer ID 签名或公证，不发布 Intel 构建。
- 验收标准：README 与实际 Lite 功能一致；DMG 内应用版本、架构、签名和哈希可验证；远端标签和
  GitHub Release 指向同一提交。

## 工作计划

1. 核对当前版本、Release、标签和构建产物。
2. 将根 README 收敛为 Lite 版功能、安装、权限和源码构建说明。
3. 构建并使用稳定本地身份签名，生成 Apple Silicon DMG 与 SHA-256。
4. 提交并推送文档，创建并验证版本标签与 GitHub Draft Release。
5. 根据用户发布确认公开 Release，记录结果并归档计划。

## 风险与决策

- 使用 `v2.22.0-lite.1` 区分 Lite 首发与上游 `2.22.0`。
- DMG 使用维护者本机的稳定自签名身份，未经过 Apple 公证；README 明确限制，其他设备建议源码构建。
- 不调用上游 Developer ID、Sparkle 和 appcast 发布流水线，避免改变 Lite 版已移除的自动更新边界。

## 进度

- [x] 核对版本、仓库和现有 Release 状态。
- [x] 更新 Lite 版 README。
- [x] 完成 Release 构建、签名和 DMG 验证。
- [x] 提交并推送 README。
- [x] 创建并验证 GitHub Draft Release。
- [x] 经用户确认公开发布并设为 Latest。
- [x] 写入 history 并归档计划。

## 验证

- Release 构建通过，应用版本为 `2.22.0 (65)`，Bundle ID 为
  `com.anonymxxx.EasydictLite`，主程序架构为 `arm64`。
- 稳定本地身份签名和 `codesign --verify --deep --strict` 通过。
- `hdiutil verify` 通过；DMG 内应用、`Applications` 链接、版本、架构和签名检查通过。
- `spctl --assess` 因未使用 Apple Developer ID 和公证而拒绝，README 与 Release 正文已保留
  首次右键打开的提示。
- DMG SHA-256 为 `08cb2694559dc4801830d5c3ebbc1fa41314a9f31018e605223227f1696ab5f2`。
- GitHub API 回读确认 Release 已公开、为 Latest，两个资产状态均为 `uploaded`；远端 Tag 与
  `origin/dev` 均解析到 `7d23dcbd183bca5e5627a3fc6ec56095a510da83`。

## 完成条件

- README、DMG、标签与 Release 状态均完成验证。
- 远端 `dev` 包含文档提交，Release 标签指向预期提交。
- history 已记录，计划已归档。
