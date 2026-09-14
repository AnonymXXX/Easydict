## 2026-09-14 | 任务：移除 Lite 划词翻译与静默截图 OCR

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-14-remove-lite-extra-actions.md)

### 用户请求

继续精简 Easydict Lite，删除菜单中的“划词翻译”和“静默截图 OCR”及其关联功能。

### 变更

- 从菜单和全局快捷键设置中删除划词翻译与静默截图 OCR，只保留输入翻译和普通截图翻译。
- 删除两项动作的快捷键枚举、默认键位、偏好 key、映射和 Objective-C 窗口执行方法。
- 从通用设置移除划词自动查询项，并在 Lite 初始化时关闭可能由旧安装遗留的自动划词偏好。
- 重新构建、签名并替换安装 `/Applications/Easydict Lite.app`；旧 Lite 安装移入废纸篓。

### 设计意图

用户的新范围替代此前保留划词翻译的决定。普通截图翻译继续使用 `snipTranslate` 与共享 OCR
基础设施；本次只删除静默 OCR 的专用入口和动作，避免影响截图识别、自动查询与复制结果。

### 验证

- Debug 稳定测试集：19 个 suite、149 项测试通过。
- Release 构建：arm64 构建通过，产物约 27 MB。
- 静态检查：`git diff --check` 通过；已移除动作、快捷键和窗口方法无源码引用，
  `snipTranslate` 仍存在。
- 安装：`codesign --verify --deep --strict` 通过；构建产物与安装产物主程序 SHA-256 一致；
  应用已重新启动，自动划词偏好读取为关闭。
- GUI 视觉验收：未执行；用户截图作为修改前基线。

### 受影响文件

- `Easydict/Swift/View/MenuItemView.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/GeneralTab.swift`
- `Easydict/Swift/Feature/Shortcut/Model/ShortcutAction.swift`
- `Easydict/Swift/Feature/Shortcut/Model/ShortcutManager+Default.swift`
- `Easydict/Swift/Feature/Shortcut/View/KeyHolderWrapper.swift`
- `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
- `Easydict/Swift/Feature/Configuration/MyConfiguration.swift`
- `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.h`
- `Easydict/objc/ViewController/Window/WindowManager/EZWindowManager.m`
- `docs/exec-plans/completed/2026-09/2026-09-14-remove-lite-extra-actions.md`

### 后续事项

- 需要用户打开菜单与快捷键设置，确认两项入口已经消失且当前精简程度符合预期。
- 变更未推送远端，也未制作新的 DMG。
