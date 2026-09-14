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
