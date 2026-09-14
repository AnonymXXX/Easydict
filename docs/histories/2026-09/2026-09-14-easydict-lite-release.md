## 2026-09-14 | 任务：发布 Easydict Lite 首个版本

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-14-easydict-lite-release.md)、[GitHub Release](https://github.com/AnonymXXX/Easydict/releases/tag/v2.22.0-lite.1)、[个人 fork](https://github.com/AnonymXXX/Easydict)

### 用户请求

将 README 改为当前个人 Lite 版的准确说明，更新 GitHub About 简介，制作可下载的首个 Release，
并在确认后公开发布。

### 变更

- 重写根 README，只描述输入翻译、截图翻译、Apple Vision OCR、有道与 DeepSeek，以及实际
  移除范围；将旧中文 README 收敛为主页入口。
- 更新 GitHub About 简介，移除上游多服务宣传，改为 Lite 版能力和 Apple Silicon 边界。
- 构建、稳定本地签名并打包 `Easydict-Lite-2.22.0-arm64.dmg`，同时提供 SHA-256 文件。
- 创建并公开 `v2.22.0-lite.1` Release，设为 Latest。

### 设计意图

版本标签使用 `lite.1` 后缀区分上游应用版本与个人发行轮次。发布包延续本机稳定签名方案，
但不冒充 Developer ID 公证发行；README 和 Release 正文都明确首次启动方式和设备边界。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Release -derivedDataPath /tmp/EasydictLiteDerivedData CODE_SIGNING_ALLOWED=NO -quiet`：通过。
- `codesign --verify --deep --strict`：源码构建产物和 DMG 内应用均通过。
- `hdiutil verify /tmp/Easydict-Lite-2.22.0-arm64.dmg`：通过。
- 产物检查：版本 `2.22.0 (65)`，Bundle ID `com.anonymxxx.EasydictLite`，架构 `arm64`，
  DMG SHA-256 为 `08cb2694559dc4801830d5c3ebbc1fa41314a9f31018e605223227f1696ab5f2`。
- GitHub API 回读：Release 为公开、非 prerelease、Latest；DMG 与校验文件均为 `uploaded`。
- Git 远端回读：`origin/dev` 和 `v2.22.0-lite.1^{}` 均指向
  `7d23dcbd183bca5e5627a3fc6ec56095a510da83`。

### 受影响文件

- `README.md`
- `README_ZH.md`
- `docs/exec-plans/completed/2026-09/2026-09-14-easydict-lite-release.md`
- `docs/histories/2026-09/2026-09-14-easydict-lite-release.md`

### 后续事项

- Release 未经过 Apple Developer ID 签名与公证；面向其他 Mac 分发时，应使用正式开发者证书
  并完成公证。
