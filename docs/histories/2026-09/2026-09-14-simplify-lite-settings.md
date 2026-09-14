## 2026-09-14 | 任务：精简 Lite 设置界面

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-14-simplify-lite-settings.md)

### 用户请求

根据修改前截图继续精简 Easydict Lite 的设置窗口，降低分页数量和通用设置的信息密度。

### 变更

- 设置窗口从通用、服务、收藏、禁止名单、快捷键、高级、关于 7 个分页缩减为通用、服务、
  快捷键 3 个分页，并将窗口调整为 820 × 560。
- 通用页只保留第一/第二语言、清空输入、划词自动查询、OCR 自动查询、OCR 自动复制和开机
  启动，共 7 个可见项。
- 快捷键页只显示输入翻译、截图翻译、划词翻译和静默截图 OCR 4 个全局快捷键。
- 从 Lite target 排除高级、收藏、禁止名单和应用内快捷键设置视图，并把规则写入幂等裁剪脚本。
- 重新构建、签名并替换安装 `/Applications/Easydict Lite.app`；旧 Lite 安装移入废纸篓。

### 设计意图

沿用现有 macOS 原生 Form、TabView 和控件语言，通过删除非核心决策而不是增加新样式降低认知
负担。服务配置仍独立保留，确保有道启用状态和 DeepSeek API Key 具备可发现的配置入口。

### 验证

- Debug 稳定测试集：19 个 suite、149 项测试通过。
- Release 构建：`arm64` 构建通过，产物约 27 MB。
- 工程：裁剪脚本语法和幂等执行通过；目标成员复核为 326 个 source，不含 5 个已隐藏设置视图。
- 静态检查：`git diff --check` 通过。
- 安装：`codesign --verify --deep --strict` 通过；构建产物与安装产物主程序 SHA-256 一致。
- GUI 视觉验收：未执行；用户截图作为修改前基线。

### 受影响文件

- `Easydict/Swift/View/SettingView/SettingView.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/GeneralTab.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ShortcutTab.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `scripts/lite/configure-lite-project.rb`
- `docs/exec-plans/completed/2026-09/2026-09-14-simplify-lite-settings.md`

### 后续事项

- 需要用户重新打开 Lite 设置窗口，确认 3 个分页的实际视觉密度和服务页操作符合预期。
- 变更未推送远端，也未制作新的 DMG。
