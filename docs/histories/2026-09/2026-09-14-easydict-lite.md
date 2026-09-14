## 2026-09-14 | 任务：制作 Easydict 个人轻量版

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-14-easydict-lite.md)、[个人 fork](https://github.com/AnonymXXX/Easydict)

### 用户请求

从 Easydict fork 开发个人轻量版，只保留输入翻译、划词翻译、截图 OCR，以及有道和
DeepSeek 两个查询服务，同时缩减运行资源和依赖。

### 变更

- 将查询服务注册表和默认服务收窄为有道与 DeepSeek，并保留 Apple Vision OCR、语言检测
  和语音能力；移除 Apple 翻译、Apple Dictionary 及其他查询服务的目标成员关系。
- 精简菜单、设置和快捷键入口，移除 HTTP Server、自动更新、分析、崩溃上报和未使用的
  AI/服务依赖；DeepSeek 改为复用本地 URLSession/SSE 流实现。
- 清理未使用服务图标，将 Release 产品改名为 `Easydict Lite`，设置独立 Bundle ID，并将
  Release 架构限定为 `arm64`。被清理的图标目录已移入废纸篓，清空前可恢复。
- 保留未参与 Lite 编译的上游服务源码，方便后续合并安全修复；新增幂等工程裁剪脚本，并在
  中英文 README 顶部标明 fork 范围。

### 设计意图

以服务注册表、Xcode target membership 和构建依赖作为轻量版边界，避免只隐藏 UI 而继续
编译和打包无关服务。将裁剪规则集中到可重复执行的脚本，使后续同步上游时能重新建立同一
边界，同时保留 GPL-3.0 许可证和原作者版权信息。

### 验证

- `xcodebuild -workspace Easydict.xcworkspace -scheme Easydict -configuration Release -derivedDataPath /tmp/EasydictLiteDerivedData CODE_SIGNING_ALLOWED=NO build`：通过。
- 稳定测试集：19 个 suite、149 项测试通过；显式跳过当前系统相关的 OCR 图像快照测试和
  AppleScript 环境测试。
- 产物检查：`Easydict Lite.app` 约 27 MB，主程序约 23 MB，Mach-O 为 `arm64`，版本
  `2.22.0`，Bundle ID 为 `com.anonymxxx.EasydictLite`。
- `ruby -c scripts/lite/configure-lite-project.rb`、`plutil -lint`、脚本幂等执行和
  `git diff --check`：通过。
- 人工静态复核：注册表只暴露 Youdao、DeepSeek；服务资源目录只保留 Youdao、DeepSeek
  和共用播放图标。

### 受影响文件

- `Easydict.xcodeproj/project.pbxproj`
- `Easydict.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `Easydict/App/`
- `Easydict/Swift/`
- `README.md`
- `README_ZH.md`
- `scripts/lite/configure-lite-project.rb`
- `docs/exec-plans/completed/2026-09/2026-09-14-easydict-lite.md`

### 后续事项

- 需要在真实 macOS 权限环境中验收输入、划词、截图 OCR 快捷键和结果，并配置凭据验证
  有道与 DeepSeek 在线调用。
- 当前 Release 未签名、未安装、未制作 DMG，也未发布或推送远端。
