<p align="center">
  <img src="./Easydict/App/Assets.xcassets/logo.imageset/icon_ns_512x512@2x.png" width="160" alt="Easydict Lite">
</p>

<h1 align="center">Easydict Lite</h1>

<p align="center">只保留日常翻译所需功能的 macOS 轻量版。</p>

<p align="center">
  <a href="https://github.com/AnonymXXX/Easydict/releases/latest"><img src="https://img.shields.io/github/v/release/AnonymXXX/Easydict?display_name=tag" alt="Release"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/github/license/AnonymXXX/Easydict" alt="License"></a>
  <img src="https://img.shields.io/badge/macOS-13.0%2B-black?logo=apple" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/CPU-Apple%20Silicon-blue" alt="Apple Silicon">
</p>

这是 [Easydict](https://github.com/tisfeng/Easydict) 的个人轻量 fork，面向 Apple Silicon Mac，
减少菜单、设置项、翻译服务和后台依赖，只保留高频入口。

## 保留功能

- 输入翻译：默认快捷键 `⌥ A`
- 截图翻译：默认快捷键 `⌥ S`
- 三指轻点取词：无需预先选中，轻点光标下单词后自动翻译
- Apple Vision 本地 OCR
- 有道词典与翻译
- DeepSeek AI 翻译
- 简体中文与英语互译

## 已移除

- 划词翻译、静默截图 OCR
- Apple 翻译及其他词典、翻译、AI、CLI 服务
- 收藏、禁止名单、高级设置和帮助菜单
- HTTP Server、自动更新、分析与崩溃上报
- Intel (`x86_64`) 构建

## 安装

从 [Releases](https://github.com/AnonymXXX/Easydict/releases/latest) 下载
`Easydict-Lite-2.22.0-arm64.dmg`，打开后将 `Easydict Lite.app` 拖入“应用程序”。

截图翻译首次使用时，需要在“系统设置 → 隐私与安全性 → 屏幕与系统录音”中允许
Easydict Lite。当前发布包使用个人本地签名，未经过 Apple 公证，主要用于本项目维护者的 Mac；
macOS 首次拦截时，在“应用程序”中右键点击 Easydict Lite，选择“打开”，再确认“仍要打开”。
其他设备建议从源码构建并创建自己的本地签名身份。

使用三指轻点取词前，请在“系统设置 → 触控板 → 光标与点按”中关闭“查询与数据检测器”，
避免同时弹出 macOS 系统词典。该功能依赖 macOS 内部触控板接口，系统升级后可能需要重新验证。

## 从源码安装

环境要求：macOS 13.0+、Xcode、CocoaPods、Apple Silicon Mac。

```bash
git clone git@github.com:AnonymXXX/Easydict.git
cd Easydict
pod install

xcodebuild build \
  -workspace Easydict.xcworkspace \
  -scheme Easydict \
  -configuration Release \
  -derivedDataPath /tmp/EasydictLiteDerivedData \
  CODE_SIGNING_ALLOWED=NO

scripts/lite/setup-local-signing.sh
scripts/lite/install-local-app.sh
```

`setup-local-signing.sh` 只需首次运行。后续重新构建后执行 `install-local-app.sh`，即可复用同一
代码签名身份，避免因每次构建的应用身份变化而反复丢失屏幕录制权限。

## 说明

- 当前版本：`2.22.0 (66)`，当前 Lite 标签为 `v2.22.0-lite.2`
- Bundle ID：`com.anonymxxx.EasydictLite`
- 本项目继续遵循 [GPL-3.0](./LICENSE)
- 原项目版权、致谢与贡献归 [Easydict](https://github.com/tisfeng/Easydict) 及其贡献者所有
