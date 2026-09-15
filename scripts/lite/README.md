# Easydict Lite 本地安装

Lite 版需要稳定的本地代码签名身份，避免每次重新构建后 macOS 将其视为新的屏幕录制权限主体。
该身份只用于本机开发安装，不用于向其他用户分发。

首次安装前创建专用身份：

```bash
scripts/lite/setup-local-signing.sh
```

完成 Release 构建后签名、替换安装并启动：

```bash
scripts/lite/install-local-app.sh
```

安装脚本默认读取
`/tmp/EasydictLiteDerivedData/Build/Products/Release/Easydict Lite.app`，也可将其他 `.app` 路径作为
第一个参数传入。首次从 ad-hoc 签名切换后，需要在“系统设置 → 隐私与安全性 → 屏幕与系统录音”
中重新允许 Easydict Lite 一次。

## GitHub Actions 发布

`.github/workflows/release-lite.yml` 支持推送 `v<version>-lite.<number>` Tag 自动发布，也可以在
GitHub Actions 中手动输入已有 Tag。工作流使用仓库 Secrets 中的稳定本地签名证书，构建并验证
Apple Silicon DMG，然后创建或更新对应的 GitHub Release。

发布前会运行稳定测试集合。依赖具体 macOS OCR 输出、AppleScript 系统权限或精确调度时序的
`OCRImageTests`、`SystemUtilitiesTests`、`AppleScriptExecutorTests` 和 `TaskTimeoutTests` 不作为
GitHub Runner 的发布门禁，完整测试仍应在本机按需运行。

工作流需要以下仓库 Secrets：

- `MACOS_SIGNING_CERTIFICATE`
- `MACOS_SIGNING_CERTIFICATE_PASSWORD`
- `MACOS_SIGNING_KEYCHAIN_PASSWORD`

本地复现打包时，先确保 `Local Mac App Code Signing` 身份可用，再运行：

```bash
scripts/lite/package-release.sh v2.22.0-lite.4
```
